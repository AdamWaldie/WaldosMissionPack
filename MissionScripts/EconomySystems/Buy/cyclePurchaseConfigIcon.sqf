/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - cyclePurchaseConfigIcon
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_cyclePurchaseConfigIcon via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull], ["_delta", 0]];
        [_disp, _delta, "WaldoEcoBuy_ConfigIconIndex", "WaldoEcoBuy_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;

