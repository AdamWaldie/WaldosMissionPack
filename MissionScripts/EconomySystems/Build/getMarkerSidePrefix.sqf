/*
 * Author: Waldo
 * Get marker side prefix.
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
 * [_sideKey] call Waldo_fnc_EcoBuild_getMarkerSidePrefix;
 */

        params [["_sideKey", "NONE"]];

        switch (toUpper _sideKey) do {
            case "WEST": {"b"};
            case "EAST": {"o"};
            case "GUER": {"n"};
            default {"c"};
        };

