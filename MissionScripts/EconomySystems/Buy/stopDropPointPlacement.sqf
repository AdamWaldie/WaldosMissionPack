/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - stopDropPointPlacement
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_stopDropPointPlacement via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [
            _disp,
            "WaldoEcoBuy_PlacementPending",
            "WaldoEcoBuy_PlacementEH",
            "WaldoEcoBuy_PlacementKeyEH"
        ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;

