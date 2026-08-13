/*
 * Author: WaldoTheWarfighter, Val
 * Calculates protection for one unit against a configurable hazard profile.
 *
 * Vehicle, interior and equipment protection are combined into one exposure multiplier. This is a
 * pure locality-safe calculation currently called once per active zone by Waldo_fnc_HazardTick and
 * available to custom profile callbacks or mission scripts.
 * Locality and authority: Pure local calculation against the supplied unit/profile. It is normally
 * executed by the affected player's client and changes no network state.
 *
 * Arguments:
 * 0: unit <OBJECT>
 * 1: profile <HASHMAP>
 * 2: indoor cache key <STRING> (optional) - when supplied, the expensive `insideBuilding` check is
 *    throttled to once per Waldo_Hazard_IndoorCacheSeconds (default 3) per key instead of every call;
 *    omit for the previous always-live behaviour (direct/mission-script calls remain a pure read).
 *
 * Return Value:
 * Number - exposure multiplier from 0 (fully protected) to 1 (unprotected)
 *
 * Example:
 * private _factor = [player, _profile] call Waldo_fnc_HazardProtectionFactor;
 * Result: Returns 0 for full protection, 1 for no protection, or a partial exposure multiplier.
 * Current caller: Waldo_fnc_HazardTick once for each active zone affecting the local player (with a
 * cache key so a stationary occupancy state is not re-tested through `insideBuilding` every tick).
 */

params ["_unit", "_profile", ["_cacheKey", "", [""]]];
if (isNull _unit) exitWith {1};

private _factor = 1;
if (_profile getOrDefault ["protectInVehicles", false] && {vehicle _unit != _unit}) then {
    _factor = _factor min (_profile getOrDefault ["vehicleFactor", 0]);
};
if (_profile getOrDefault ["protectIndoors", false]) then {
    private _indoors = if (_cacheKey == "") then {
        insideBuilding _unit > 0
    } else {
        // insideBuilding is a documented-expensive engine query; a hazard zone's protectIndoors gate
        // otherwise called it on every hazard tick for the entire time a player stood inside the zone.
        // A unit's building occupancy does not change fast enough to need per-tick resolution.
        private _cache = missionNamespace getVariable ["Waldo_Hazard_LocalIndoorCache", createHashMap];
        private _entry = _cache getOrDefault [_cacheKey, [-1e6, false]];
        _entry params ["_checkedAt", "_wasIndoors"];
        private _throttle = missionNamespace getVariable ["Waldo_Hazard_IndoorCacheSeconds", 3];
        if ((diag_tickTime - _checkedAt) >= _throttle) then {
            _wasIndoors = insideBuilding _unit > 0;
            _cache set [_cacheKey, [diag_tickTime, _wasIndoors]];
            missionNamespace setVariable ["Waldo_Hazard_LocalIndoorCache", _cache];
        };
        _wasIndoors
    };
    if (_indoors) then {_factor = _factor min (_profile getOrDefault ["indoorFactor", 0]);};
};

private _slots = _profile getOrDefault ["protectiveItems", createHashMap];
private _checks = [];
private _wornItems = [headgear _unit, goggles _unit, hmd _unit, uniform _unit, vest _unit, backpack _unit];
{
    private _allowed = _slots getOrDefault [_x select 0, []];
    if (count _allowed > 0) then {
        _checks pushBack ((_x select 1) in _allowed);
    };
} forEach [
    ["headgear", headgear _unit],
    ["goggles", goggles _unit],
    ["hmd", hmd _unit],
    ["uniform", uniform _unit],
    ["vest", vest _unit],
    ["backpack", backpack _unit]
];

private _anySlot = _profile getOrDefault ["protectiveItemsAnySlot", []];
if (count _anySlot > 0) then {
    _checks pushBack (_wornItems findIf {_x in _anySlot} >= 0);
};

if (count _checks > 0) then {
    private _mode = toUpperANSI (_profile getOrDefault ["protectionMode", "ANY"]);
    private _protected = if (_mode == "ALL") then {
        _checks findIf {!_x} < 0
    } else {
        _checks findIf {_x} >= 0
    };
    if (_protected) then {
        _factor = _factor min (_profile getOrDefault ["equipmentFactor", 0.05]);
    };
};

(_factor max 0) min 1
