/*
 * Author: WaldoTheWarfighter
 * Resolves and caches spawnable infantry, vehicle, static and aircraft pools for one faction.
 *
 * The resolver uses inheritance and engine configuration properties instead of hard-coded mod
 * classnames. Fixed-wing aircraft are split at 600 km/h and UAVs are removed from crewed air
 * buckets. Called by DynamicAOCreate and available to mission makers for validation or overrides.
 *
 * Arguments:
 * 0: faction classname <STRING>
 * 1: side <SIDE>
 *
 * Return Value:
 * HashMap with infantry, car, apc, tank, static, heli, jet, drone and plane arrays
 *
 * Current callers: DynamicAOCreate and mission-maker validation/override scripts.
 *
 * Example:
 * ["OPF_F", east] call Waldo_fnc_DynamicAOResolvePools;
 */
params [["_faction", "", [""]], ["_side", east, [west]]];
private _sideKey = [east, west, independent, civilian] find _side;
private _cacheKey = format ["%1|%2", _sideKey, _faction];
private _cache = missionNamespace getVariable ["Waldo_DynamicAO_PoolCache", createHashMap];
if (_cacheKey in keys _cache) exitWith {_cache get _cacheKey};

private _pools = createHashMapFromArray [
    ["infantry", []], ["car", []], ["apc", []], ["tank", []], ["static", []],
    ["heli", []], ["jet", []], ["drone", []], ["plane", []]
];
{
    if (getNumber (_x >> "scope") >= 2 && {getText (_x >> "faction") == _faction}) then {
        private _class = configName _x;
        if (_class isKindOf "CAManBase") then {
            (_pools get "infantry") pushBack _class;
        } else {
            if (_class isKindOf "StaticWeapon") then {
                (_pools get "static") pushBack _class;
            } else {
                if (_class isKindOf "Car") then {(_pools get "car") pushBack _class};
                if (_class isKindOf "Tank") then {
                    private _bucket = if (getNumber (_x >> "transportSoldier") > 2) then {"apc"} else {"tank"};
                    (_pools get _bucket) pushBack _class;
                };
                if (_class isKindOf "Helicopter" || {_class isKindOf "Plane"}) then {
                    if (getNumber (_x >> "isUav") > 0) then {
                        (_pools get "drone") pushBack _class;
                    } else {
                        if (_class isKindOf "Helicopter") then {
                            (_pools get "heli") pushBack _class;
                        } else {
                            private _bucket = if (getNumber (_x >> "maxSpeed") >= 600) then {"jet"} else {"plane"};
                            (_pools get _bucket) pushBack _class;
                        };
                    };
                };
            };
        };
    };
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

_cache set [_cacheKey, _pools];
missionNamespace setVariable ["Waldo_DynamicAO_PoolCache", _cache];
_pools
