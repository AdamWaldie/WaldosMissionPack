/*
 * Author: Waldo
 * Normalize side resource rows.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _rows <ANY> - rows
 * 1: _types <ANY> - types
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_rows, _types] call Waldo_fnc_EcoResource_normalizeSideResourceRows;
 */

    params ["_rows", "_types"];

    private _normalized = [];

    {
        private _typeName = _x;
        private _existingIndex = _rows findIf {
            ((_x param [0, ""]) isEqualTo _typeName)
        };

        private _value = 0;
        if (_existingIndex >= 0) then {
            _value = (_rows select _existingIndex) param [1, 0];
        };

        _normalized pushBack [_typeName, 0 max (floor _value)];
    } forEach _types;

    _normalized
