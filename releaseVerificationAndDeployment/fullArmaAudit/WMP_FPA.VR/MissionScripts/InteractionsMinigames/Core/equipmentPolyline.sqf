/*
 * Author: WaldoTheWarfighter
 * Purpose: Draws a procedural polyline as small square controls. This deliberately avoids
 * ctrlSetAngle, which does not rotate filled procedural controls in Arma.
 * Locality/Authority: Interface client only; creates local controls.
 * Repeat/JIP Behaviour: Each call creates a new set of controls; nothing is replayed to JIP.
 * Arguments: 0: display <DISPLAY>, default displayNull; 1: grid points <ARRAY>, default [];
 * 2: RGBA colour <ARRAY>, default [0.8,0.8,0.8,1]; 3: grid-cell thickness <NUMBER>,
 * default 0.18; 4: semantic label <STRING>, default "instrument line".
 * Return Value: <ARRAY of CONTROL> generated line segments, or [] for invalid input.
 * Current Callers: Wire-cut and circuit challenge displays.
 * Example: [_display, [[2,2],[8,2]], [1,0,0,1], 0.18, "red wire"]
 *          call Waldo_fnc_MiniGameEquipmentPolyline;
 * Result: A visible line made of recorded equipment controls.
 */
disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_points", [], [[]]],
    ["_colour", [0.8, 0.8, 0.8, 1], [[]]],
    ["_thickness", 0.18, [0]],
    ["_semanticLabel", "instrument line", [""]]
];
if (isNull _display || {count _points < 2}) exitWith {[]};
private _segments = [];
for "_pointIndex" from 0 to ((count _points) - 2) do {
    private _start = _points select _pointIndex;
    private _end = _points select (_pointIndex + 1);
    private _dx = (_end select 0) - (_start select 0);
    private _dy = (_end select 1) - (_start select 1);
    private _steps = (ceil (((abs _dx) max (abs _dy)) / (_thickness max 0.08))) max 1;
    for "_step" from 0 to _steps do {
        private _progress = _step / _steps;
        private _control = [_display, "RscText", [
            (_start select 0) + (_dx * _progress) - (_thickness / 2),
            (_start select 1) + (_dy * _progress) - (_thickness / 2),
            _thickness,
            _thickness
        ], _semanticLabel] call Waldo_fnc_MiniGameEquipmentCreateControl;
        _control ctrlSetBackgroundColor _colour;
        _segments pushBack _control;
    };
};
_segments
