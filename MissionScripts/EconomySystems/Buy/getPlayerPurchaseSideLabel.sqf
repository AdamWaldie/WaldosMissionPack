/*
 * Author: WaldoTheWarfighter
 * Converts a purchase side key into a label for the player UI.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <STRING> BLUFOR, OPFOR, INDEP or EVERYONE.
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoBuy_getPlayerPurchaseSideLabel;
 * Locality/Authority: Any machine; pure label mapping.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Purchase terminal action and status display.
 * Result: Unknown/neutral sides display as EVERYONE.
 */

        params [["_sideKey", "NONE"]];

        switch (toUpper _sideKey) do {
            case "WEST": {"BLUFOR"};
            case "EAST": {"OPFOR"};
            case "GUER": {"INDEP"};
            default {"EVERYONE"};
        }

