/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getMarkerColorBySide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getMarkerColorBySide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_sideKey", "NONE"]];

        switch (toUpper _sideKey) do {
            case "WEST": {"ColorWEST"};
            case "EAST": {"ColorEAST"};
            case "GUER": {"ColorGUER"};
            case "CIV": {"ColorCIV"};
            default {"ColorWhite"};
        };

