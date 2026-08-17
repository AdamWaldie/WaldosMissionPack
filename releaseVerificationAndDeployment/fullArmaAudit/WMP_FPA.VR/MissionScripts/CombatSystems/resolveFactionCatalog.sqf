/*
 * Author: WaldoTheWarfighter
 * Returns runtime faction choices that contain at least one usable public vehicle or soldier -
 * the shared mod-aware faction discovery primitive behind Dynamic AO, Dynamic AA and any other
 * feature that lets a curator pick "a faction" instead of typing raw classnames. It scans whatever
 * factions genuinely exist in the running modset (vanilla or third-party) rather than relying on a
 * mission-maker-authored allowlist, so a faction is offered the moment its mod is loaded.
 *
 * Results are cached per machine because configuration data is immutable during a mission. Each
 * row keeps side, classname and a curator-friendly label together, preventing invalid side/faction
 * combinations.
 *
 * Arguments:
 * 0: allowed sides <ARRAY<SIDE>> (default [west,east,independent])
 *
 * Return Value:
 * Array of [side <SIDE>, faction classname <STRING>, label <STRING>]
 *
 * Current callers: Waldo_fnc_DynamicAOGetFactions (thin back-compat alias) and Waldo_fnc_DynamicAAZen.
 *
 * Example:
 * [[east, independent]] call Waldo_fnc_ResolveFactionCatalog;
 */
params [["_allowedSides", [west, east, independent], [[]]]];

private _cache = missionNamespace getVariable ["Waldo_FactionCatalog_Cache", []];
if (_cache isEqualTo []) then {
    private _used = createHashMap;
    {
        if (getNumber (_x >> "scope") >= 2) then {
            private _faction = getText (_x >> "faction");
            private _sideNumber = getNumber (_x >> "side");
            if (_faction != "" && {_sideNumber in [0, 1, 2, 3]}) then {
                _used set [format ["%1|%2", _sideNumber, _faction], true];
            };
        };
    } forEach ("true" configClasses (configFile >> "CfgVehicles"));

    {
        private _sideNumber = getNumber (_x >> "side");
        private _faction = configName _x;
        if (_sideNumber in [0, 1, 2, 3] && {_used getOrDefault [format ["%1|%2", _sideNumber, _faction], false]}) then {
            private _side = [east, west, independent, civilian] select _sideNumber;
            private _sideLabel = ["OPFOR", "BLUFOR", "Independent", "Civilian"] select _sideNumber;
            private _name = getText (_x >> "displayName");
            if (_name == "") then {_name = _faction};
            _cache pushBack [_side, _faction, format ["[%1] %2", _sideLabel, _name]];
        };
    } forEach ("true" configClasses (configFile >> "CfgFactionClasses"));
    _cache = [_cache, [], {_x select 2}, "ASCEND"] call BIS_fnc_sortBy;
    missionNamespace setVariable ["Waldo_FactionCatalog_Cache", _cache];
};

_cache select {(_x select 0) in _allowedSides}
