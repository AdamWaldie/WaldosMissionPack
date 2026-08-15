/*
 * Author: WaldoTheWarfighter
 * Scans CfgVehicles once per distinct cache key for classes matching a caller-supplied test,
 * returning them as validated, label-sorted [classname, label] pairs. This is the shared mod-aware
 * discovery primitive behind dynamic aircraft/vehicle selection: it lets a feature offer every
 * usable class actually present in the running modset instead of only a hardcoded vanilla list or
 * a mission-maker-authored allowlist that silently returns nothing when left unset.
 *
 * Results are cached per cache key because configuration data is immutable during a mission - pass
 * a distinct key per caller/test combination (e.g. one key per side) so unrelated scans never share
 * a cache entry.
 *
 * Arguments:
 * 0: cache key <STRING> - unique per distinct test, e.g. "PARADROP_AIRCRAFT" or "GUNSHIP_AIR_WEST"
 * 1: test code <CODE> - executed once per CfgVehicles class with _this = classname <STRING>;
 *    return true to include it. Scope is not implied - test getNumber (config >> "scope") >= 2
 *    explicitly when public-only classes are required.
 *
 * Return Value:
 * Array of [classname <STRING>, label <STRING>], sorted alphabetically by label.
 *
 * Current callers: Waldo_fnc_ParadropDropZoneZen (airframe discovery), Waldo_fnc_GunshipRegister
 * (default armed-aircraft fallback).
 *
 * Example:
 * ["PARADROP_AIRCRAFT", {
 *     _this isKindOf "Air"
 *     && {getNumber (configFile >> "CfgVehicles" >> _this >> "scope") >= 2}
 *     && {getNumber (configFile >> "CfgVehicles" >> _this >> "transportSoldier") > 0}
 * }] call Waldo_fnc_ResolveVehicleClassPool;
 */
params [["_cacheKey", "", [""]], ["_test", {false}, [{}]]];
if (_cacheKey == "") exitWith {[]};

private _varName = format ["Waldo_VehicleClassPool_%1", _cacheKey];
private _cache = missionNamespace getVariable [_varName, []];
if (_cache isEqualTo []) then {
    {
        private _class = configName _x;
        if (_class call _test) then {
            private _name = getText (_x >> "displayName");
            if (_name == "") then {_name = _class};
            _cache pushBack [_class, _name];
        };
    } forEach ("true" configClasses (configFile >> "CfgVehicles"));
    _cache = [_cache, [], {_x select 1}, "ASCEND"] call BIS_fnc_sortBy;
    missionNamespace setVariable [_varName, _cache];
};

_cache
