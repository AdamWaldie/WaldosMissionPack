/*
 * Author: WaldoTheWarfighter
 * Lists a unit's compatible throwable magazines, including live modded Throw muzzle wells.
 * Locality and authority: Called on the interface client while building the ACE corpse action;
 * it reads that player's inventory and local game configuration.
 * Repeat/JIP: The compatible-class list is cached per machine; inventory counts are read afresh
 * on every call. No action or public state is installed here.
 * Arguments:
 * 0: unit to inspect <OBJECT> (default objNull)
 * Return Value: <ARRAY> - rows [magazine class, ammo class, display name, picture, count].
 * Current callers: Waldo_fnc_CorpseTrapInit ACE action builder and condition.
 * Example: private _throwables = [player] call Waldo_fnc_CorpseTrapGetThrowables;
 * Result: Each carried compatible throwable appears once with its current quantity.
 */
params [
    ["_unit", objNull, [objNull]]
];

if (isNull _unit) exitWith {[]};

private _compatible = missionNamespace getVariable ["Waldo_CorpseTrap_CompatibleMagazines", []];
if !(missionNamespace getVariable ["Waldo_CorpseTrap_CompatibleCacheReady", false]) then {
    private _throwConfig = configFile >> "CfgWeapons" >> "Throw";
    _compatible = compatibleMagazines "Throw";
    {
        _compatible append (compatibleMagazines ["Throw", _x]);
        _compatible append getArray (_throwConfig >> _x >> "magazines");
    } forEach getArray (_throwConfig >> "muzzles");
    _compatible = (_compatible arrayIntersect _compatible) apply {toLowerANSI _x};
    missionNamespace setVariable ["Waldo_CorpseTrap_CompatibleMagazines", _compatible];
    missionNamespace setVariable ["Waldo_CorpseTrap_CompatibleCacheReady", true];
};

private _counts = createHashMap;
{
    if (toLowerANSI _x in _compatible) then {
        _counts set [_x, (_counts getOrDefault [_x, 0]) + 1];
    };
} forEach magazines _unit;

private _rows = [];
{
    private _magazineConfig = configFile >> "CfgMagazines" >> _x;
    private _ammo = getText (_magazineConfig >> "ammo");
    if (_ammo != "" && {isClass (configFile >> "CfgAmmo" >> _ammo)}) then {
        private _displayName = getText (_magazineConfig >> "displayName");
        if (_displayName == "") then {
            _displayName = _x;
        };
        _rows pushBack [
            _x,
            _ammo,
            _displayName,
            getText (_magazineConfig >> "picture"),
            _counts get _x
        ];
    };
} forEach keys _counts;

_rows
