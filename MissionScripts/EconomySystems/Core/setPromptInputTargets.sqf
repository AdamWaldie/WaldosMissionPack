/*
 * Author: Waldo
 * Set prompt input targets.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 * 1: _targets <ARRAY> - targets (optional, default: [])
 * 2: _focusCtrl <ANY> - focus ctrl (optional, default: controlNull)
 * 3: _targetsVarName <STRING> - targets var name (optional, default: "")
 * 4: _passthroughKeys <ARRAY> - passthrough keys (optional, default: [14, 28, 156, 211])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _targets, _focusCtrl, _targetsVarName, _passthroughKeys] call Waldo_fnc_EcoCore_setPromptInputTargets;
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
