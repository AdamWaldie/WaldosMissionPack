/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - getDropPointSideLabel
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_getDropPointSideLabel via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_sideKey", "ANY"]];

        switch ([_sideKey] call Waldo_fnc_EcoBuy_normalizeDropPointSide) do {
            case "WEST": {"BLUFOR"};
            case "EAST": {"OPFOR"};
            case "GUER": {"INDEP"};
            default {"EVERYONE"};
        }

