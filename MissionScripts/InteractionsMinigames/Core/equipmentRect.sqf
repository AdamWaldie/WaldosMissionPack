/*
 * Author: WaldoTheWarfighter
 * Purpose: Converts a 40 x 25 equipment-grid rectangle to local control-group coordinates.
 * Locality/Authority: Interface client only; reads the display's grid-cell dimensions.
 * Repeat/JIP Behaviour: Pure conversion for each call; no persistent or JIP state.
 * Arguments: 0: display <DISPLAY>, default displayNull; 1: [x,y,w,h] grid rectangle
 * <ARRAY of NUMBER>, default [0,0,0,0].
 * Return Value: <ARRAY [x,y,w,h]> local coordinates; zeros for invalid input.
 * Current Callers: MiniGameEquipmentCreateControl and MiniGameEquipmentSetPosition.
 * Example: [_display, [1, 2, 8, 1]] call Waldo_fnc_MiniGameEquipmentRect;
 * Result: The grid rectangle is scaled to the display's current cell size.
 */
params [
    ["_display", displayNull, [displayNull]],
    ["_rect", [0, 0, 0, 0], [[]]]
];
if (isNull _display || {count _rect < 4}) exitWith {[0, 0, 0, 0]};
private _cell = _display getVariable ["Waldo_MG_UI_GridCell", [0, 0]];
[
    (_rect select 0) * (_cell select 0),
    (_rect select 1) * (_cell select 1),
    (_rect select 2) * (_cell select 0),
    (_rect select 3) * (_cell select 1)
]
