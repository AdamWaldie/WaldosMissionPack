/*
 * Author: Waldo
 * Apply resource rows to side.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _rows <ARRAY> - rows (optional, default: [])
 * 2: _callerName <STRING> - caller name (optional, default: "Zeus")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _rows, _callerName] call Waldo_fnc_EcoResource_applyResourceRowsToSide;
 */

    params ["_sideKey", ["_rows", []], ["_callerName", "Zeus"]];

    private _normalizedRows = [_rows] call Waldo_fnc_EcoResource_normalizeResourceRows;
    private _applied = [];
    private _leftover = [];

    {
        private _resourceType = _x param [0, ""];
        private _requested = _x param [1, 0];
        private _appliedAmount = [_sideKey, _resourceType, _requested] call Waldo_fnc_EcoResource_getAllowedResourceGain;

        if (_appliedAmount > 0) then {
            [_sideKey, _resourceType, _appliedAmount, _callerName] call Waldo_fnc_EcoResource_addSideResourceAmount;
            _applied pushBack [_resourceType, _appliedAmount];
        };

        private _remaining = _requested - _appliedAmount;
        if (_remaining > 0) then {
            _leftover pushBack [_resourceType, _remaining];
        };
    } forEach _normalizedRows;

    [_applied, _leftover]
