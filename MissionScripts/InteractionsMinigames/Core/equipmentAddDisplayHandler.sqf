/*
 * Author: WaldoTheWarfighter
 * Purpose: Installs a display event handler and records its ID for equipment cleanup.
 * Locality/Authority: Interface client only; the handler belongs to a local display.
 * Repeat/JIP Behaviour: Every call adds one handler; cleanup removes recorded IDs. No JIP replay.
 * Arguments: 0: display <DISPLAY>, default displayNull; 1: event name <STRING>, default "";
 * 2: callback <CODE>, default {}.
 * Return Value: Handler ID <NUMBER>, or -1 for a null display/empty event.
 * Current Callers: Field-equipment challenge openers and MiniGameChallengeUI.
 * Example: [_display, "KeyDown", {false}] call Waldo_fnc_MiniGameEquipmentAddDisplayHandler;
 * Result: The handler is installed and will be removed with the equipment display.
 */
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
