/*
 * Author: WaldoTheWarfighter
 * Purpose: Binds pointer-captured dragging to an equipment control. Callback arguments are
 * [display, control, localGridPosition, phase], with START/MOVE/END/CANCEL phases.
 * Locality/Authority: Interface client only; operates on a local display and control.
 * Repeat/JIP Behaviour: Bind once per control. The display cleanup cancels active drags;
 * no open drag is replayed to a joining player.
 * Arguments: 0: display <DISPLAY>, default displayNull; 1: control <CONTROL>, default controlNull;
 * 2: phase callback <CODE>, default {}.
 * Return Value: <BOOL> true if bound, false if either UI handle is null.
 * Current Callers: Field-equipment challenge openers with draggable controls.
 * Example: [_display, _slider, {params ["_display", "_control", "_grid", "_phase"]}]
 *          call Waldo_fnc_MiniGameEquipmentBindDrag;
 * Result: Left-button dragging invokes the callback in local 40 x 25 grid coordinates.
 */
disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_control", controlNull, [controlNull]],
    ["_callback", {}, [{}]]
];
if (isNull _display || {isNull _control}) exitWith {false};
_control setVariable ["Waldo_MG_UI_DragCallback", _callback];
_control ctrlAddEventHandler ["MouseButtonDown", {
    params ["_control", "_button"];
    if (_button != 0) exitWith {false};
    private _display = ctrlParent _control;
    if (isNull _display || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {false};
    _display setVariable ["Waldo_MG_UI_DragControl", _control];
    getMousePosition params ["_mouseX", "_mouseY"];
    private _bounds = _display getVariable ["Waldo_MG_UI_Content", [0, 0, 1, 1]];
    private _local = [
        40 * ((_mouseX - (_bounds select 0)) / ((_bounds select 2) max 0.0001)),
        25 * ((_mouseY - (_bounds select 1)) / ((_bounds select 3) max 0.0001))
    ];
    [_display, _control, _local, "START"] call (_control getVariable ["Waldo_MG_UI_DragCallback", {}]);
    true
}];
true
