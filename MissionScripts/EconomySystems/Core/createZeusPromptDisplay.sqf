/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - createZeusPromptDisplay
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_createZeusPromptDisplay via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
