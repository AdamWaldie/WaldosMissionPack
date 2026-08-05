/*
 * Author: WaldoTheWarfighter
 * Validates an explosion and applies matching breach profiles exactly once on the server.
 * Locality and authority: Server-only target mutation. The explosive owner's client may submit the
 * event, but network ownership, configured ammo, range, strength and repeat state are server-validated.
 *
 * Arguments:
 * 0: unit <OBJECT> - explosive owner when known
 * 1: position <ARRAY> - explosion world position
 * 2: explosiveClass <STRING>
 *
 * Return Value:
 * Number - breached object count
 *
 * Example:
 * [player, getPosWorld _charge, typeOf _charge] remoteExecCall ["Waldo_fnc_BreachingServerHandle", 2];
 * Result: Breaches each matching nearby configured target once and returns the number affected.
 * Current caller: Waldo_fnc_BreachingInit explosive event handling.
 */

params [
    ["_unit", objNull, [objNull]],
    ["_position", [], [[]]],
    ["_explosiveClass", "", [""]]
];
if !(isServer) exitWith {0};
if !(missionNamespace getVariable ["Waldo_Breaching_Enable", false]) exitWith {0};
if (count _position < 2 || {_explosiveClass == ""}) exitWith {0};
if (remoteExecutedOwner > 0 && {isNull _unit || {owner _unit != remoteExecutedOwner}}) exitWith {0};

private _profiles = missionNamespace getVariable ["Waldo_Breaching_Profiles", createHashMap];
if !(_profiles isEqualType createHashMap) exitWith {
    diag_log "[WMP BREACHING] Configuration rejected: Waldo_Breaching_Profiles must be a HashMap.";
    0
};
private _validProfileClasses = (keys _profiles) select {
    isClass (configFile >> "CfgVehicles" >> _x)
    && {(_profiles get _x) isEqualType createHashMap}
};
private _breached = 0;
{
    private _targetClass = _x;
    private _profile = _profiles get _targetClass;
    private _radius = _profile getOrDefault ["radius", 6];
    if !(_radius isEqualType 0) then {_radius = 6};
    _radius = _radius max 0.5;
    private _allowedExplosives = _profile getOrDefault ["explosives", []];
    if !(_allowedExplosives isEqualType []) then {_allowedExplosives = []};
    private _explosiveAllowed = count _allowedExplosives == 0 || {
        _allowedExplosives findIf {_explosiveClass isKindOf [_x, configFile >> "CfgAmmo"] || {_explosiveClass == _x}} >= 0
    };
    if (_explosiveAllowed) then {
        private _strengths = missionNamespace getVariable ["Waldo_Breaching_ExplosiveStrengths", createHashMap];
        if !(_strengths isEqualType createHashMap) then {_strengths = createHashMap};
        private _strengthKeys = keys _strengths;
        private _exactStrengthIndex = _strengthKeys findIf {_x == _explosiveClass};
        private _strength = _profile getOrDefault ["defaultExplosiveStrength", 1];
        if (_exactStrengthIndex >= 0) then {
            _strength = _strengths get (_strengthKeys select _exactStrengthIndex);
        } else {
            private _parentStrengthIndex = _strengthKeys findIf {
                _explosiveClass isKindOf [_x, configFile >> "CfgAmmo"]
            };
            if (_parentStrengthIndex >= 0) then {
                _strength = _strengths get (_strengthKeys select _parentStrengthIndex);
            };
        };
        if !(_strength isEqualType 0) then {_strength = 1};
        _strength = _strength max 0;
        {
            private _target = _x;
            if !(_target getVariable ["Waldo_Breaching_Processed", false]) then {
                private _accumulated = (_target getVariable ["Waldo_Breaching_AccumulatedStrength", 0]) + _strength;
                _target setVariable ["Waldo_Breaching_AccumulatedStrength", _accumulated, true];
                private _requiredStrength = _profile getOrDefault ["requiredStrength", 1];
                if !(_requiredStrength isEqualType 0) then {_requiredStrength = 1};
                if (_accumulated >= (_requiredStrength max 0.01)) then {
                    _target setVariable ["Waldo_Breaching_Processed", true, true];
                    private _spawned = [];
                    private _replacementProfiles = _profile getOrDefault ["replacements", []];
                    if !(_replacementProfiles isEqualType []) then {_replacementProfiles = []};
                    {
                        private _replacement = [_target, _x] call Waldo_fnc_BreachingSpawnRelative;
                        if (!isNull _replacement) then {_spawned pushBack _replacement};
                    } forEach _replacementProfiles;
                    _target setVariable ["Waldo_Breaching_Replacements", _spawned, true];

                    private _callback = _profile getOrDefault ["onBreach", {}];
                    if (_callback isEqualType {}) then {
                        [_target, _spawned, _position, _explosiveClass, _profile] call _callback;
                    };
                    if (_profile getOrDefault ["destroyOriginal", true]) then {_target setDamage 1};
                    if (_profile getOrDefault ["hideOriginal", false]) then {hideObjectGlobal _target};
                    if (_profile getOrDefault ["deleteOriginal", false]) then {deleteVehicle _target};
                    _breached = _breached + 1;
                };
            };
        } forEach nearestObjects [_position, [_targetClass], _radius, true];
    };
} forEach _validProfileClasses;

if (
    _breached > 0
    && {missionNamespace getVariable ["Waldo_Breaching_ShowNotifications", false]}
    && {!isNull _unit}
    && {isPlayer _unit}
) then {
    ["EXPLOSIVE BREACH", format ["%1 configured section(s) breached.", _breached], "SUCCESS", "EXPLOSIVE_BREACH"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _unit];
};

_breached
