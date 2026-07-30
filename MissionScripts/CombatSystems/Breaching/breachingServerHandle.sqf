/*
 * Author: WaldoTheWarfighter
 * Validates an explosion and applies matching breach profiles exactly once on the server.
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
private _breached = 0;
{
    private _targetClass = _x;
    private _profile = _profiles get _targetClass;
    private _radius = (_profile getOrDefault ["radius", 6]) max 0.5;
    private _allowedExplosives = _profile getOrDefault ["explosives", []];
    private _explosiveAllowed = count _allowedExplosives == 0 || {
        _allowedExplosives findIf {_explosiveClass isKindOf [_x, configFile >> "CfgAmmo"] || {_explosiveClass == _x}} >= 0
    };
    if (_explosiveAllowed) then {
        private _strengths = missionNamespace getVariable ["Waldo_Breaching_ExplosiveStrengths", createHashMap];
        private _strength = _strengths getOrDefault [_explosiveClass, _profile getOrDefault ["defaultExplosiveStrength", 1]];
        {
            private _target = _x;
            if !(_target getVariable ["Waldo_Breaching_Processed", false]) then {
                private _accumulated = (_target getVariable ["Waldo_Breaching_AccumulatedStrength", 0]) + _strength;
                _target setVariable ["Waldo_Breaching_AccumulatedStrength", _accumulated, true];
                if (_accumulated >= (_profile getOrDefault ["requiredStrength", 1])) then {
                    _target setVariable ["Waldo_Breaching_Processed", true, true];
                    private _spawned = [];
                    {
                        private _replacement = [_target, _x] call Waldo_fnc_BreachingSpawnRelative;
                        if (!isNull _replacement) then {_spawned pushBack _replacement};
                    } forEach (_profile getOrDefault ["replacements", []]);
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
} forEach keys _profiles;

if (_breached > 0 && {!isNull _unit} && {isPlayer _unit}) then {
    ["EXPLOSIVE BREACH", format ["%1 configured section(s) breached.", _breached], "SUCCESS", "EXPLOSIVE_BREACH"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _unit];
};

_breached
