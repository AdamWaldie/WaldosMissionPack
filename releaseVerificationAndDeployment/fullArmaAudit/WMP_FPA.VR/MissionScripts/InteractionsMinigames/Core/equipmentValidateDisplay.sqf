/*
 * Performs runtime layout checks against the actual Arma-created controls.
 * Returns arrays: [severity, code, semanticLabel, details].
 */
disableSerialization;
params [["_display", displayNull, [displayNull]], ["_log", false, [false]]];
if (isNull _display) exitWith {[["ERROR", "DISPLAY_NULL", "display", "No equipment display exists"]]};
private _findings = [];
private _protected = [];
private _visibleLeft = safeZoneX;
private _visibleTop = safeZoneY;
private _visibleRight = safeZoneX + safeZoneW;
private _visibleBottom = safeZoneY + safeZoneH;
{
    if (!isNull _x && {ctrlShown _x}) then {
        private _position = ctrlPosition _x;
        _position params ["_xPos", "_yPos", "_width", "_height"];
        private _label = ctrlText _x;
        if (_width <= 0 || {_height <= 0}) then {
            _findings pushBack ["ERROR", "SHELL_INVALID_SIZE", _label, str _position];
        };
        if (_xPos < (_visibleLeft - 0.001)
            || {_yPos < (_visibleTop - 0.001)
            || {_xPos + _width > (_visibleRight + 0.001)
            || {_yPos + _height > (_visibleBottom + 0.001)}}}) then {
            _findings pushBack ["ERROR", "SHELL_OUTSIDE_VISIBLE_AREA", _label, str _position];
        };
        if (ctrlType _x in [0, 1, 11, 13, 16, 41] && {_label != ""}) then {
            if (ctrlTextHeight _x > (_height * 1.04)) then {
                _findings pushBack ["ERROR", "SHELL_TEXT_HEIGHT_CLIPPED", _label, format ["text=%1 control=%2", ctrlTextHeight _x, _height]];
            };
            if (ctrlType _x in [0, 1, 2, 11, 16, 41] && {ctrlTextWidth _x > (_width * 0.97)}) then {
                _findings pushBack ["ERROR", "SHELL_TEXT_WIDTH_CLIPPED", _label, format ["text=%1 control=%2", ctrlTextWidth _x, _width]];
            };
        };
    };
} forEach (_display getVariable ["Waldo_MG_UI_ShellControls", []]);
{
    if (!isNull _x) then {
        private _rect = _x getVariable ["Waldo_MG_UI_GridRect", []];
        private _label = _x getVariable ["Waldo_MG_UI_SemanticLabel", ""];
        if (count _rect == 4) then {
            _rect params ["_xPos", "_yPos", "_width", "_height"];
            if (_width <= 0 || {_height <= 0}) then {
                _findings pushBack ["ERROR", "INVALID_SIZE", _label, str _rect];
            };
            if (_xPos < -0.01 || {_yPos < -0.01 || {_xPos + _width > 40.01 || {_yPos + _height > 25.01}}}) then {
                _findings pushBack ["ERROR", "OUT_OF_BOUNDS", _label, str _rect];
            };
            if (_x getVariable ["Waldo_MG_UI_ProtectedRegion", false] && {ctrlShown _x}) then {
                _protected pushBack [_x, _label, _rect];
            };
        };
        if (_label == "" && {ctrlType _x in [1, 11, 12, 16, 41]}) then {
            _findings pushBack ["WARNING", "MISSING_SEMANTIC_LABEL", ctrlText _x, str _rect];
        };
        if (ctrlType _x in [0, 1, 11, 13, 16, 41] && {ctrlText _x != ""}) then {
            if ((ctrlText _x) find "\n" >= 0) then {
                _findings pushBack ["ERROR", "LITERAL_NEWLINE_ESCAPE", _label, ctrlText _x];
            };
            private _position = ctrlPosition _x;
            private _textHeight = ctrlTextHeight _x;
            if (_textHeight > ((_position select 3) * 1.04)) then {
                _findings pushBack ["ERROR", "TEXT_CLIPPED", _label, format ["text=%1 control=%2", _textHeight, _position select 3]];
            };
            if (ctrlType _x in [0, 1, 2, 11, 16, 41] && {(ctrlTextWidth _x) > ((_position select 2) * 0.96)}) then {
                _findings pushBack ["ERROR", "TEXT_WIDTH_CLIPPED", _label, format ["text=%1 control=%2", ctrlTextWidth _x, _position select 2]];
            };
        };
    };
} forEach (_display getVariable ["Waldo_MG_UI_EquipmentControls", []]);
for "_leftIndex" from 0 to ((count _protected) - 2) do {
    private _left = _protected select _leftIndex;
    (_left select 2) params ["_leftX", "_leftY", "_leftW", "_leftH"];
    for "_rightIndex" from (_leftIndex + 1) to ((count _protected) - 1) do {
        private _right = _protected select _rightIndex;
        (_right select 2) params ["_rightX", "_rightY", "_rightW", "_rightH"];
        private _overlaps = _leftX < (_rightX + _rightW) && {_leftX + _leftW > _rightX && {_leftY < (_rightY + _rightH) && {_leftY + _leftH > _rightY}}};
        if (_overlaps) then {
            _findings pushBack ["ERROR", "PROTECTED_OVERLAP", format ["%1 / %2", _left select 1, _right select 1], format ["%1 intersects %2", _left select 2, _right select 2]];
        };
    };
};
if (_log) then {
    diag_log format ["WMP INTERACTION UI VALIDATION: %1 finding(s) %2", count _findings, _findings];
};
_display setVariable ["Waldo_MG_UI_ValidationFindings", _findings];
_findings
