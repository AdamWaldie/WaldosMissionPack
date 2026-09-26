/*
 * Author: WaldoTheWarfighter
 * Resolves and caches spawnable infantry, vehicle, static and aircraft pools for one faction.
 *
 * The resolver uses inheritance and engine configuration properties instead of hard-coded mod
 * classnames. Fixed-wing aircraft are split at 600 km/h and UAVs are removed from crewed air
 * buckets. For every side except civilian, infantry is restricted to classes whose config loadout
 * carries a primary weapon or launcher. Classification is by equipment, not role name: an armed
 * officer or pilot can still be selected. If a faction has no such class,
 * handgun-armed classes are used instead; a faction with no armed infantry at all returns an empty
 * infantry pool. Civilian pools are left unfiltered because civilians are expected to be unarmed.
 * Called by DynamicAOCreate and available to mission makers for validation or overrides.
 *
 * Locality/authority and repeat/JIP behaviour:
 * Runs on the calling machine and caches its config-derived pools by faction and requested side.
 * Creation resolves again on the server; this cache is not public state and requires no JIP replay.
 * Repeated calls return the cached HashMap. Callers must not prune its arrays based on spawned
 * inventories: mod loadout initialization can be deferred. No units are spawned by this function.
 * Config-only filtering does not support combat classes armed exclusively by later scripts.
 *
 * Arguments:
 * 0: faction classname <STRING> - default "" (no matching assets)
 * 1: side <SIDE> - default east; civilian disables the infantry armament filter
 *
 * Return Value:
 * HashMap with infantry, car, apc, tank, static, heli, jet, drone and plane arrays
 *
 * Current callers: DynamicAOCreate and mission-maker validation/override scripts.
 *
 * Example:
 * ["OPF_F", east] call Waldo_fnc_DynamicAOResolvePools;
 * Locality and authority: Reads faction and unit configuration on the caller. Repeated calls
 * resolve the same available mod classes; no state is published for JIP.
 * Result: Returns the usable class pools for this faction and side.
 */
params [["_faction", "", [""]], ["_side", east, [west]]];
private _sideKey = [east, west, independent, civilian] find _side;
private _cacheKey = format ["%1|%2", _sideKey, _faction];
private _cache = missionNamespace getVariable ["Waldo_DynamicAO_PoolCache", createHashMap];
if (_cacheKey in keys _cache) exitWith {_cache get _cacheKey};

// Weapon-type bitmask from CfgWeapons: 1 primary, 2 handgun, 4 launcher. Throw/Put/binoculars and
// items use other values and never count as an armament. Returns 2 (rifle/launcher), 1 (handgun
// only) or 0 (unarmed).
private _weaponTypeCache = createHashMap;
private _armament = {
    params ["_unitConfig"];
    private _flags = 0;
    {
        private _weapon = toLowerANSI _x;
        private _type = _weaponTypeCache getOrDefault [_weapon, -1];
        if (_type < 0) then {
            _type = getNumber (configFile >> "CfgWeapons" >> _x >> "type");
            if (_type >= 8) then {_type = 0};
            _weaponTypeCache set [_weapon, _type];
        };
        private _primaryOrLauncher = (_type mod 2) == 1 || {(floor (_type / 4)) mod 2 == 1};
        private _handgun = (floor (_type / 2)) mod 2 == 1;
        _flags = _flags max (if (_primaryOrLauncher) then {2} else {if (_handgun) then {1} else {0}});
    } forEach getArray (_unitConfig >> "weapons");
    _flags
};
private _filterInfantry = _side != civilian;
private _handgunInfantry = [];

private _pools = createHashMapFromArray [
    ["infantry", []], ["car", []], ["apc", []], ["tank", []], ["static", []],
    ["heli", []], ["jet", []], ["drone", []], ["plane", []]
];
{
    if (getNumber (_x >> "scope") >= 2 && {getText (_x >> "faction") == _faction}) then {
        private _class = configName _x;
        if (_class isKindOf "CAManBase") then {
            if (_filterInfantry) then {
                switch ([_x] call _armament) do {
                    case 2: {(_pools get "infantry") pushBack _class};
                    case 1: {_handgunInfantry pushBack _class};
                    default {};
                };
            } else {
                (_pools get "infantry") pushBack _class;
            };
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

if (_filterInfantry && {count (_pools get "infantry") == 0}) then {
    _pools set ["infantry", _handgunInfantry];
    if (count _handgunInfantry > 0) then {
        diag_log format ["[WMP DYNAMIC AO] Faction %1 has no rifle/launcher infantry; using %2 handgun-armed classes.", _faction, count _handgunInfantry];
    };
};

_cache set [_cacheKey, _pools];
missionNamespace setVariable ["Waldo_DynamicAO_PoolCache", _cache];
_pools
