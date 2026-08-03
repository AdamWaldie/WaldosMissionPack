/*
 * Author: WaldoTheWarfighter
 * Temporarily hides every concurrent WMP HUD card while a higher-priority local interface owns the
 * view. Notification stacks, SafeStart and electronic-warfare controls are restored together and
 * immediately reflowed, preserving queued state without drawing through ACE interaction.
 *
 * Arguments:
 * 0: suppressed <BOOL> (default false)
 *
 * Return Value: BOOL - true after the local HUD visibility state is applied.
 *
 * Example: [true] call Waldo_fnc_SetUiPanelsSuppressed;
 * Current caller: SetupUiAcePriority ACE interaction open/close event handlers.
 */
params [["_suppressed", false, [true]]];
if (!hasInterface) exitWith {false};

uiNamespace setVariable ["Waldo_UI_PanelsSuppressed", _suppressed];
{
    {
        if (!isNull _x) then {_x ctrlShow !_suppressed};
    } forEach (_x param [1, []]);
} forEach (uiNamespace getVariable ["Waldo_UiPanelRegistry", []]);

private _display = findDisplay 46;
if (!isNull _display) then {
    {
        private _control = _display displayCtrl _x;
        if (!isNull _control) then {_control ctrlShow !_suppressed};
    } forEach [5299, 5300, 5309, 5310];
};

if (!_suppressed) then {
    [0] call Waldo_fnc_ReflowUiPanels;
    [] call Waldo_fnc_DrainUiNotificationQueue;
};
true
