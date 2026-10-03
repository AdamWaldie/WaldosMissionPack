/*
 * Author: WaldoTheWarfighter
 * Purpose: Cancels active drag input and removes handlers and workers owned by one equipment display.
 * Locality/Authority: Interface client only; cleans the supplied local UI.
 * Repeat/JIP Behaviour: Stored lists are cleared, so repeat cleanup is safe; nothing persists for JIP.
 * Arguments: 0: display <DISPLAY>, default displayNull; 1: drag phase <STRING>, default "CANCEL".
 * Return Value: <BOOL> true for a valid display, false for displayNull.
 * Current Callers: MiniGameChallengeUI completion/abort paths.
 * Example: [_display, "CANCEL"] call Waldo_fnc_MiniGameEquipmentCleanup;
 * Result: Active input, display events, workers and per-frame handlers are stopped.
 */
disableSerialization;
params [["_display", displayNull, [displayNull]], ["_phase", "CANCEL", [""]]];
if (isNull _display) exitWith {false};
private _dragControl = _display getVariable ["Waldo_MG_UI_DragControl", controlNull];
if (!isNull _dragControl) then {
    [_display, _dragControl, [-1, -1], _phase] call (_dragControl getVariable ["Waldo_MG_UI_DragCallback", {}]);
};
_display setVariable ["Waldo_MG_UI_DragControl", controlNull];
{
    _x params ["_event", "_id"];
    _display displayRemoveEventHandler [_event, _id];
} forEach (_display getVariable ["Waldo_MG_UI_DisplayHandlers", []]);
_display setVariable ["Waldo_MG_UI_DisplayHandlers", []];
{
    if (!scriptDone _x) then {terminate _x;};
} forEach (_display getVariable ["Waldo_MG_UI_Workers", []]);
_display setVariable ["Waldo_MG_UI_Workers", []];
{
    removeMissionEventHandler ["EachFrame", _x];
} forEach (_display getVariable ["Waldo_MG_UI_EachFrameHandlers", []]);
_display setVariable ["Waldo_MG_UI_EachFrameHandlers", []];
true
