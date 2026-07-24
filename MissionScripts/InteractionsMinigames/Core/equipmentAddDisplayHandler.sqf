/* Adds and registers a display event handler for deterministic cleanup. */
disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_event", "", [""]],
    ["_callback", {}, [{}]]
];
if (isNull _display || {_event == ""}) exitWith {-1};
private _id = _display displayAddEventHandler [_event, _callback];
private _handlers = _display getVariable ["Waldo_MG_UI_DisplayHandlers", []];
_handlers pushBack [_event, _id];
_display setVariable ["Waldo_MG_UI_DisplayHandlers", _handlers];
_id
