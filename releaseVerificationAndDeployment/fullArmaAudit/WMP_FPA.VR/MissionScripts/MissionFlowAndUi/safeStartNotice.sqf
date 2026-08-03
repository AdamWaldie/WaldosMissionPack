/*
 * Author: WaldoTheWarfighter
 * Shows a transient SafeStart transition notice without using Arma's shared
 * hint channel. A token prevents an older timer from hiding a newer notice.
 *
 * Arguments: 0: structured content <STRING>; 1: duration seconds <NUMBER>.
 * Return Value: BOOL - true when the notice was shown or queued for startup completion.
 *
 * Example: ["SafeStart active", 8] call Waldo_fnc_SafeStartNotice;
 * Current caller: SafeStartApply when protection changes state.
 */
if (!hasInterface) exitWith {false};
params [
    ["_content", ""],
    ["_duration", 12, [0]]
];

// Keep only the latest requested transition while the title presentation owns the screen.
// SafeStart protection and its server timer are already active during this wait.
if !(missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]) exitWith {
    private _pendingToken = format ["pending_%1_%2", diag_tickTime, random 1e9];
    uiNamespace setVariable ["Waldo_SafeStart_PendingNoticeToken", _pendingToken];
    [_content, _duration, _pendingToken] spawn {
        params ["_content", "_duration", "_pendingToken"];
        waitUntil {
            uiSleep 0.1;
            missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]
            || {(uiNamespace getVariable ["Waldo_SafeStart_PendingNoticeToken", ""]) != _pendingToken}
        };
        if ((uiNamespace getVariable ["Waldo_SafeStart_PendingNoticeToken", ""]) == _pendingToken) then {
            uiNamespace setVariable ["Waldo_SafeStart_PendingNoticeToken", nil];
            [_content, _duration] call Waldo_fnc_SafeStartNotice;
        };
    };
    true
};

private _display = findDisplay 46;
if (isNull _display) exitWith {false};
private _theme = [] call Waldo_fnc_UiTheme;

// Persistent status and transitions deliberately share one screen region. A new state replaces
// the previous state instead of stacking another panel underneath it.
private _legacyNotice = _display displayCtrl 5301;
if !(isNull _legacyNotice) then {_legacyNotice ctrlShow false;};
private _frame = _display displayCtrl 5299;
private _control = _display displayCtrl 5300;
if (isNull _frame) then {
    _frame = _display ctrlCreate ["RscText", 5299];
    _frame ctrlCommit 0;
};
_frame ctrlSetBackgroundColor (_theme getOrDefault ["header", [0.015, 0.11, 0.075, 0.94]]);
if (isNull _control) then {
    _control = _display ctrlCreate ["RscStructuredText", 5300];
    _control ctrlSetBackgroundColor [0, 0, 0, 0];
    _control ctrlCommit 0;
};

private _token = format ["%1_%2", diag_tickTime, random 1e9];
uiNamespace setVariable ["Waldo_SafeStart_NoticeToken", _token];
_control ctrlSetStructuredText (if (typeName _content == "TEXT") then {_content} else {parseText _content});
private _panelW = safeZoneW * 0.48;
private _padX = _panelW * 0.035;
private _padY = safeZoneH * 0.012;
private _panelX = safeZoneX + ((safeZoneW - _panelW) / 2);
private _panelY = safeZoneY + (safeZoneH * 0.045);
private _maximumContentH = safeZoneH * 0.32;
_control ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _maximumContentH];
_control ctrlCommit 0;
private _contentH = (((ctrlTextHeight _control) + (safeZoneH * 0.008)) max (safeZoneH * 0.08)) min _maximumContentH;
private _panelH = _contentH + (2 * _padY);
_frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_control ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _contentH];
_frame ctrlCommit 0;
_control ctrlCommit 0;
["SAFESTART_STATUS", [_frame, _control], ["TOP", "TOP_RIGHT"], true] call Waldo_fnc_RegisterUiReservationLocal;

[_frame, _control, _token, _duration max 1] spawn {
    params ["_frame", "_control", "_token", "_duration"];
    uiSleep _duration;
    if ((uiNamespace getVariable ["Waldo_SafeStart_NoticeToken", ""]) isEqualTo _token) then {
        uiNamespace setVariable ["Waldo_SafeStart_NoticeToken", nil];
        if (!isNull _control && {!(missionNamespace getVariable ["Waldo_SafeStart_Active", false])}) then {
            _control ctrlShow false;
            if (!isNull _frame) then {_frame ctrlShow false;};
            ["SAFESTART_STATUS", [_frame, _control], ["TOP", "TOP_RIGHT"], false] call Waldo_fnc_RegisterUiReservationLocal;
        };
    };
};
true
