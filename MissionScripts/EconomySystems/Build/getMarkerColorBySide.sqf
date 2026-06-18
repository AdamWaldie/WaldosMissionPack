/*
 * Author: Waldo
 * Get marker color by side.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoBuild_getMarkerColorBySide;
 */

        params [["_sideKey", "NONE"]];

        switch (toUpper _sideKey) do {
            case "WEST": {"ColorWEST"};
            case "EAST": {"ColorEAST"};
            case "GUER": {"ColorGUER"};
            case "CIV": {"ColorCIV"};
            default {"ColorWhite"};
        };

