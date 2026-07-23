/* Applies local, presentation-only accessibility settings to a completed equipment display. */
disableSerialization;
params [["_display", displayNull, [displayNull]]];
if (isNull _display || {_display getVariable ["Waldo_IMG_AccessibilityApplied", false]}) exitWith {};
_display setVariable ["Waldo_IMG_AccessibilityApplied", true];
private _profile = _display getVariable ["Waldo_IMG_Profile", createHashMap];
private _access = _profile getOrDefault ["accessibility", [] call Waldo_fnc_MiniGameAccessibility];

private _ok = if (_access getOrDefault ["colourblind", true]) then {[0.25, 0.72, 0.90, 1]} else {[0.35, 0.80, 0.45, 1]};
private _warning = [0.96, 0.76, 0.20, 1];
private _bad = if (_access getOrDefault ["colourblind", true]) then {[0.86, 0.36, 0.72, 1]} else {[0.90, 0.32, 0.28, 1]};
_display setVariable ["Waldo_IMG_ColourOK", _ok];
_display setVariable ["Waldo_IMG_ColourWarning", _warning];
_display setVariable ["Waldo_IMG_ColourBad", _bad];
_display setVariable ["Waldo_IMG_ReducedMotion", _access getOrDefault ["reducedMotion", false]];
_display setVariable ["Waldo_IMG_AudioCaptions", _access getOrDefault ["audioCaptions", true]];

if (_access getOrDefault ["largeText", false]) then {
    {
        private _height = ctrlFontHeight _x;
        if (_height > 0 && {_height < (0.045 * safezoneH)}) then {
            _x ctrlSetFontHeight ((_height * 1.10) min (0.045 * safezoneH));
            _x ctrlCommit 0;
        };
    } forEach allControls _display;
};

if (_access getOrDefault ["strongOutlines", true]) then {
    private _bounds = _display getVariable ["Waldo_IMG_Bounds", [safezoneX + 0.1 * safezoneW, safezoneY + 0.05 * safezoneH, 0.8 * safezoneW, 0.9 * safezoneH]];
    _bounds params ["_x", "_y", "_w", "_h"];
    private _thicknessW = 0.003 * safezoneW;
    private _thicknessH = 0.004 * safezoneH;
    {
        private _edge = _display ctrlCreate ["RscText", -1];
        _edge ctrlSetPosition _x;
        _edge ctrlSetBackgroundColor _warning;
        _edge ctrlCommit 0;
    } forEach [
        [_x, _y, _w, _thicknessH],
        [_x, _y + _h - _thicknessH, _w, _thicknessH],
        [_x, _y, _thicknessW, _h],
        [_x + _w - _thicknessW, _y, _thicknessW, _h]
    ];
};
