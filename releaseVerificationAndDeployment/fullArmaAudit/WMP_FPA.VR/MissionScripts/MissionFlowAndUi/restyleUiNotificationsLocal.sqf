/*
 * Author: WaldoTheWarfighter
 * Restyles every currently visible WMP notification card after an era-theme or colour-vision
 * change. Raw card metadata stored in the local registry is re-rendered so fonts, copy motifs,
 * semantic colours, panel materials and rail orientation all change without replaying or extending
 * the notification. Legacy registry entries remain visible and are left untouched.
 *
 * Arguments: None.
 *
 * Return Value: NUMBER - count of active notification cards restyled.
 *
 * Example: [] call Waldo_fnc_RestyleUiNotificationsLocal;
 * Current caller: UiThemeApplyLocal after local theme resolution.
 */

if (!hasInterface) exitWith {0};
private _theme = [] call Waldo_fnc_UiNotificationTheme;
private _resolution = getResolution;
private _screenHeight = (_resolution param [1, 1080]) max 480;
private _resolutionScale = linearConversion [720, 1080, _screenHeight, 0.88, 1, true];
private _notificationScaleId = toUpperANSI (missionNamespace getVariable ["Waldo_UI_NotificationScaleLocal", profileNamespace getVariable ["Waldo_UI_NotificationScale", "MEDIUM"]]);
private _personalScale = switch (_notificationScaleId) do {case "SMALL": {0.82}; case "LARGE": {1.18}; default {1};};
private _sizeScale = 0.68 * _resolutionScale * _personalScale;
private _panelScale = 0.76 * _resolutionScale * _personalScale;
private _registry = +(uiNamespace getVariable ["Waldo_UiPanelRegistry", []]);
private _restyled = 0;
{
    private _entry = _x;
    private _controls = _entry param [1, []];
    private _metadata = _entry param [14, []];
    if (count _controls >= 4 && {count _metadata >= 4}) then {
        _controls params ["_frame", "_accent", "_trim", "_content", ["_chrome0", controlNull], ["_chrome1", controlNull], ["_chrome2", controlNull], ["_chrome3", controlNull], ["_chrome4", controlNull], ["_chrome5", controlNull]];
        _metadata params ["_title", "_message", "_state", "_source"];
        private _semantic = switch (toUpperANSI _state) do {
            case "SUCCESS": {[_theme getOrDefault ["successHex", "#6CE5A8"], _theme getOrDefault ["successSymbol", "[OK]"], _theme getOrDefault ["success", [0.18, 0.66, 0.45, 1]]]};
            case "WARNING": {[_theme getOrDefault ["warningHex", "#FFD166"], _theme getOrDefault ["warningSymbol", "[!]"], _theme getOrDefault ["warning", [0.88, 0.60, 0.12, 1]]]};
            case "ERROR": {[_theme getOrDefault ["dangerHex", "#FF6161"], _theme getOrDefault ["dangerSymbol", "[X]"], _theme getOrDefault ["danger", [0.78, 0.15, 0.20, 1]]]};
            default {[_theme getOrDefault ["accentHex", "#79C7FF"], _theme getOrDefault ["infoSymbol", "[i]"], _theme getOrDefault ["accent", [0.10, 0.38, 0.66, 1]]]};
        };
        _semantic params ["_colour", "_symbol", "_accentColour"];
        if (!isNull _frame) then {_frame ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.012, 0.020, 0.028, 0.94]]);};
        {
            _x params ["_control", "_colour"];
            if (!isNull _control) then {_control ctrlSetBackgroundColor _colour;};
        } forEach [
            [_chrome0, _theme getOrDefault ["chromePrimary", [0, 0, 0, 0]]],
            [_chrome1, _theme getOrDefault ["chromeSecondary", [0, 0, 0, 0]]],
            [_chrome2, _theme getOrDefault ["chromeTertiary", [0, 0, 0, 0]]],
            [_chrome3, _theme getOrDefault ["chromePrimary", [0, 0, 0, 0]]],
            [_chrome4, _theme getOrDefault ["chromeSecondary", [0, 0, 0, 0]]],
            [_chrome5, _theme getOrDefault ["chromeTertiary", [0, 0, 0, 0]]]
        ];
        if (!isNull _accent) then {_accent ctrlSetBackgroundColor _accentColour;};
        if (!isNull _trim) then {_trim ctrlSetBackgroundColor (_theme getOrDefault ["trim", _theme getOrDefault ["accent", [0.10, 0.38, 0.66, 1]]]);};
        if (!isNull _content) then {
            private _styledSource = (_theme getOrDefault ["sourcePrefix", ""]) + toUpperANSI _source + (_theme getOrDefault ["sourceSuffix", ""]);
            private _styledTitle = (_theme getOrDefault ["titlePrefix", ""]) + _title + (_theme getOrDefault ["titleSuffix", ""]);
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
                _styledSource, _colour, _symbol, _styledTitle, _message,
                _theme getOrDefault ["font", "RobotoCondensed"],
                _theme getOrDefault ["sourceHex", _theme getOrDefault ["mutedHex", "#9FB3C8"]],
                _theme getOrDefault ["fontBold", "RobotoCondensedBold"],
                _theme getOrDefault ["textHex", "#FFFFFF"],
                _theme getOrDefault ["motif", "TACTICAL INTERFACE"],
                _sourceSize * _sizeScale, _titleSize * _sizeScale, _messageSize * _sizeScale, _copyAlign
            ];
            _content ctrlCommit 0;
            private _placement = _entry param [3, "TOP"];
            private _layoutW = safeZoneW min (safeZoneH * 1.333333);
            private _panelWidth = (switch (_placement) do {
                case "BOTTOM_RIGHT": {_layoutW * 0.20};
                case "TOP_RIGHT": {_layoutW * 0.23};
                case "BOTTOM_LEFT": {_layoutW * 0.28};
                case "BOTTOM_CENTER": {_layoutW * 0.26};
                case "CENTER": {_layoutW * 0.38};
                default {_layoutW * 0.40};
            }) * _panelScale;
            private _padX = _layoutW * 0.008 * _resolutionScale * _personalScale;
            private _padY = safeZoneH * 0.006 * _resolutionScale * _personalScale;
            private _maximumContentHeight = safeZoneH * 0.18 * _sizeScale;
            private _contentWidthFactor = if ((toUpperANSI (_theme getOrDefault ["chromeMode", "STANDARD"])) isEqualTo "STANDARD") then {1} else {0.88};
            _content ctrlSetPosition [0, 0, (_panelWidth * _contentWidthFactor) - (2 * _padX), _maximumContentHeight];
            _content ctrlCommit 0;
            private _textHeight = ctrlTextHeight _content;
            private _textGutter = ((_textHeight * 0.08) max (safeZoneH * 0.004 * _sizeScale)) min (safeZoneH * 0.012 * _sizeScale);
            private _contentHeight = ((_textHeight + _textGutter) max (safeZoneH * 0.050 * _sizeScale)) min _maximumContentHeight;
            private _materialPadY = if ((toUpperANSI (_theme getOrDefault ["chromeMode", "STANDARD"])) isEqualTo "STANDARD") then {0} else {safeZoneH * 0.012 * _sizeScale};
            _entry set [4, _panelWidth];
            _entry set [6, _padX];
            _entry set [7, _padY];
            _entry set [8, (safeZoneH * 0.003 * _resolutionScale * _personalScale) max 0.0015];
            _entry set [9, _contentHeight];
            _entry set [5, _contentHeight + (2 * _padY) + _materialPadY + _textGutter];
            _entry set [16, _textGutter];
        };
        _entry set [12, _theme getOrDefault ["railMode", "TOP"]];
        _entry set [15, _theme getOrDefault ["chromeMode", "STANDARD"]];
        _registry set [_forEachIndex, _entry];
        _restyled = _restyled + 1;
    };
} forEach _registry;
uiNamespace setVariable ["Waldo_UiPanelRegistry", _registry];
if (_restyled > 0) then {[0] call Waldo_fnc_ReflowUiPanels;};
_restyled
