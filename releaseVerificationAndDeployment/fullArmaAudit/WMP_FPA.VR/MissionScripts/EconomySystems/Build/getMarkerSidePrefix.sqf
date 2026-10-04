/*
 * Author: WaldoTheWarfighter
 * Maps an Economy side key to the standard tactical-marker prefix.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <STRING> marker prefix; "c" for unknown sides.
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoBuild_getMarkerSidePrefix;
 * Locality/Authority: Any machine; pure side-to-prefix lookup.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Detector contact marker type selection.
 * Result: Marker names use the selected side's tactical prefix.
 */

        params [["_sideKey", "NONE"]];

        switch (toUpper _sideKey) do {
            case "WEST": {"b"};
            case "EAST": {"o"};
            case "GUER": {"n"};
            default {"c"};
        };

