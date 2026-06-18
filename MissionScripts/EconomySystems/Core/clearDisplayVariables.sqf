/*
 * Author: Waldo
 * Clear display variables.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 * 1: _varNames <ARRAY> - var names (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _varNames] call Waldo_fnc_EcoCore_clearDisplayVariables;
 */

    params [["_disp", displayNull], ["_varNames", []]];
    if (isNull _disp) exitWith {};

    {
        _disp setVariable [_x, nil];
    } forEach _varNames;
