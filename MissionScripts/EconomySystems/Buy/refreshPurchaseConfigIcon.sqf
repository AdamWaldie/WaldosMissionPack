/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - refreshPurchaseConfigIcon
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_refreshPurchaseConfigIcon via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull]];
        [_disp, "WaldoEcoBuy_ConfigIconIndex", "WaldoEcoBuy_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;

