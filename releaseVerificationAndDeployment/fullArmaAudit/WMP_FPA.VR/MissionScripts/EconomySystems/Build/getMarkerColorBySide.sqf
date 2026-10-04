/*
 * Author: WaldoTheWarfighter
 * Maps an Economy side key to an Arma map-marker colour name.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <STRING> marker colour class; ColorWhite for unknown sides.
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoBuild_getMarkerColorBySide;
 * Locality/Authority: Any machine; pure side-to-colour lookup.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Building and detector marker drawing.
 * Result: Friendly-side markers use their faction colour.
 */

        params [["_sideKey", "NONE"]];

        switch (toUpper _sideKey) do {
            case "WEST": {"ColorWEST"};
            case "EAST": {"ColorEAST"};
            case "GUER": {"ColorGUER"};
            case "CIV": {"ColorCIV"};
            default {"ColorWhite"};
        };

