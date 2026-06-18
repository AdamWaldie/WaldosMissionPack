/*
 * Author: Waldo
 * Close prompt display if dedicated.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};
    if !(_disp getVariable ["WaldoEcoCore_IsDedicatedZeusPromptDisplay", false]) exitWith {};

    private _active = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    if (!isNull _active && {_active isEqualTo _disp}) then {
        uiNamespace setVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    };

    _disp closeDisplay 1;
