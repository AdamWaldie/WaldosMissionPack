/*
 * Author: Waldo
 * Create zeus prompt display.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_createZeusPromptDisplay;
 */

    if (!hasInterface) exitWith {displayNull};

    private _existing = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    if (!isNull _existing) then {
        [_existing] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;
    };

    createDialog "RscDisplayEmpty";
    private _disp = findDisplay -1;
    if (isNull _disp) exitWith {displayNull};

    _disp setVariable ["WaldoEcoCore_IsDedicatedZeusPromptDisplay", true];
    uiNamespace setVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", _disp];
    _disp
