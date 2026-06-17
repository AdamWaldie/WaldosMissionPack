/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - stopConstructionPlacement
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_stopConstructionPlacement via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [
            _disp,
            "WaldoEcoBuild_PlacementPending",
            "WaldoEcoBuild_PlacementEH",
            "WaldoEcoBuild_PlacementKeyEH"
        ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;

