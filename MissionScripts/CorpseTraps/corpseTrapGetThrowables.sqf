/*
 * Returns the distinct throwable magazines carried by a unit, including modded
 * magazines exposed through Throw muzzle magazine wells.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Rows in the form [magazine, ammo, display name, picture, count] <ARRAY>
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
