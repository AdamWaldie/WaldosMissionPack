/*
 * Author: Waldo
 * Get all side resource rows.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoResource_getAllSideResourceRows;
 */

    private _result = [];

    {
        private _varName = [_x] call Waldo_fnc_EcoResource_getSideStorageVar;
        private _rows = +(missionNamespace getVariable [_varName, []]);
        _result pushBack [_x, _rows];
    } forEach ["WEST", "EAST", "GUER", "CIV"];

    _result
