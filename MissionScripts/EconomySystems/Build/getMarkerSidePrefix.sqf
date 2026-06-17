/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getMarkerSidePrefix
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getMarkerSidePrefix via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_sideKey", "NONE"]];

        switch (toUpper _sideKey) do {
            case "WEST": {"b"};
            case "EAST": {"o"};
            case "GUER": {"n"};
            default {"c"};
        };

