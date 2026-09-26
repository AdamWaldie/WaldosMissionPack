/*
 * Author: WaldoTheWarfighter
 * Converts a delivery-point faction label to its stored side key.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _value <STRING> - value (optional, default: "ANY")
 *
 * Return Value:
 * <STRING> ANY, WEST, EAST or GUER; unknown labels become ANY.
 *
 * Example:
 * [_value] call Waldo_fnc_EcoBuy_normalizeDropPointSide;
 * Locality/Authority: Any machine; pure label normalization.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Delivery-point creation, filtering and curator controls.
 * Result: Common faction aliases map to a single stored key.
 */

        params [["_value", "ANY"]];

        private _trimmed = toUpper ([_value] call Waldo_fnc_EcoCore_trimString);
        if (_trimmed in ["EVERYONE", "ANY", "ALL"]) exitWith {"ANY"};
        if (_trimmed in ["BLUFOR", "WEST"]) exitWith {"WEST"};
        if (_trimmed in ["OPFOR", "EAST"]) exitWith {"EAST"};
        if (_trimmed in ["INDEP", "INDFOR", "GUER", "INDEPENDENT"]) exitWith {"GUER"};
        "ANY"

