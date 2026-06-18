/*
 * Author: Waldo
 * Normalize zone resource rows.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoResource_normalizeZoneResourceRows;
 */

    params [["_rows", []]];

    private _types = call Waldo_fnc_EcoResource_getResourceTypes;
    private _result = [];

    {
        private _name = [(_x param [0, ""])] call Waldo_fnc_EcoResource_normalizeResourceName;
        private _amount = floor (_x param [1, 0]);
        if (_name isEqualTo "") then {continue;};
        if (_amount <= 0) then {continue;};
        if ((_types find _name) < 0) then {continue;};

        private _remaining = floor (_x param [2, -1]);
        private _total = floor (_x param [3, -1]);
        if (_total <= 0) then {
            _remaining = -1;
            _total = -1;
        } else {
            if (_remaining < 0) then {
                _remaining = _total;
            };
            _remaining = _remaining min _total;
        };

        private _existing = _result findIf {((_x param [0, ""]) isEqualTo _name)};
        if (_existing < 0) then {
            _result pushBack [_name, _amount, _remaining, _total];
        } else {
            private _existingRow = _result select _existing;
            private _existingAmount = _existingRow param [1, 0];
            private _existingRemaining = _existingRow param [2, -1];
            private _existingTotal = _existingRow param [3, -1];

            private _mergedRemaining = -1;
            private _mergedTotal = -1;
            if (_existingTotal > 0 || {_total > 0}) then {
                _mergedRemaining = (0 max _existingRemaining) + (0 max _remaining);
                _mergedTotal = (0 max _existingTotal) + (0 max _total);
            };

            _result set [_existing, [_name, _existingAmount + _amount, _mergedRemaining, _mergedTotal]];
        };
    } forEach _rows;

    _result
