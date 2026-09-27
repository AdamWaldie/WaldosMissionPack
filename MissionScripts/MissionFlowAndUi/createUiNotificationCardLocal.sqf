/*
 * Author: WaldoTheWarfighter
 * Builds the actual notification controls, typography and measured dimensions for live cards and previews.
 * Locality/authority: Interface client only; no network or JIP state is changed.
 * Repeat behaviour: Caller owns controls and deletes them before replacing a preview.
 * Arguments: 0: display <DISPLAY>; 1: resolved theme <HASHMAP>; 2: metadata [title, message, state, source] <ARRAY>; 3: placement <STRING> (TOP_RIGHT); 4: size <STRING> (MEDIUM).
 * Return Value: ARRAY - unregistered card entry, or [] without a display.
 * Current callers: ShowUiNotification and notification settings.
 * Example: [_display, _theme, ["NOTICE", "Ready.", "INFO", "WMP"], "TOP_RIGHT", "MEDIUM"] call Waldo_fnc_CreateUiNotificationCardLocal;
 */
disableSerialization;
params ["_display", "_theme", "_metadata", ["_placement", "TOP_RIGHT"], ["_notificationScaleId", "MEDIUM"]];
if (isNull _display) exitWith {[]};
_metadata params ["_title", "_messageText", "_state", "_source"];
_state = toUpperANSI _state;
private _channel = "";
private _priority = 0;
private _resolution = getResolution;
private _screenHeight = (_resolution param [1, 1080]) max 480;
// Arma's safe-zone coordinates handle UI scaling, while this final bounded factor protects short
// displays where a three-card stack otherwise consumes most of the available vertical space.
private _resolutionScale = linearConversion [720, 1080, _screenHeight, 0.88, 1, true];
_notificationScaleId = toUpperANSI _notificationScaleId;
private _personalScale = switch (_notificationScaleId) do {case "SMALL": {0.82}; case "LARGE": {1.18}; default {1};};
private _sizeScale = 0.68 * _resolutionScale * _personalScale;
private _panelScale = 0.76 * _resolutionScale * _personalScale;
// Full themes share one medium footprint. Per-theme width multipliers compounded with font and
// chrome reductions and made nominally equivalent cards visibly inconsistent. Theme identity now
// comes from construction, material, typography and alignment rather than overall size.
private _widthScale = 1;
private _semantic = switch (_state) do {
    case "SUCCESS": {[_theme getOrDefault ["successHex", "#6CE5A8"], _theme getOrDefault ["successSymbol", "[OK]"], _theme getOrDefault ["success", [0.18, 0.66, 0.45, 1]]]};
    case "WARNING": {[_theme getOrDefault ["warningHex", "#FFD166"], _theme getOrDefault ["warningSymbol", "[!]"], _theme getOrDefault ["warning", [0.88, 0.60, 0.12, 1]]]};
    case "ERROR": {[_theme getOrDefault ["dangerHex", "#FF6161"], _theme getOrDefault ["dangerSymbol", "[X]"], _theme getOrDefault ["danger", [0.78, 0.15, 0.20, 1]]]};
    default {[_theme getOrDefault ["accentHex", "#79C7FF"], _theme getOrDefault ["infoSymbol", "[i]"], _theme getOrDefault ["accent", [0.10, 0.38, 0.66, 1]]]};
};
_semantic params ["_colour", "_symbol", "_accentColour"];

private _frame = _display ctrlCreate ["RscText", -1];
private _chrome0 = _display ctrlCreate ["RscText", -1];
private _chrome1 = _display ctrlCreate ["RscText", -1];
private _chrome2 = _display ctrlCreate ["RscText", -1];
private _chrome3 = _display ctrlCreate ["RscText", -1];
private _chrome4 = _display ctrlCreate ["RscText", -1];
private _chrome5 = _display ctrlCreate ["RscText", -1];
private _accent = _display ctrlCreate ["RscText", -1];
private _trim = _display ctrlCreate ["RscText", -1];
private _content = _display ctrlCreate ["RscStructuredText", -1];
_frame ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.012, 0.020, 0.028, 0.94]]);
{
    _x params ["_control", "_colour"];
    _control ctrlSetBackgroundColor _colour;
    _control ctrlShow false;
} forEach [
    [_chrome0, _theme getOrDefault ["chromePrimary", [0, 0, 0, 0]]],
    [_chrome1, _theme getOrDefault ["chromeSecondary", [0, 0, 0, 0]]],
    [_chrome2, _theme getOrDefault ["chromeTertiary", [0, 0, 0, 0]]],
    [_chrome3, _theme getOrDefault ["chromePrimary", [0, 0, 0, 0]]],
    [_chrome4, _theme getOrDefault ["chromeSecondary", [0, 0, 0, 0]]],
    [_chrome5, _theme getOrDefault ["chromeTertiary", [0, 0, 0, 0]]]
];
_accent ctrlSetBackgroundColor _accentColour;
_trim ctrlSetBackgroundColor (_theme getOrDefault ["trim", _theme getOrDefault ["accent", [0.10, 0.38, 0.66, 1]]]);
_content ctrlSetBackgroundColor [0, 0, 0, 0];

