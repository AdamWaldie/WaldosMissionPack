/*
 * Author: Waldo
 * Install prompt input guard.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoCore_installPromptInputGuard;
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};
    if !(isNil {_disp getVariable "WaldoEcoCore_InputGuardEH"}) exitWith {};

    private _eh = _disp displayAddEventHandler ["KeyDown", {
        params ["_display", "_key", "_shift", "_ctrl", "_alt"];

        private _targets = _display getVariable ["WaldoEcoCore_InputTargets", []];
        if ((count _targets) <= 0) exitWith {false};

        private _focused = focusedCtrl _display;
        if (isNull _focused) exitWith {false};
        if ((_targets find _focused) < 0) exitWith {false};

        if (_ctrl || _alt) exitWith {false};
        if (_key isEqualTo 14) exitWith {true};
        if (_key in (_display getVariable ["WaldoEcoCore_InputPassthroughKeys", [14, 28, 156, 211]])) exitWith {false};

        true
    }];

    _disp setVariable ["WaldoEcoCore_InputGuardEH", _eh];
