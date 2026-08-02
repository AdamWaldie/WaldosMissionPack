/*
 * Author: WaldoTheWarfighter
 * Shows an electronic-warfare transition notice in a dedicated control that
 * cannot be overwritten by Safestart, ENDEX or another use of Arma's hint UI.
 * Newer notices own the control and prevent older timers from hiding them.
 *
 * Arguments: 0: title <STRING>; 1: message <STRING>; 2: duration <NUMBER>;
 * 3: state <STRING> - WARNING, SUCCESS or INFO.
 * Return Value: BOOL - true when the local notice was drawn.
 *
 * Example: ["ELECTRONIC WARFARE", "Signal restored", 8, "SUCCESS"] call Waldo_fnc_JammingNotice;
 * Current callers: jamming client state transitions and jammer disable feedback.
 */
if (!hasInterface) exitWith {false};
params [
    ['_title', 'ELECTRONIC WARFARE', ['']],
    ['_message', '', ['']],
    ['_duration', 8, [0]],
    ['_state', 'WARNING', ['']]
];

private _display = findDisplay 46;
if (isNull _display) exitWith {false};
private _theme = [] call Waldo_fnc_UiTheme;
private _legacyNotice = _display displayCtrl 5312;
if !(isNull _legacyNotice) then {_legacyNotice ctrlShow false;};

// Radio status and radio transitions share the ELECTRONIC WARFARE panel. This prevents two
// competing jammer interfaces and makes restoration part of the same clear state model.
private _idc = 5310;
private _frame = _display displayCtrl 5309;
private _control = _display displayCtrl _idc;
if (isNull _frame) then {
    _frame = _display ctrlCreate ['RscText', 5309];
    _frame ctrlCommit 0;
};
_frame ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.015, 0.025, 0.035, 0.92]]);
if (isNull _control) then {
    _control = _display ctrlCreate ['RscStructuredText', _idc];
    _control ctrlSetBackgroundColor [0, 0, 0, 0];
    _control ctrlCommit 0;
};

private _colour = switch (toUpper _state) do {
    case 'SUCCESS': {_theme getOrDefault ['successHex', '#6CE5A8']};
    case 'INFO': {_theme getOrDefault ['accentHex', '#4FA9E8']};
    default {_theme getOrDefault ['dangerHex', '#FF6161']};
};
_control ctrlSetStructuredText parseText format [
    "<t align='left' font='%4' color='%5' size='0.72'>  ELECTRONIC WARFARE</t><br/>" +
    "<t align='left' font='%6' color='%1' size='1.12' shadow='1'>  %2</t><br/>" +
    "<t align='left' font='%4' color='%7' size='0.82'>  %3</t>",
    _colour,
    _title,
    _message,
    _theme getOrDefault ['font', 'RobotoCondensed'], _theme getOrDefault ['mutedHex', '#9FB3C8'],
    _theme getOrDefault ['fontBold', 'RobotoCondensedBold'], _theme getOrDefault ['textHex', '#FFFFFF']
];
private _visibleX = safeZoneX;
private _visibleY = safeZoneY;
private _visibleRight = safeZoneX + safeZoneW;
private _visibleBottom = safeZoneY + safeZoneH;
private _visibleW = (_visibleRight - _visibleX) max 0.2;
private _visibleH = (_visibleBottom - _visibleY) max 0.2;
private _panelW = _visibleW * 0.235;
private _padX = _visibleW * 0.008;
private _padY = _visibleH * 0.007;
private _panelX = _visibleRight - _panelW - (_visibleW * 0.012);
private _reservedRadioH = _visibleH * 0.175;
_control ctrlSetPosition [_panelX + _padX, _visibleBottom - _reservedRadioH - (_visibleH * 0.105), _panelW - (2 * _padX), _visibleH * 0.10];
_control ctrlCommit 0;
private _contentH = ((ctrlTextHeight _control) max (_visibleH * 0.065)) min (_visibleH * 0.10);
private _panelH = _contentH + (2 * _padY);
private _panelY = _visibleBottom - _reservedRadioH - _panelH - (_visibleH * 0.012);
_frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_control ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _contentH];
_frame ctrlCommit 0;
_control ctrlCommit 0;
_frame ctrlShow true;
_control ctrlShow true;

private _token = format ['%1_%2', diag_tickTime, random 1e9];
uiNamespace setVariable ['Waldo_JammingNoticeToken', _token];
[_frame, _control, _token, 1 max _duration] spawn {
    params ['_frame', '_control', '_token', '_duration'];
    uiSleep _duration;
    if ((uiNamespace getVariable ['Waldo_JammingNoticeToken', '']) isEqualTo _token) then {
        uiNamespace setVariable ['Waldo_JammingNoticeToken', nil];
        if (!isNull _control) then {
            private _factor = if (alive player) then {[getPosASL player, side player, -1] call Waldo_fnc_JammingFactor} else {0};
            if (_factor > 0) then {
                [_factor] call Waldo_fnc_JammingHud;
            } else {
                _control ctrlShow false;
                if (!isNull _frame) then {_frame ctrlShow false;};
            };
        };
    };
};
true
