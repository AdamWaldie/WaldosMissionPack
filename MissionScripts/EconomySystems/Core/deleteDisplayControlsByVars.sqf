/*
 * Author: Waldo
 * Delete display controls by vars.
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
 * [_disp, _varNames] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;
 */

    params [["_disp", displayNull], ["_varNames", []]];
    if (isNull _disp) exitWith {};

    {
        private _ctrl = _disp getVariable [_x, controlNull];
        if (!isNull _ctrl) then {
            ctrlDelete _ctrl;
        };
        _disp setVariable [_x, controlNull];
    } forEach _varNames;
