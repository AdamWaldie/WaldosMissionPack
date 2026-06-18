/*
 * Author: Waldo
 * Normalize drop point type.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _value <STRING> - value (optional, default: "Ground")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_value] call Waldo_fnc_EcoBuy_normalizeDropPointType;
 */

        params [["_value", "Ground"]];

        private _trimmed = [_value] call Waldo_fnc_EcoCore_trimString;
        private _choices = call Waldo_fnc_EcoBuy_getDropPointTypeChoices;
        private _index = _choices findIf {(toLower _x) isEqualTo (toLower _trimmed)};
        if (_index < 0) exitWith {"Ground"};
        _choices select _index

