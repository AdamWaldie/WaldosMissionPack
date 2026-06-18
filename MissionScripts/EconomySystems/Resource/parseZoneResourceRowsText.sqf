/*
 * Author: Waldo
 * Parse zone resource rows text.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _text <STRING> - text (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_text] call Waldo_fnc_EcoResource_parseZoneResourceRowsText;
 */

    params [["_text", ""]];

    private _rows = [];
    {
        private _line = [_x] call Waldo_fnc_EcoResource_normalizeResourceName;
        if (_line isEqualTo "") then {continue;};

        private _chars = toArray _line;
        private _sepIndex = _chars findIf {_x in [58, 61]};
        if (_sepIndex < 0) then {continue;};

        private _name = [(_line select [0, _sepIndex])] call Waldo_fnc_EcoResource_normalizeResourceName;
        private _valueText = [(_line select [_sepIndex + 1])] call Waldo_fnc_EcoResource_normalizeResourceName;
        private _parts = _valueText splitString "/";
        private _amount = floor (parseNumber (_parts param [0, "0"]));
        private _deposit = if ((count _parts) > 1) then {
            floor (parseNumber (_parts param [1, "0"]))
        } else {
            -1
        };

        if (_name isEqualTo "") then {continue;};
        if (_amount <= 0) then {continue;};

        if (_deposit > 0) then {
            _rows pushBack [_name, _amount, _deposit, _deposit];
        } else {
            _rows pushBack [_name, _amount, -1, -1];
        };
    } forEach (_text splitString toString [10]);

    [_rows] call Waldo_fnc_EcoResource_normalizeZoneResourceRows
