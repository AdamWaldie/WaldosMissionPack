/*
 * Author: WaldoTheWarfighter
 * Purpose: Repositions an equipment control using the local 40 x 25 grid.
 * Locality/Authority: Interface client only; changes one local control.
 * Repeat/JIP Behaviour: Repeated calls replace the same control position; no JIP replay.
 * Arguments: 0: display <DISPLAY>, default displayNull; 1: control <CONTROL>, default controlNull;
 * 2: [x,y,w,h] grid rectangle <ARRAY>, default [0,0,1,1]; 3: commit time <NUMBER>, default 0.
 * Return Value: <BOOL> true when repositioned, false for a null handle.
 * Current Callers: Field-equipment challenge UI and animation callbacks.
 * Example: [_display, _needle, [10, 5, 1, 3], 0.1]
 *          call Waldo_fnc_MiniGameEquipmentSetPosition;
 * Result: The control moves to the requested grid rectangle.
 */
disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_control", controlNull, [controlNull]],
    ["_rect", [0, 0, 1, 1], [[]]],
    ["_commit", 0, [0]]
];
if (isNull _display || {isNull _control}) exitWith {false};
_control ctrlSetPosition ([_display, _rect] call Waldo_fnc_MiniGameEquipmentRect);
_control ctrlCommit _commit;
_control setVariable ["Waldo_MG_UI_GridRect", +_rect];
true
