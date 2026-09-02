/*
 * Author: WaldoTheWarfighter
 * Slides one newly laid-out notification card into its stack in the lane's reading direction.
 * Top and centre lanes enter upward with the newest card below older cards. Bottom lanes enter
 * downward with the newest card above older cards. The animation is local presentation only,
 * repeat-safe for a valid token and does not change queue, channel, authority or JIP state.
 *
 * Arguments:
 * 0: notification token <STRING>
 * 1: placement <STRING>
 * 2: animation duration <NUMBER> (default Waldo_UiNotification_ReflowDuration)
 *
 * Return Value: BOOL - true when the matching live card was animated.
 * Current caller: Waldo_fnc_ShowUiNotification after its immediate geometry pass.
 * Example: [_token, "BOTTOM_RIGHT", 0.18] call Waldo_fnc_AnimateUiNotificationEntryLocal;
 */

if (!hasInterface) exitWith {false};
params [
    ["_token", "", [""]],
    ["_placement", "TOP", [""]],
    ["_duration", missionNamespace getVariable ["Waldo_UiNotification_ReflowDuration", 0.18], [0]]
];
_duration = [_duration] call Waldo_fnc_UiNotificationMotionDuration;
if (_token isEqualTo "" || {_duration <= 0} || {uiNamespace getVariable ["Waldo_UI_PanelsSuppressed", false]}) exitWith {false};

private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
private _index = _registry findIf {(_x param [2, ""]) isEqualTo _token};
if (_index < 0) exitWith {false};
private _entry = _registry select _index;
private _controls = (_entry param [1, []]) select {!isNull _x};
if (_controls isEqualTo []) exitWith {false};

private _panelH = _entry param [5, safeZoneH * 0.08];
private _bottomLane = (toUpperANSI _placement) in ["BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"];
private _offsetY = (_panelH * 0.28) * ([-1, 1] select _bottomLane);
{
    private _target = ctrlPosition _x;
    private _start = +_target;
    _start set [1, (_target select 1) - _offsetY];
    _x ctrlSetPosition _start;
    _x ctrlCommit 0;
    _x ctrlSetPosition _target;
    _x ctrlCommit _duration;
} forEach _controls;
true
