/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getPresetPurchaseSideName
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getPresetPurchaseSideName via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_sideKey", ""]];

    switch (toUpper _sideKey) do {
        case "WEST": {"BLUFOR"};
        case "EAST": {"OPFOR"};
        case "GUER": {"INDEP"};
        default {"EVERYONE"};
    }
