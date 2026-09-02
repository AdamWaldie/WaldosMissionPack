/*
 * Author: WaldoTheWarfighter
 * Opens the local Notification UI Settings screen with separate theme, size and motion controls and
 * a live, bounded preview. Apply validates and persists player presentation; Cancel changes nothing;
 * Restore Defaults only resets the pending controls. Mission custom themes and theme-token overrides
 * are displayed through UiTheme and remain authoritative. The display is local, repeat-safe and has
 * no network/JIP side effects.
 *
 * Arguments: None.
 * Return Value: DISPLAY - created settings display, or displayNull without a gameplay display.
 * Current caller: WMP Options self-interaction and QA capture.
 * Example: [] call Waldo_fnc_UiNotificationSettingsOpenLocal;
 */

disableSerialization;
if (!hasInterface) exitWith {displayNull};
private _parent = findDisplay 46;
if (isNull _parent) exitWith {displayNull};
private _display = _parent createDisplay "RscDisplayEmpty";
_display setVariable ["Waldo_UI_ThemedDisplay", true];
private _shell = [] call Waldo_fnc_UiTheme;
private _w = safeZoneW min (safeZoneH * 1.333333);
private _panelW = _w * 0.62;
private _panelH = safeZoneH * 0.68;
private _panelX = safeZoneX + ((safeZoneW - _panelW) / 2);
private _panelY = safeZoneY + ((safeZoneH - _panelH) / 2);
private _back = _display ctrlCreate ["RscText", -1];
_back ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_back ctrlSetBackgroundColor (_shell getOrDefault ["panel", [0.01, 0.02, 0.03, 0.98]]);
_back ctrlCommit 0;
private _header = _display ctrlCreate ["RscStructuredText", -1];
_header ctrlSetPosition [_panelX + _panelW * 0.045, _panelY + _panelH * 0.04, _panelW * 0.91, _panelH * 0.13];
_header ctrlSetStructuredText parseText format ["<t font='%1' size='1.25' color='%2'>NOTIFICATION UI SETTINGS</t><br/><t font='%3' size='0.82' color='%4'>Personal presentation only. Mission theme overrides and notification content remain unchanged.</t>", _shell getOrDefault ["fontBold", "RobotoCondensedBold"], _shell getOrDefault ["accentHex", "#79C7FF"], _shell getOrDefault ["font", "RobotoCondensed"], _shell getOrDefault ["mutedHex", "#9FB3C8"]];
_header ctrlCommit 0;
private _makeLabel = {
    params ["_text", "_y"];
    private _control = _display ctrlCreate ["RscText", -1];
    _control ctrlSetPosition [_panelX + _panelW * 0.055, _y, _panelW * 0.26, _panelH * 0.06];
    _control ctrlSetText _text;
    _control ctrlSetTextColor (_shell getOrDefault ["text", [1,1,1,1]]);
    _control ctrlSetFont (_shell getOrDefault ["fontBold", "RobotoCondensedBold"]);
    _control ctrlCommit 0;
};
private _makeCombo = {
    params ["_y"];
    private _control = _display ctrlCreate ["RscCombo", -1];
    _control ctrlSetPosition [_panelX + _panelW * 0.32, _y + _panelH * 0.006, _panelW * 0.61, _panelH * 0.052];
    _control ctrlSetFont (_shell getOrDefault ["font", "RobotoCondensed"]);
    _control ctrlSetBackgroundColor (_shell getOrDefault ["list", [0.02,0.04,0.05,1]]);
    _control ctrlCommit 0;
    _control
};
private _themeY = _panelY + _panelH * 0.19;
["Notification theme", _themeY] call _makeLabel;
private _themeCombo = [_themeY] call _makeCombo;
private _themeIds = ["FOLLOW_MISSION", "DEFAULT", "WW2", "VIETNAM", "SCIFI", "PARCHMENT", "MINIMAL", "NAVAL", "DESERT_STORM", "INDUSTRIAL", "EASTERN_BLOC", "INTELLIGENCE", "GRIMDARK", "ATOMIC_AGE", "WASTELAND", "PMC", "RETRO_COMMAND", "DIESELPUNK", "MERCENARY", "PROPAGANDA", "EMERGENCY"];
private _custom = missionNamespace getVariable ["Waldo_UI_CustomThemes", createHashMap];
if (typeName _custom == "HASHMAP") then {{_themeIds pushBackUnique (toUpperANSI _x)} forEach keys _custom;};
private _currentTheme = toUpperANSI (missionNamespace getVariable ["Waldo_UI_NotificationThemeLocal", profileNamespace getVariable ["Waldo_UI_NotificationTheme", "FOLLOW_MISSION"]]);
private _themeSelection = 0;
{
    private _resolved = if (_x isEqualTo "FOLLOW_MISSION") then {[] call Waldo_fnc_UiTheme} else {[_x] call Waldo_fnc_UiTheme};
    private _label = if (_x isEqualTo "FOLLOW_MISSION") then {format ["Follow Mission (%1)", _resolved getOrDefault ["label", "Default"]]} else {_resolved getOrDefault ["label", _x]};
    private _index = _themeCombo lbAdd _label;
    _themeCombo lbSetData [_index, _x];
    if (_x isEqualTo _currentTheme) then {_themeSelection = _index;};
} forEach _themeIds;
_themeCombo lbSetCurSel _themeSelection;
private _sizeY = _panelY + _panelH * 0.285;
["Card size", _sizeY] call _makeLabel;
private _sizeCombo = [_sizeY] call _makeCombo;
private _currentSize = toUpperANSI (missionNamespace getVariable ["Waldo_UI_NotificationScaleLocal", profileNamespace getVariable ["Waldo_UI_NotificationScale", "MEDIUM"]]);
{private _i = _sizeCombo lbAdd (_x select 1); _sizeCombo lbSetData [_i, _x select 0]; if ((_x select 0) isEqualTo _currentSize) then {_sizeCombo lbSetCurSel _i;};} forEach [["SMALL", "Small"], ["MEDIUM", "Medium (Default)"], ["LARGE", "Large"]];
private _motionY = _panelY + _panelH * 0.38;
["Entry motion", _motionY] call _makeLabel;
private _motionCombo = [_motionY] call _makeCombo;
private _currentMotion = toUpperANSI (missionNamespace getVariable ["Waldo_UI_NotificationMotionLocal", profileNamespace getVariable ["Waldo_UI_NotificationMotion", "NORMAL"]]);
{private _i = _motionCombo lbAdd (_x select 1); _motionCombo lbSetData [_i, _x select 0]; if ((_x select 0) isEqualTo _currentMotion) then {_motionCombo lbSetCurSel _i;};} forEach [["NORMAL", "Normal"], ["REDUCED", "Reduced"], ["OFF", "Off"]];
private _previewBack = _display ctrlCreate ["RscText", -1];
private _preview = _display ctrlCreate ["RscStructuredText", -1];
_previewBack ctrlSetPosition [_panelX + _panelW * 0.055, _panelY + _panelH * 0.49, _panelW * 0.89, _panelH * 0.20];
_preview ctrlSetPosition [_panelX + _panelW * 0.085, _panelY + _panelH * 0.515, _panelW * 0.83, _panelH * 0.15];
_previewBack ctrlCommit 0;
_preview ctrlCommit 0;
_display setVariable ["Waldo_UI_NotificationThemeCombo", _themeCombo];
_display setVariable ["Waldo_UI_NotificationSizeCombo", _sizeCombo];
_display setVariable ["Waldo_UI_NotificationMotionCombo", _motionCombo];
_display setVariable ["Waldo_UI_NotificationPreviewBack", _previewBack];
_display setVariable ["Waldo_UI_NotificationPreview", _preview];
private _refresh = {
    params ["_control"];
    private _d = ctrlParent _control;
    private _combo = _d getVariable ["Waldo_UI_NotificationThemeCombo", controlNull];
    private _id = _combo lbData (lbCurSel _combo);
    private _theme = if (_id isEqualTo "FOLLOW_MISSION") then {[] call Waldo_fnc_UiTheme} else {[_id] call Waldo_fnc_UiTheme};
    private _back = _d getVariable ["Waldo_UI_NotificationPreviewBack", controlNull];
    private _preview = _d getVariable ["Waldo_UI_NotificationPreview", controlNull];
    _back ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.01,0.02,0.03,0.98]]);
    _preview ctrlSetStructuredText parseText format ["<t font='%1' size='0.72' color='%2'>%3WMP OPTIONS%4 // %5</t><br/><t font='%6' size='1.05' color='%7'>%8PREVIEW MESSAGE%9</t><br/><t font='%1' size='0.82' color='%10'>This is how notification copy and material colours will read.</t>", _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["sourceHex", _theme getOrDefault ["mutedHex", "#9FB3C8"]], _theme getOrDefault ["sourcePrefix", ""], _theme getOrDefault ["sourceSuffix", ""], _theme getOrDefault ["motif", "TACTICAL INTERFACE"], _theme getOrDefault ["fontBold", "RobotoCondensedBold"], _theme getOrDefault ["accentHex", "#79C7FF"], _theme getOrDefault ["titlePrefix", ""], _theme getOrDefault ["titleSuffix", ""], _theme getOrDefault ["textHex", "#FFFFFF"]];
    _preview ctrlCommit 0;
};
_themeCombo ctrlAddEventHandler ["LBSelChanged", {_this call ((ctrlParent (_this select 0)) getVariable "Waldo_UI_NotificationRefresh");}];
_display setVariable ["Waldo_UI_NotificationRefresh", _refresh];
[_themeCombo] call _refresh;
private _buttonY = _panelY + _panelH * 0.80;
private _makeButton = {
    params ["_x", "_width", "_text"];
    private _button = _display ctrlCreate ["RscButton", -1];
    _button ctrlSetPosition [_x, _buttonY, _width, _panelH * 0.075];
    _button ctrlSetText _text;
    _button ctrlSetBackgroundColor (_shell getOrDefault ["button", [0.04,0.14,0.23,1]]);
    _button ctrlSetActiveColor (_shell getOrDefault ["buttonActive", [0.08,0.45,0.75,1]]);
    _button ctrlCommit 0;
    _button
};
private _defaults = [_panelX + _panelW * 0.055, _panelW * 0.29, "RESTORE DEFAULTS"] call _makeButton;
private _cancel = [_panelX + _panelW * 0.49, _panelW * 0.20, "CANCEL"] call _makeButton;
private _apply = [_panelX + _panelW * 0.71, _panelW * 0.235, "APPLY"] call _makeButton;
_defaults ctrlAddEventHandler ["ButtonClick", {private _d = ctrlParent (_this select 0); (_d getVariable "Waldo_UI_NotificationThemeCombo") lbSetCurSel 0; (_d getVariable "Waldo_UI_NotificationSizeCombo") lbSetCurSel 1; (_d getVariable "Waldo_UI_NotificationMotionCombo") lbSetCurSel 0;}];
_cancel ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this select 0)) closeDisplay 2;}];
_apply ctrlAddEventHandler ["ButtonClick", {private _d = ctrlParent (_this select 0); private _t = _d getVariable "Waldo_UI_NotificationThemeCombo"; private _s = _d getVariable "Waldo_UI_NotificationSizeCombo"; private _m = _d getVariable "Waldo_UI_NotificationMotionCombo"; private _values = [_t lbData (lbCurSel _t), _s lbData (lbCurSel _s), _m lbData (lbCurSel _m), true]; _d closeDisplay 1; _values call Waldo_fnc_UiNotificationSettingsApplyLocal;}];
[_display, true] call Waldo_fnc_UiThemeApplyDisplayLocal;
[_themeCombo] call _refresh;
_display
