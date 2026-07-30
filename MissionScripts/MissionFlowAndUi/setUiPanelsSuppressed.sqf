/* Temporarily hides WMP notification cards while a higher-priority local UI owns the view. */
params [["_suppressed", false, [true]]];
if (!hasInterface) exitWith {false};

uiNamespace setVariable ["Waldo_UI_PanelsSuppressed", _suppressed];
{
    {
        if (!isNull _x) then {_x ctrlShow !_suppressed};
    } forEach (_x param [1, []]);
} forEach (uiNamespace getVariable ["Waldo_UiPanelRegistry", []]);

if (!_suppressed) then {
    [0] call Waldo_fnc_ReflowUiPanels;
    [] call Waldo_fnc_DrainUiNotificationQueue;
};
true
