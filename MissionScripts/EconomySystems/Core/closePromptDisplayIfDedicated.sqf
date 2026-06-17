/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - closePromptDisplayIfDedicated
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_closePromptDisplayIfDedicated via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};
    if !(_disp getVariable ["WaldoEcoCore_IsDedicatedZeusPromptDisplay", false]) exitWith {};

    private _active = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    if (!isNull _active && {_active isEqualTo _disp}) then {
        uiNamespace setVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    };

    _disp closeDisplay 1;
