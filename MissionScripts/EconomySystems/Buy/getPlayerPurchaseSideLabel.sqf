/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - getPlayerPurchaseSideLabel
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_getPlayerPurchaseSideLabel via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_sideKey", "NONE"]];

        switch (toUpper _sideKey) do {
            case "WEST": {"BLUFOR"};
            case "EAST": {"OPFOR"};
            case "GUER": {"INDEP"};
            default {"EVERYONE"};
        }

