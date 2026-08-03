/*
 * Author: WaldoTheWarfighter
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
    private _active = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    if (!isNull _active && {_active isEqualTo _disp}) then {
        uiNamespace setVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    };

    if (_disp getVariable ["WaldoEcoCore_IsDedicatedZeusPromptDisplay", false]) exitWith {
        _disp closeDisplay 1;
    };

    _disp setVariable ["WaldoEcoCore_PromptToken", nil];
    _disp setVariable ["WaldoEcoCore_FitScheduled", false];
    private _owned = _disp getVariable ["WaldoEcoCore_PromptOwnedControls", []];
    if (_owned isEqualTo []) then {
        private _baseline = _disp getVariable ["WaldoEcoCore_PromptBaselineControls", []];
        _owned = (allControls _disp) select {!(_x in _baseline)};
    };
    {if (!isNull _x) then {ctrlDelete _x;};} forEach _owned;
    _disp setVariable ["WaldoEcoCore_PromptOwnedControls", []];
    _disp setVariable ["WaldoEcoCore_PromptBaselineControls", []];
    _disp setVariable ["WaldoEcoCore_PromptChromeControls", []];
    _disp setVariable ["WaldoEcoCore_PromptCardBounds", []];
    _disp setVariable ["WaldoEcoCore_PromptContentBounds", []];
