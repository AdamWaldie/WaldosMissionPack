/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - resetPromptInputTargets
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_resetPromptInputTargets via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull], ["_targetsVarName", ""]];
    if (isNull _disp) exitWith {};
    if !(_targetsVarName isEqualTo "") then {
        _disp setVariable [_targetsVarName, []];
    };
    _disp setVariable ["WaldoEcoCore_InputTargets", []];
