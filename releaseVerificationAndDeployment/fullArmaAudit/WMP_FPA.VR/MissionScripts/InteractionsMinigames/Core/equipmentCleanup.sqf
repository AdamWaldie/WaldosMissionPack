/* Cancels active input and removes every shared display handler and worker. */
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
true
