/*
 * Removes one WMP notification channel without disturbing unrelated panels.
 * Queued requests for the same channel are also discarded.
 *
 * Arguments: [channel]
 * Return: BOOL - true when an active or queued notification was removed
 */
if (!hasInterface) exitWith {false};
params [["_channel", "MISSION", [""]]];
_channel = toUpper _channel;

private _removed = false;
private _registry = +(uiNamespace getVariable ["Waldo_UiPanelRegistry", []]);
private _index = _registry findIf {(_x param [0, ""]) isEqualTo _channel};
if (_index >= 0) then {
    private _entry = _registry deleteAt _index;
    {if (!isNull _x) then {ctrlDelete _x;};} forEach (_entry param [1, []]);
    _removed = true;
};
uiNamespace setVariable ["Waldo_UiPanelRegistry", _registry];

private _queue = +(uiNamespace getVariable ["Waldo_UiPanelQueue", []]);
private _remaining = _queue select {toUpper (_x param [5, "MISSION"]) != _channel};
if ((count _remaining) != (count _queue)) then {_removed = true;};
uiNamespace setVariable ["Waldo_UiPanelQueue", _remaining];
[] call Waldo_fnc_ReflowUiPanels;
[] call Waldo_fnc_DrainUiNotificationQueue;
_removed
