/*
 * Author: WaldoTheWarfighter
 * Converts a delivery-point side key to its player-facing label.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "ANY")
 *
 * Return Value:
 * <STRING> BLUFOR, OPFOR, INDEP or EVERYONE.
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoBuy_getDropPointSideLabel;
 * Locality/Authority: Any machine; pure label mapping.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Delivery-point authoring and status display.
 * Result: Unknown/ANY sides display as EVERYONE.
 */

        params [["_sideKey", "ANY"]];

        switch ([_sideKey] call Waldo_fnc_EcoBuy_normalizeDropPointSide) do {
            case "WEST": {"BLUFOR"};
            case "EAST": {"OPFOR"};
            case "GUER": {"INDEP"};
            default {"EVERYONE"};
        }

