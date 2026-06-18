/*
 * Author: Waldo
 * Reset prompt input targets.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 * 1: _targetsVarName <STRING> - targets var name (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _targetsVarName] call Waldo_fnc_EcoCore_resetPromptInputTargets;
 */

    params [["_disp", displayNull], ["_targetsVarName", ""]];
    if (isNull _disp) exitWith {};
    if !(_targetsVarName isEqualTo "") then {
        _disp setVariable [_targetsVarName, []];
    };
    _disp setVariable ["WaldoEcoCore_InputTargets", []];
