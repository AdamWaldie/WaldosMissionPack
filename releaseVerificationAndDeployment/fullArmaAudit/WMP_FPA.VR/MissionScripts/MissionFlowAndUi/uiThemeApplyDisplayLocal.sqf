/*
 * Author: WaldoTheWarfighter
 * Applies the active visual theme to an already-created WMP child display. Fonts and buttons are
 * normalised for every variant; button labels shrink to fit when a theme font is wider. Neutral panels, buttons, edits and lists receive era-specific
 * material tokens, while semantic state colours come from the player's colour-vision profile.
 * Saturated puzzle pieces and map symbology remain untouched because they also carry labels/patterns.
 *
 * Arguments:
 * 0: display <DISPLAY>
 * 1: restyle neutral panels <BOOL> (default true)
 *
 * Return Value: BOOL - true when a live display was processed.
 *
 * Example: [_display, true] call Waldo_fnc_UiThemeApplyDisplayLocal;
 * Current callers: party-game display guard and live UI-theme apply path.
 * Locality and authority: Restyles only controls in this client's live display. Repeating
 * it updates presentation without server or JIP gameplay changes.
 * Result: The selected display uses current WMP theme and accessibility colours.
 */

disableSerialization;
params [["_display", displayNull, [displayNull]], ["_restylePanels", true, [true]]];
if (isNull _display) exitWith {false};
private _theme = [] call Waldo_fnc_UiTheme;
{
    private _control = _x;
    private _type = ctrlType _control;
    if (_type in [0, 1, 2, 11, 12, 13, 16, 41, 44]) then {
        _control ctrlSetFont (_theme getOrDefault ["font", "RobotoCondensed"]);
    };
    if (_type in [1, 16] && {ctrlText _control != ""}) then {
        // A live theme change can swap in a much wider font. Start from the size the button had
        // before any theme fit, then shrink only as far as needed to keep its label inside it.
        private _baseHeight = _control getVariable ["Waldo_UI_BaseFontHeight", ctrlFontHeight _control];
        _control setVariable ["Waldo_UI_BaseFontHeight", _baseHeight];
        private _width = (ctrlPosition _control) select 2;
        private _fontHeight = _baseHeight;
        private _minimumFont = _baseHeight * 0.55;
        _control ctrlSetFontHeight _fontHeight;
        while {_width > 0 && {_fontHeight > _minimumFont} && {ctrlTextWidth _control > (_width * 0.94)}} do {
            _fontHeight = (_fontHeight - 0.001) max _minimumFont;
            _control ctrlSetFontHeight _fontHeight;
        };
    };
    if (_type in [1, 16]) then {
        _control ctrlSetBackgroundColor (_theme getOrDefault ["button", _theme getOrDefault ["header", [0.035, 0.16, 0.28, 0.98]]]);
        _control ctrlSetActiveColor (_theme getOrDefault ["accentActive", [0.08, 0.48, 0.78, 1]]);
        _control ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
    };
    if (_type in [2, 6]) then {
        _control ctrlSetBackgroundColor (_theme getOrDefault ["edit", [0.015, 0.045, 0.07, 1]]);
        _control ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
    };
    if (_type in [4, 5, 102]) then {
        _control ctrlSetBackgroundColor (_theme getOrDefault ["list", [0.018, 0.035, 0.052, 1]]);
        _control ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
    };
    if (_restylePanels && {_type in [0, 5]}) then {
        private _colour = ctrlBackgroundColor _control;
        if (count _colour >= 4 && {(_colour select 3) > 0.2}) then {
            private _red = _colour select 0;
            private _green = _colour select 1;
            private _blue = _colour select 2;
            private _maximum = _red max _green max _blue;
            private _minimum = _red min _green min _blue;
            private _chroma = _maximum - _minimum;
            if (_maximum < 0.22) then {
                _control ctrlSetBackgroundColor (_theme getOrDefault ["panel", _colour]);
            } else {
                if (_maximum < 0.42 && {_chroma < 0.14}) then {
                    _control ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", _colour]);
                };
            };
        };
    };
    _control ctrlCommit 0;
} forEach allControls _display;
_display setVariable ["Waldo_UI_ThemedDisplay", true];
true
