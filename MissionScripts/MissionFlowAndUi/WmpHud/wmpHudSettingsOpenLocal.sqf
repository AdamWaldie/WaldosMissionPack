/*
 * Author: WaldoTheWarfighter
 * Opens the local WMP HUD Settings screen. It exposes only presentation reductions and clearly
 * reports mission-owned availability. Apply persists local display choices; Cancel changes nothing;
 * Restore Defaults resets pending controls. Mission information restrictions, equipment gates,
 * UID exclusions and feature enablement remain authoritative. Local display creation is repeat-safe
 * and has no network/JIP side effects.
 *
 * Arguments: None.
 * Return Value: DISPLAY - created settings display, or displayNull without a gameplay display.
 * Current caller: WMP Options > WMP HUD self-interaction and QA capture.
 * Example: [] call Waldo_fnc_WmpHudSettingsOpenLocal;
 */

disableSerialization;
if (!hasInterface) exitWith {displayNull};
private _parent = findDisplay 46;
if (isNull _parent) exitWith {displayNull};
private _display = _parent createDisplay "RscDisplayEmpty";
_display setVariable ["Waldo_UI_ThemedDisplay", true];
private _theme = [] call Waldo_fnc_UiTheme;
private _w = safeZoneW min (safeZoneH * 1.333333);
private _panelW = _w * 0.58;
private _panelH = safeZoneH * 0.64;
private _panelX = safeZoneX + ((safeZoneW - _panelW) / 2);
private _panelY = safeZoneY + ((safeZoneH - _panelH) / 2);
private _back = _display ctrlCreate ["RscText", -1];
_back ctrlSetPosition [_panelX, _panelY, _panelW, _panelH]; _back ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.01,0.02,0.03,0.98]]); _back ctrlCommit 0;
private _enabled = missionNamespace getVariable ["Waldo_WmpHud_Enable", false];
private _eligible = _enabled && {[player] call Waldo_fnc_WmpHudEligible};
private _status = if (!_enabled) then {"UNAVAILABLE // DISABLED BY MISSION"} else {if (!_eligible) then {"LOCKED // MISSION ELIGIBILITY NOT MET"} else {"AVAILABLE // MISSION ELIGIBILITY MET"}};
private _header = _display ctrlCreate ["RscStructuredText", -1];
_header ctrlSetPosition [_panelX + _panelW * 0.05, _panelY + _panelH * 0.045, _panelW * 0.90, _panelH * 0.18];
_header ctrlSetStructuredText parseText format ["<t font='%1' size='1.25' color='%2'>WMP HUD SETTINGS</t><br/><t font='%1' size='0.82' color='%3'>%4</t><br/><t font='%5' size='0.78' color='%6'>These choices cannot expand mission-authorised information or bypass equipment restrictions.</t>", _theme getOrDefault ["fontBold", "RobotoCondensedBold"], _theme getOrDefault ["accentHex", "#79C7FF"], if (_eligible) then {_theme getOrDefault ["successHex", "#6CE5A8"]} else {_theme getOrDefault ["warningHex", "#FFD166"]}, _status, _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["mutedHex", "#9FB3C8"]];
_header ctrlCommit 0;
private _prefs = [] call Waldo_fnc_WmpHudPreferences;
private _labels = [["Information shown", 0.27], ["HUD scale", 0.39], ["HUD opacity", 0.51]];
private _combos = [];
{
    private _label = _display ctrlCreate ["RscText", -1];
    _label ctrlSetPosition [_panelX + _panelW * 0.06, _panelY + _panelH * (_x select 1), _panelW * 0.28, _panelH * 0.065];
    _label ctrlSetText (_x select 0); _label ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]); _label ctrlSetTextColor (_theme getOrDefault ["text", [1,1,1,1]]); _label ctrlCommit 0;
    private _combo = _display ctrlCreate ["RscCombo", -1];
    _combo ctrlSetPosition [_panelX + _panelW * 0.35, _panelY + _panelH * ((_x select 1) + 0.007), _panelW * 0.58, _panelH * 0.055]; _combo ctrlSetBackgroundColor (_theme getOrDefault ["list", [0.02,0.04,0.05,1]]); _combo ctrlCommit 0;
    _combos pushBack _combo;
} forEach _labels;
_combos params ["_displayCombo", "_scaleCombo", "_opacityCombo"];
private _missionIcons = missionNamespace getVariable ["Waldo_WmpHud_ShowIcons", true];
private _missionNames = missionNamespace getVariable ["Waldo_WmpHud_ShowNames", true];
private _displayOptions = [];
if (_missionIcons && {_missionNames}) then {_displayOptions = [["BOTH", "Icons and names"], ["ICONS", "Icons only"], ["NAMES", "Names only"], ["NONE", "Hidden"]];};
if (_missionIcons && {!_missionNames}) then {_displayOptions = [["ICONS", "Icons"], ["NONE", "Hidden"]];};
if (!_missionIcons && {_missionNames}) then {_displayOptions = [["NAMES", "Names"], ["NONE", "Hidden"]];};
if (!_missionIcons && {!_missionNames}) then {_displayOptions = [["NONE", "Hidden by mission"]];};
private _currentDisplay = if !(_prefs getOrDefault ["showIcons", true]) then {if (_prefs getOrDefault ["showNames", true]) then {"NAMES"} else {"NONE"}} else {if (_prefs getOrDefault ["showNames", true]) then {"BOTH"} else {"ICONS"}};
{private _i = _displayCombo lbAdd (_x select 1); _displayCombo lbSetData [_i, _x select 0]; if ((_x select 0) isEqualTo _currentDisplay) then {_displayCombo lbSetCurSel _i;};} forEach _displayOptions;
if (lbCurSel _displayCombo < 0) then {_displayCombo lbSetCurSel 0;};
{private _i = _scaleCombo lbAdd (_x select 1); _scaleCombo lbSetData [_i, _x select 0]; if ((_x select 0) isEqualTo (_prefs get "scaleId")) then {_scaleCombo lbSetCurSel _i;};} forEach [["SMALL", "Small"], ["MEDIUM", "Medium (Default)"], ["LARGE", "Large"]];
{private _i = _opacityCombo lbAdd (_x select 1); _opacityCombo lbSetData [_i, _x select 0]; if ((_x select 0) isEqualTo (_prefs get "opacityId")) then {_opacityCombo lbSetCurSel _i;};} forEach [["LOW", "Low"], ["MEDIUM", "Medium (Default)"], ["HIGH", "High"]];
_display setVariable ["Waldo_WmpHud_DisplayCombo", _displayCombo]; _display setVariable ["Waldo_WmpHud_ScaleCombo", _scaleCombo]; _display setVariable ["Waldo_WmpHud_OpacityCombo", _opacityCombo];
private _preview = _display ctrlCreate ["RscStructuredText", -1];
_preview ctrlSetPosition [_panelX + _panelW * 0.06, _panelY + _panelH * 0.62, _panelW * 0.87, _panelH * 0.105];
_preview ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.04,0.06,0.08,1]]);
_preview ctrlSetStructuredText parseText format ["<t align='center' font='%1' size='1.05' color='%2'>◇  FRIENDLY ELEMENT  //  42 m</t>", _theme getOrDefault ["fontBold", "RobotoCondensedBold"], _theme getOrDefault ["accentHex", "#79C7FF"]]; _preview ctrlCommit 0;
_display setVariable ["Waldo_WmpHud_Preview", _preview];
_display setVariable ["Waldo_WmpHud_PreviewTheme", _theme];
private _refreshPreview = {
    params ["_control"];
    private _d = ctrlParent _control;
    private _show = _d getVariable ["Waldo_WmpHud_DisplayCombo", controlNull];
    private _scale = _d getVariable ["Waldo_WmpHud_ScaleCombo", controlNull];
    private _opacity = _d getVariable ["Waldo_WmpHud_OpacityCombo", controlNull];
    private _previewControl = _d getVariable ["Waldo_WmpHud_Preview", controlNull];
    private _previewTheme = _d getVariable ["Waldo_WmpHud_PreviewTheme", createHashMap];
    private _mode = _show lbData (lbCurSel _show);
    private _scaleId = _scale lbData (lbCurSel _scale);
    private _opacityId = _opacity lbData (lbCurSel _opacity);
    private _copy = switch (_mode) do {case "ICONS": {"◇"}; case "NAMES": {"FRIENDLY ELEMENT  //  42 m"}; case "NONE": {"HUD HIDDEN BY PLAYER"}; default {"◇  FRIENDLY ELEMENT  //  42 m"};};
    private _textSize = switch (_scaleId) do {case "SMALL": {0.88}; case "LARGE": {1.22}; default {1.05};};
    _previewControl ctrlSetStructuredText parseText format ["<t align='center' font='%1' size='%2' color='%3'>%4</t>", _previewTheme getOrDefault ["fontBold", "RobotoCondensedBold"], _textSize, _previewTheme getOrDefault ["accentHex", "#79C7FF"], _copy];
    _previewControl ctrlSetFade (switch (_opacityId) do {case "LOW": {0.45}; case "HIGH": {0}; default {0.18};});
    _previewControl ctrlCommit 0;
};
_display setVariable ["Waldo_WmpHud_RefreshPreview", _refreshPreview];
{_x ctrlAddEventHandler ["LBSelChanged", {_this call ((ctrlParent (_this select 0)) getVariable "Waldo_WmpHud_RefreshPreview");}];} forEach [_displayCombo, _scaleCombo, _opacityCombo];
[_displayCombo] call _refreshPreview;
private _buttonY = _panelY + _panelH * 0.80;
private _makeButton = {params ["_x", "_width", "_text"]; private _b = _display ctrlCreate ["RscButton", -1]; _b ctrlSetPosition [_x, _buttonY, _width, _panelH * 0.078]; _b ctrlSetText _text; _b ctrlSetBackgroundColor (_theme getOrDefault ["button", [0.04,0.14,0.23,1]]); _b ctrlSetActiveColor (_theme getOrDefault ["buttonActive", [0.08,0.45,0.75,1]]); _b ctrlCommit 0; _b};
private _defaults = [_panelX + _panelW * 0.06, _panelW * 0.29, "RESTORE DEFAULTS"] call _makeButton;
private _cancel = [_panelX + _panelW * 0.50, _panelW * 0.19, "CANCEL"] call _makeButton;
private _apply = [_panelX + _panelW * 0.71, _panelW * 0.22, "APPLY"] call _makeButton;
_defaults ctrlAddEventHandler ["ButtonClick", {private _d = ctrlParent (_this select 0); (_d getVariable "Waldo_WmpHud_DisplayCombo") lbSetCurSel 0; (_d getVariable "Waldo_WmpHud_ScaleCombo") lbSetCurSel 1; (_d getVariable "Waldo_WmpHud_OpacityCombo") lbSetCurSel 1;}];
_cancel ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this select 0)) closeDisplay 2;}];
_apply ctrlAddEventHandler ["ButtonClick", {private _d = ctrlParent (_this select 0); private _show = _d getVariable "Waldo_WmpHud_DisplayCombo"; private _scale = _d getVariable "Waldo_WmpHud_ScaleCombo"; private _opacity = _d getVariable "Waldo_WmpHud_OpacityCombo"; private _mode = _show lbData (lbCurSel _show); private _values = [_mode in ["BOTH", "ICONS"], _mode in ["BOTH", "NAMES"], _scale lbData (lbCurSel _scale), _opacity lbData (lbCurSel _opacity), true]; _d closeDisplay 1; _values call Waldo_fnc_WmpHudSettingsApplyLocal;}];
[_display, true] call Waldo_fnc_UiThemeApplyDisplayLocal;
_display
