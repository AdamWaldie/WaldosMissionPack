/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - beginConstructionVehiclePlacement
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_beginConstructionVehiclePlacement via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

