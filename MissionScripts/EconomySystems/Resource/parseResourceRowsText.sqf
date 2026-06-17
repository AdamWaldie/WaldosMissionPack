/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - parseResourceRowsText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_parseResourceRowsText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
        private _value = floor (parseNumber _valueText);
        if (_name isEqualTo "") then {continue;};
        if (_value <= 0) then {continue;};

        _rows pushBack [_name, _value];
    } forEach (_text splitString toString [10]);

    [_rows] call Waldo_fnc_EcoResource_normalizeResourceRows
