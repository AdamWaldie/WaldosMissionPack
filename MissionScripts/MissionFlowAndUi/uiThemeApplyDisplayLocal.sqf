/*
 * Author: WaldoTheWarfighter
 * Applies the active visual theme to an already-created WMP child display. Fonts and buttons are
 * normalised for every variant. For non-default themes, neutral dark chrome is remapped by luminance
 * while saturated game pieces, semantic colours, map symbology and functional state colours remain
 * untouched. This lets party-game boards share the global era style without obscuring gameplay.
 *
 * Arguments:
 * 0: display <DISPLAY>
 * 1: restyle neutral panels <BOOL> (default true)
 *
 * Return Value: BOOL - true when a live display was processed.
 *
 * Example: [_display, true] call Waldo_fnc_UiThemeApplyDisplayLocal;
 * Current callers: party-game display guard and live UI-theme apply path.
 */

disableSerialization;
params [["_display", displayNull, [displayNull]], ["_restylePanels", true, [true]]];
if (isNull _display) exitWith {false};
private _theme = [] call Waldo_fnc_UiTheme;
private _themeId = _theme getOrDefault ["id", "DEFAULT"];
{
    private _control = _x;
    private _type = ctrlType _control;
    if (_type in [0, 1, 2, 11, 12, 13, 16, 41, 44]) then {
        _control ctrlSetFont (_theme getOrDefault ["font", "RobotoCondensed"]);
    };
    if (_themeId != "DEFAULT" && {_type in [1, 16]}) then {
        _control ctrlSetBackgroundColor (_theme getOrDefault ["header", [0.035, 0.16, 0.28, 0.98]]);
        _control ctrlSetActiveColor (_theme getOrDefault ["accentActive", [0.08, 0.48, 0.78, 1]]);
        _control ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
    };
    if (_restylePanels && {_themeId != "DEFAULT"} && {_type in [0, 5]}) then {
        private _colour = ctrlBackgroundColor _control;
        if (count _colour >= 4 && {(_colour select 3) > 0.2}) then {
            private _red = _colour select 0;
            private _green = _colour select 1;
            private _blue = _colour select 2;
            private _maximum = _red max _green max _blue;
            private _minimum = _red min _green min _blue;
            private _chroma = _maximum - _minimum;
            if (_maximum < 0.18) then {
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
