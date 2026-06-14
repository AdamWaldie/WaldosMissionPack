/*
 * Author: Waldo
 * Zeus Enhanced module that turns the nearest AI land-vehicle group into a
 * managed convoy using the pack's own Waldo_fnc_SimpleAiConvoy behaviour
 * (column formation, speed limiting, separation keeping, optional push-through).
 * The Zeus places the module on or near the lead vehicle of the convoy.
 *
 * Arguments:
 * 0: modulePos <POSITION> - where the Zeus dropped the module
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_modulePos] call Waldo_fnc_ZenConvoyModule;
 *
 * Public: No
 */

params ["_modulePos"];

// Find the nearest crewed AI land vehicle to the module placement.
private _vehicles = nearestObjects [_modulePos, ["LandVehicle"], 150];
private _target = objNull;
{
    if (count (crew _x) > 0 && {!(_x isKindOf "Man")}) exitWith { _target = _x; };
} forEach _vehicles;

if (isNull _target) exitWith {
    systemChat "[WMP] Spawn AI Convoy: no crewed land vehicle found within 150m of the module.";
};

private _group = group (effectiveCommander _target);
if (isNull _group) then { _group = group (driver _target); };
if (isNull _group) exitWith {
    systemChat "[WMP] Spawn AI Convoy: could not resolve a group for the selected convoy vehicle.";
};

[
    "Spawn AI Convoy",
    [
        ["SLIDER", ["Max Speed (km/h)", "Top speed of the convoy lead vehicle."], [5, 120, 30, 0], false],
        ["SLIDER", ["Separation (m)", "Target distance between vehicles."], [5, 100, 15, 0], false],
        ["CHECKBOX", ["Push Through Contact", "If checked, the convoy keeps moving and only returns fire on the move."], true]
    ],
    {
        params ["_args", "_group"];
        _args params ["_speed", "_separation", "_pushThrough"];
        _speed = round _speed;
        _separation = round _separation;
        [_group, _speed, _separation, _pushThrough] spawn Waldo_fnc_SimpleAiConvoy;
    },
    {},
    _group
] call zen_dialog_fnc_create;
