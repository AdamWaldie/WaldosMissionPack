/* Adds equipment-specific faceplate details to a challenge content area. */
disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_content", [], [[]]]
];
if (isNull _display || {(count _content) < 4}) exitWith {};
_content params ["_x", "_y", "_w", "_h"];
private _profile = _display getVariable ["Waldo_IMG_Profile", createHashMap];
private _accent = _profile getOrDefault ["accent", [0.8, 0.6, 0.2, 1]];
private _cellW = _w / 40;
private _cellH = _h / 25;
private _created = [];

// Recessed inner face and four fasteners make the common safe-zone feel like a physical unit.
private _recess = _display ctrlCreate ["RscText", -1];
_recess ctrlSetPosition [_x, _y, _w, _h];
_recess ctrlSetBackgroundColor [0.035, 0.04, 0.038, 0.88];
_recess ctrlCommit 0;
_created pushBack _recess;

{
    _x params ["_sx", "_sy"];
    private _screw = _display ctrlCreate ["RscText", -1];
    _screw ctrlSetPosition [_sx, _sy, 0.48 * _cellW, 0.48 * _cellH];
    _screw ctrlSetBackgroundColor [0.42, 0.43, 0.39, 1];
    _screw ctrlSetText "+";
    _screw ctrlSetTextColor [0.08, 0.08, 0.07, 1];
    _screw ctrlSetFontHeight (0.34 * _cellH);
    _screw ctrlCommit 0;
    _created pushBack _screw;
} forEach [
    [_x + (0.55 * _cellW), _y + (0.55 * _cellH)],
    [_x + _w - (1.03 * _cellW), _y + (0.55 * _cellH)],
    [_x + (0.55 * _cellW), _y + _h - (1.03 * _cellH)],
    [_x + _w - (1.03 * _cellW), _y + _h - (1.03 * _cellH)]
];

private _bus = _display ctrlCreate ["RscText", -1];
_bus ctrlSetPosition [_x + (1.2 * _cellW), _y + (1.15 * _cellH), _w - (2.4 * _cellW), 0.12 * _cellH];
_bus ctrlSetBackgroundColor _accent;
_bus ctrlCommit 0;
_created pushBack _bus;
private _shellControls = _display getVariable ["Waldo_MG_UI_ShellControls", []];
_shellControls append _created;
_display setVariable ["Waldo_MG_UI_ShellControls", _shellControls];
