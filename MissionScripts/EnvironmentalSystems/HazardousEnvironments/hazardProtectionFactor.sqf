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
 *
 * Return Value:
 * Number - exposure multiplier from 0 (fully protected) to 1 (unprotected)
 *
 * Example:
 * private _factor = [player, _profile] call Waldo_fnc_HazardProtectionFactor;
 * Result: Returns 0 for full protection, 1 for no protection, or a partial exposure multiplier.
 * Current caller: Waldo_fnc_HazardTick once for each active zone affecting the local player.
 */

params ["_unit", "_profile"];
if (isNull _unit) exitWith {1};

private _factor = 1;
if (_profile getOrDefault ["protectInVehicles", false] && {vehicle _unit != _unit}) then {
    _factor = _factor min (_profile getOrDefault ["vehicleFactor", 0]);
};
if (_profile getOrDefault ["protectIndoors", false] && {insideBuilding _unit > 0}) then {
    _factor = _factor min (_profile getOrDefault ["indoorFactor", 0]);
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
