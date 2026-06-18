/*
 * Author: Waldo
 * Get drop point side label.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "ANY")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoBuy_getDropPointSideLabel;
 */

        params [["_sideKey", "ANY"]];

        switch ([_sideKey] call Waldo_fnc_EcoBuy_normalizeDropPointSide) do {
            case "WEST": {"BLUFOR"};
            case "EAST": {"OPFOR"};
            case "GUER": {"INDEP"};
            default {"EVERYONE"};
        }

