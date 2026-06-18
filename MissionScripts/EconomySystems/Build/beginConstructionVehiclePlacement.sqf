/*
 * Author: Waldo
 * Begin construction vehicle placement.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _display <ANY> - display
 * 1: _pos <ANY> - pos
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_display, _pos] call Waldo_fnc_EcoBuild_beginConstructionVehiclePlacement;
 */

        if (!hasInterface) exitWith {};

        private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
        if (isNull _disp) exitWith {};

        [_disp] call Waldo_fnc_EcoBuild_cleanupBuildConfigPrompt;

        if (!isNil "Waldo_fnc_EcoResource_stopResourceCratePlacement") then {
            [_disp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;
        };

        [_disp] call Waldo_fnc_EcoBuild_stopConstructionPlacement;

        [
            _disp,
            "WaldoEcoBuild_PlacementPending",
            "WaldoEcoBuild_PlacementEH",
            "WaldoEcoBuild_PlacementKeyEH",
            {
                call Waldo_fnc_EcoBuild_getPlacementPos
            },
            {
                params ["_display", "_pos"];
                [_pos, "B_Truck_01_box_F"] call Waldo_fnc_EcoBuild_spawnConstructionVehicle;
            }
        ] call Waldo_fnc_EcoCore_beginZeusPlacementSession;

