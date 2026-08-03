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
private _theme = [] call Waldo_fnc_UiTheme;
private _registry = +(uiNamespace getVariable ["Waldo_UiPanelRegistry", []]);
private _restyled = 0;
{
    private _entry = _x;
    private _controls = _entry param [1, []];
    private _metadata = _entry param [14, []];
    if (count _controls >= 4 && {count _metadata >= 4}) then {
        _controls params ["_frame", "_accent", "_trim", "_content"];
        _metadata params ["_title", "_message", "_state", "_source"];
        private _semantic = switch (toUpperANSI _state) do {
            case "SUCCESS": {[_theme getOrDefault ["successHex", "#6CE5A8"], "[OK]", _theme getOrDefault ["success", [0.18, 0.66, 0.45, 1]]]};
            case "WARNING": {[_theme getOrDefault ["warningHex", "#FFD166"], "[!]", _theme getOrDefault ["warning", [0.88, 0.60, 0.12, 1]]]};
            case "ERROR": {[_theme getOrDefault ["dangerHex", "#FF6161"], "[X]", _theme getOrDefault ["danger", [0.78, 0.15, 0.20, 1]]]};
            default {[_theme getOrDefault ["accentHex", "#79C7FF"], "[i]", _theme getOrDefault ["accent", [0.10, 0.38, 0.66, 1]]]};
        };
        _semantic params ["_colour", "_symbol", "_accentColour"];
        if (!isNull _frame) then {_frame ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.012, 0.020, 0.028, 0.94]]);};
        if (!isNull _accent) then {_accent ctrlSetBackgroundColor _accentColour;};
        if (!isNull _trim) then {_trim ctrlSetBackgroundColor (_theme getOrDefault ["trim", _theme getOrDefault ["accent", [0.10, 0.38, 0.66, 1]]]);};
        if (!isNull _content) then {
            private _styledSource = (_theme getOrDefault ["sourcePrefix", ""]) + toUpperANSI _source + (_theme getOrDefault ["sourceSuffix", ""]);
            private _styledTitle = (_theme getOrDefault ["titlePrefix", ""]) + _title + (_theme getOrDefault ["titleSuffix", ""]);
            _content ctrlSetStructuredText parseText format [
                "<t align='left' font='%6' color='%7' size='0.72'>%1 // %10</t><br/>" +
                "<t align='left' font='%8' color='%2' size='1.12' shadow='1'>%3 %4</t><br/>" +
                "<t align='left' font='%6' color='%9' size='0.88'>%5</t>",
                _styledSource, _colour, _symbol, _styledTitle, _message,
                _theme getOrDefault ["font", "RobotoCondensed"],
                _theme getOrDefault ["mutedHex", "#9FB3C8"],
                _theme getOrDefault ["fontBold", "RobotoCondensedBold"],
                _theme getOrDefault ["textHex", "#FFFFFF"],
                _theme getOrDefault ["motif", "TACTICAL INTERFACE"]
            ];
            _content ctrlCommit 0;
            private _panelWidth = _entry param [4, safeZoneW * 0.28];
            private _padX = _entry param [6, safeZoneW * 0.01];
            private _padY = _entry param [7, safeZoneH * 0.008];
            private _maximumContentHeight = safeZoneH * 0.22;
            _content ctrlSetPosition [0, 0, _panelWidth - (2 * _padX), _maximumContentHeight];
            _content ctrlCommit 0;
            private _contentHeight = (((ctrlTextHeight _content) + (safeZoneH * 0.006)) max (safeZoneH * 0.07)) min _maximumContentHeight;
            _entry set [9, _contentHeight];
            _entry set [5, _contentHeight + (2 * _padY)];
        };
        _entry set [12, _theme getOrDefault ["railMode", "TOP"]];
        _registry set [_forEachIndex, _entry];
        _restyled = _restyled + 1;
    };
} forEach _registry;
uiNamespace setVariable ["Waldo_UiPanelRegistry", _registry];
if (_restyled > 0) then {[0] call Waldo_fnc_ReflowUiPanels;};
_restyled
