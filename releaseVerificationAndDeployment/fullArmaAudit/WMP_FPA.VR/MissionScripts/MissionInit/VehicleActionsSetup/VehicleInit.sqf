/*
 * Author: WaldoTheWarfighter
 * Installs WMP's global vehicle-init handler and curator-object-placement handlers.
 * Locality and authority: Runs on machines that need vehicle-local feature setup. The CBA init
 * path and curator placement path pass each non-infantry vehicle to AddVehicleFunctions.
 * Repeat/JIP: This file does not guard its handler registrations. Run it once per machine during
 * initialization; joining clients install their own handlers.
 * Arguments: None.
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_InitVehicles;
 * Current caller: mission initialization when WMP vehicle actions are enabled.
 * Result: New and curator-placed vehicles receive their applicable WMP action setup.
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
