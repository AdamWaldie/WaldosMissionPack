/*
 * Author: Waldo
 * Normalize drop point side.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _value <STRING> - value (optional, default: "ANY")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_value] call Waldo_fnc_EcoBuy_normalizeDropPointSide;
 */

        params [["_value", "ANY"]];

        private _trimmed = toUpper ([_value] call Waldo_fnc_EcoCore_trimString);
        if (_trimmed in ["EVERYONE", "ANY", "ALL"]) exitWith {"ANY"};
        if (_trimmed in ["BLUFOR", "WEST"]) exitWith {"WEST"};
        if (_trimmed in ["OPFOR", "EAST"]) exitWith {"EAST"};
        if (_trimmed in ["INDEP", "INDFOR", "GUER", "INDEPENDENT"]) exitWith {"GUER"};
        "ANY"

