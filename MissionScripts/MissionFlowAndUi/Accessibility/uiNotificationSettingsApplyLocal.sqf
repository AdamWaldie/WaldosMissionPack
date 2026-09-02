/*
 * Author: WaldoTheWarfighter
 * Validates, applies and profile-persists one player's notification-only theme, size and motion.
 * Visible cards are immediately restyled and reflowed. Mission custom themes and token overrides
 * remain authoritative inputs; this local presentation function changes no notification mechanics,
 * placement, content or JIP state. Repeated calls replace the previous local preference safely.
 *
 * Arguments:
 * 0: theme id <STRING> (default FOLLOW_MISSION)
 * 1: size id <STRING> SMALL | MEDIUM | LARGE (default MEDIUM)
 * 2: motion id <STRING> NORMAL | REDUCED | OFF (default NORMAL)
 * 3: show confirmation <BOOL> (default true)
 * Return Value: BOOL - true when all choices were valid and applied.
 * Current caller: Notification UI Settings Apply button.
 * Example: ["GRIMDARK", "SMALL", "REDUCED", true] call Waldo_fnc_UiNotificationSettingsApplyLocal;
 */

if (!hasInterface) exitWith {false};
params [["_themeId", "FOLLOW_MISSION", [""]], ["_sizeId", "MEDIUM", [""]], ["_motionId", "NORMAL", [""]], ["_preview", true, [true]]];
_themeId = toUpperANSI _themeId;
_sizeId = toUpperANSI _sizeId;
_motionId = toUpperANSI _motionId;
if !(_sizeId in ["SMALL", "MEDIUM", "LARGE"] && {_motionId in ["NORMAL", "REDUCED", "OFF"]}) exitWith {false};
private _themeValid = true;
if !(_themeId isEqualTo "FOLLOW_MISSION") then {
    private _resolved = [_themeId] call Waldo_fnc_UiTheme;
    _themeValid = (_resolved getOrDefault ["id", "DEFAULT"]) isEqualTo _themeId;
};
if (!_themeValid) exitWith {false};
profileNamespace setVariable ["Waldo_UI_NotificationTheme", _themeId];
profileNamespace setVariable ["Waldo_UI_NotificationScale", _sizeId];
profileNamespace setVariable ["Waldo_UI_NotificationMotion", _motionId];
saveProfileNamespace;
missionNamespace setVariable ["Waldo_UI_NotificationThemeLocal", _themeId];
missionNamespace setVariable ["Waldo_UI_NotificationScaleLocal", _sizeId];
missionNamespace setVariable ["Waldo_UI_NotificationMotionLocal", _motionId];
[] call Waldo_fnc_RestyleUiNotificationsLocal;
if (_preview) then {
    ["NOTIFICATION UI", format ["Theme: %1 // Size: %2 // Motion: %3", _themeId, _sizeId, _motionId], "INFO", 7, "TOP_RIGHT", "UI_NOTIFICATION_SETTINGS", "WMP OPTIONS", "REPLACE"] call Waldo_fnc_ShowUiNotification;
};
true