private _styledSource = (_theme getOrDefault ["sourcePrefix", ""]) + toUpper _source + (_theme getOrDefault ["sourceSuffix", ""]);
private _styledTitle = (_theme getOrDefault ["titlePrefix", ""]) + _title + (_theme getOrDefault ["titleSuffix", ""]);
private _chromeMode = _theme getOrDefault ["chromeMode", "STANDARD"];
private _copyMode = toUpperANSI (_theme getOrDefault ["copyMode", "STANDARD"]);
private _copyProfile = switch (_copyMode) do {
    case "HERALDIC": {["center", 0.64, 1.16, 0.86]};
    case "BROADCAST": {["center", 0.64, 1.16, 0.86]};
    default {["left", 0.64, 1.16, 0.86]};
};
_copyProfile params ["_copyAlign", "_sourceSize", "_titleSize", "_messageSize"];
_content ctrlSetStructuredText parseText format [
    "<t align='%14' font='%6' color='%7' size='%11' shadow='0'>%1 // %10</t><br/>" +
    "<t align='%14' font='%8' color='%2' size='%12' shadow='0'>%3 %4</t><br/>" +
    "<t align='%14' font='%6' color='%9' size='%13' shadow='0'>%5</t>",
    _styledSource,
    _colour,
    _symbol,
    _styledTitle,
    _messageText,
    _theme getOrDefault ["font", "RobotoCondensed"],
    _theme getOrDefault ["sourceHex", _theme getOrDefault ["mutedHex", "#9FB3C8"]],
    _theme getOrDefault ["fontBold", "RobotoCondensedBold"],
    _theme getOrDefault ["textHex", "#FFFFFF"],
    _theme getOrDefault ["motif", "TACTICAL INTERFACE"],
    _sourceSize * _sizeScale,
    _titleSize * _sizeScale,
    _messageSize * _sizeScale,
    _copyAlign
];

private _visibleW = safeZoneW;
private _visibleH = safeZoneH;
// Cap the horizontal layout canvas at a 16:9 safe-zone shape. Cards therefore remain readable on
// ultrawide displays instead of stretching with the whole desktop, while 4:3 and 16:10 layouts can
// still use all of their narrower safe width.
private _layoutW = _visibleW min (_visibleH * 1.333333);
private _maximumPanelW = (switch (_placement) do {
    case "BOTTOM_RIGHT": {_layoutW * 0.20};
    case "TOP_RIGHT": {_layoutW * 0.23};
    case "BOTTOM_LEFT": {_layoutW * 0.28};
    case "BOTTOM_CENTER": {_layoutW * 0.26};
    case "CENTER": {_layoutW * 0.38};
    default {_layoutW * 0.40};
}) * _panelScale * _widthScale;
private _minimumPanelW = (switch (_placement) do {
    case "BOTTOM_RIGHT": {_layoutW * 0.13};
    case "TOP_RIGHT": {_layoutW * 0.15};
    case "BOTTOM_LEFT": {_layoutW * 0.18};
    case "BOTTOM_CENTER": {_layoutW * 0.17};
    case "CENTER": {_layoutW * 0.21};
    default {_layoutW * 0.23};
}) * _panelScale;
private _panelW = _maximumPanelW;
private _padX = _layoutW * 0.008 * _resolutionScale * _personalScale;
private _padY = _visibleH * 0.006 * _resolutionScale * _personalScale;
private _maximumContentH = _visibleH * 0.18 * _sizeScale;
private _contentWidthFactor = if ((toUpperANSI _chromeMode) isEqualTo "STANDARD") then {1} else {0.88};
_content ctrlSetPosition [0, 0, (_panelW * _contentWidthFactor) - (2 * _padX), _maximumContentH];
_content ctrlCommit 0;
private _measuredTextW = ctrlTextWidth _content;
if (_measuredTextW > 0) then {
    private _requiredPanelW = ((_measuredTextW + (2 * _padX) + (_layoutW * 0.012)) / _contentWidthFactor);
    _panelW = (_requiredPanelW max _minimumPanelW) min _maximumPanelW;
    _content ctrlSetPosition [0, 0, (_panelW * _contentWidthFactor) - (2 * _padX), _maximumContentH];
    _content ctrlCommit 0;
};
private _textHeight = ctrlTextHeight _content;
private _textGutter = ((_textHeight * 0.08) max (_visibleH * 0.004 * _sizeScale)) min (_visibleH * 0.012 * _sizeScale);
private _contentH = ((_textHeight + _textGutter) max (_visibleH * 0.050 * _sizeScale)) min _maximumContentH;
private _materialPadY = if ((toUpperANSI _chromeMode) isEqualTo "STANDARD") then {0} else {_visibleH * 0.012 * _sizeScale};
private _panelH = _contentH + (2 * _padY) + _materialPadY + _textGutter;
private _accentH = (_visibleH * 0.003 * _resolutionScale * _personalScale) max 0.0015;
{_x ctrlShow true;} forEach [_frame, _accent, _trim, _content];

private _token = format ["%1_%2", diag_tickTime, random 1e9];
private _controls = [_frame, _accent, _trim, _content, _chrome0, _chrome1, _chrome2, _chrome3, _chrome4, _chrome5];
private _railMode = _theme getOrDefault ["railMode", "TOP"];
private _trimH = (_visibleH * 0.002) max 0.001;
[_channel, _controls, _token, _placement, _panelW, _panelH, _padX, _padY, _accentH, _contentH, _priority, diag_tickTime, _railMode, _trimH, [_title, _messageText, _state, _source], _chromeMode, _textGutter]
