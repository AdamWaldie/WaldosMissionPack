/*
 * Author: WaldoTheWarfighter
 * Opens the local colour-vision accessibility selector. Named buttons explain each profile; a
 * selection is applied immediately, persisted to the player's profile and demonstrated through
 * the normal notification stack after the selector closes.
 *
 * Arguments: None.
 * Return Value: DISPLAY - created selector, or displayNull when no gameplay display exists.
 *
 * Example:
 * [] call Waldo_fnc_UiColourVisionOpenLocal;
 * Current caller: Accessibility self-interaction category.
 */

disableSerialization;
if (!hasInterface) exitWith {displayNull};
private _parent = findDisplay 46;
if (isNull _parent) exitWith {displayNull};
private _display = _parent createDisplay "RscDisplayEmpty";
_display setVariable ["Waldo_UI_ThemedDisplay", true];
private _theme = [] call Waldo_fnc_UiTheme;
private _panelW = safeZoneW * 0.50;
private _panelH = safeZoneH * 0.70;
private _panelX = safeZoneX + ((safeZoneW - _panelW) / 2);
private _panelY = safeZoneY + ((safeZoneH - _panelH) / 2);
private _back = _display ctrlCreate ["RscText", -1];
_back ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_back ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.01, 0.02, 0.03, 0.98]]);
_back ctrlCommit 0;
private _header = _display ctrlCreate ["RscStructuredText", -1];
_header ctrlSetPosition [_panelX + (_panelW * 0.04), _panelY + (_panelH * 0.035), _panelW * 0.92, _panelH * 0.13];
_header ctrlSetStructuredText parseText format ["<t font='%1' size='1.35' color='%2'>ACCESSIBILITY // COLOUR VISION</t><br/><t font='%3' size='0.86' color='%4'>Choose a personal semantic palette. Labels, symbols, patterns and state words remain active in every mode.</t>", _theme getOrDefault ["fontBold", "RobotoCondensedBold"], _theme getOrDefault ["accentHex", "#79C7FF"], _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["textHex", "#FFFFFF"]];
_header ctrlCommit 0;
private _ids = ["STANDARD", "RED_GREEN", "PROTAN", "TRITAN", "HIGH_CONTRAST"];
private _buttonY = _panelY + (_panelH * 0.19);
{
    private _profile = [_x] call Waldo_fnc_UiColourVisionProfile;
    private _button = _display ctrlCreate ["RscButton", -1];
    _button ctrlSetPosition [_panelX + (_panelW * 0.055), _buttonY, _panelW * 0.31, _panelH * 0.095];
    _button ctrlSetText (_profile getOrDefault ["label", _x]);
    _button ctrlSetFont (_theme getOrDefault ["font", "RobotoCondensed"]);
    _button ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
    _button ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.05, 0.06, 0.07, 1]]);
    _button ctrlSetActiveColor (_theme getOrDefault ["accentActive", [0.1, 0.5, 0.8, 1]]);
    _button setVariable ["Waldo_UI_ColourVisionChoice", _x];
    _button ctrlAddEventHandler ["ButtonClick", {
        params ["_control"];
        private _choice = _control getVariable ["Waldo_UI_ColourVisionChoice", "STANDARD"];
        (ctrlParent _control) closeDisplay 1;
        [_choice, true] call Waldo_fnc_UiColourVisionApplyLocal;
    }];
    _button ctrlCommit 0;
    private _description = _display ctrlCreate ["RscStructuredText", -1];
    _description ctrlSetPosition [_panelX + (_panelW * 0.39), _buttonY + (_panelH * 0.008), _panelW * 0.555, _panelH * 0.085];
    _description ctrlSetStructuredText parseText format ["<t font='%1' size='0.82' color='%2'>%3</t>", _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["mutedHex", "#9FB3C8"], _profile getOrDefault ["description", ""]];
    _description ctrlCommit 0;
    _buttonY = _buttonY + (_panelH * 0.115);
} forEach _ids;
private _close = _display ctrlCreate ["RscButton", -1];
_close ctrlSetPosition [_panelX + (_panelW * 0.35), _panelY + (_panelH * 0.88), _panelW * 0.30, _panelH * 0.075];
_close ctrlSetText "CLOSE";
_close ctrlSetBackgroundColor (_theme getOrDefault ["header", [0.04, 0.2, 0.34, 1]]);
_close ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
_close ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this select 0)) closeDisplay 2;}];
_close ctrlCommit 0;
[_display, true] call Waldo_fnc_UiThemeApplyDisplayLocal;
_display
