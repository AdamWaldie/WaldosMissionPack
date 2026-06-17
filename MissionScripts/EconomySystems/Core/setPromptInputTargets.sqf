/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - setPromptInputTargets
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_setPromptInputTargets via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_disp", displayNull],
        ["_targets", []],
        ["_focusCtrl", controlNull],
        ["_targetsVarName", ""],
        ["_passthroughKeys", [14, 28, 156, 211]]
    ];

    if (isNull _disp) exitWith {};
    if (_targetsVarName isEqualTo "") exitWith {};

    private _filtered = _targets select {!isNull _x};
    _disp setVariable [_targetsVarName, _filtered];
    _disp setVariable ["WaldoEcoCore_InputTargets", _filtered];
    _disp setVariable ["WaldoEcoCore_InputPassthroughKeys", _passthroughKeys];
    [_disp] call Waldo_fnc_EcoCore_installPromptInputGuard;

    if (!isNull _focusCtrl) then {
        ctrlSetFocus _focusCtrl;
    };
