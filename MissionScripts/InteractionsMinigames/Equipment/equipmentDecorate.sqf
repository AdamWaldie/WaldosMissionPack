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

// Recessed inner face and four fasteners make the common safe-zone feel like a physical unit.
private _recess = _display ctrlCreate ["RscText", -1];
_recess ctrlSetPosition [_x, _y, _w, _h];
_recess ctrlSetBackgroundColor [0.035, 0.04, 0.038, 0.88];
_recess ctrlCommit 0;

{
    _x params ["_sx", "_sy"];
    private _screw = _display ctrlCreate ["RscText", -1];
    _screw ctrlSetPosition [_sx, _sy, 0.012 * safezoneW, 0.018 * safezoneH];
    _screw ctrlSetBackgroundColor [0.42, 0.43, 0.39, 1];
    _screw ctrlSetText "+";
    _screw ctrlSetTextColor [0.08, 0.08, 0.07, 1];
    _screw ctrlSetFontHeight (0.014 * safezoneH);
    _screw ctrlCommit 0;
} forEach [
    [_x + 0.008 * safezoneW, _y + 0.008 * safezoneH],
    [_x + _w - 0.020 * safezoneW, _y + 0.008 * safezoneH],
    [_x + 0.008 * safezoneW, _y + _h - 0.026 * safezoneH],
    [_x + _w - 0.020 * safezoneW, _y + _h - 0.026 * safezoneH]
];

private _bus = _display ctrlCreate ["RscText", -1];
_bus ctrlSetPosition [_x + 0.03 * safezoneW, _y + 0.045 * safezoneH, _w - 0.06 * safezoneW, 0.003 * safezoneH];
_bus ctrlSetBackgroundColor _accent;
_bus ctrlCommit 0;
