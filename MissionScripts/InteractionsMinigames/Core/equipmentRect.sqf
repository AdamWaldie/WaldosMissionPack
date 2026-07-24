/* Converts a 40 x 25 equipment-grid rectangle to control-group-local coordinates. */
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
