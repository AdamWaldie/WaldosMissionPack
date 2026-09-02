/*
 * Author: WaldoTheWarfighter
 * Resolves a local notification animation duration from the player's notification and cross-UI
 * accessibility preferences. Mission timing remains the upper bound. Reduced motion shortens it;
 * disabled motion removes it. The calculation is local, stateless and repeat/JIP safe.
 *
 * Arguments:
 * 0: mission/default duration <NUMBER> (default Waldo_UiNotification_ReflowDuration)
 * Return Value: NUMBER - effective duration in seconds from 0 to 1.
 * Current callers: ReflowUiPanels and AnimateUiNotificationEntryLocal.
 * Example: [0.18] call Waldo_fnc_UiNotificationMotionDuration;
 */

params [["_duration", missionNamespace getVariable ["Waldo_UiNotification_ReflowDuration", 0.18], [0]]];
private _mode = toUpperANSI (missionNamespace getVariable ["Waldo_UI_NotificationMotionLocal", profileNamespace getVariable ["Waldo_UI_NotificationMotion", "NORMAL"]]);
if (profileNamespace getVariable ["Waldo_UI_ReducedMotion", false] && {_mode isEqualTo "NORMAL"}) then {_mode = "REDUCED";};
switch (_mode) do {
    case "OFF": {0};
    case "REDUCED": {(_duration min 0.07) max 0};
    default {(_duration max 0) min 1};
}
