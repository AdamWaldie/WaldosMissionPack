/*
 * Author: Waldo
 * Get player purchase side label.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoBuy_getPlayerPurchaseSideLabel;
 */

        params [["_sideKey", "NONE"]];

        switch (toUpper _sideKey) do {
            case "WEST": {"BLUFOR"};
            case "EAST": {"OPFOR"};
            case "GUER": {"INDEP"};
            default {"EVERYONE"};
        }

