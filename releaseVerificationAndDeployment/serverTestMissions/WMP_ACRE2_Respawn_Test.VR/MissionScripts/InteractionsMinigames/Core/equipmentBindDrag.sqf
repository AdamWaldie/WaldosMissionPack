/*
 * Registers pointer-captured dragging for an equipment control.
 * Callback signature: [display, control, localGridPosition, phase] where phase is START/MOVE/END/CANCEL.
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
