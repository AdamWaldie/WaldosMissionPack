/*
 * Author: Waldo
 * This function add eventhandelers adding pack functionality to some vehicles.
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_InitVehicles;
 *
 * Public: No
 */

 ["AllVehicles", "init", {
    _this params ["_vehicle"];
    if (_vehicle iskindOf "man") exitWith {};
    [_vehicle] call Waldo_fnc_AddVehicleFunctions;
}, true, [], true] call CBA_fnc_addClassEventHandler;

{
    _x addEventHandler ["CuratorObjectPlaced", {
        params ["", "_vehicle"];
        if (_vehicle iskindOf "man") exitWith {};
        [_vehicle] call Waldo_fnc_AddVehicleFunctions;
    }];
} forEach allCurators;