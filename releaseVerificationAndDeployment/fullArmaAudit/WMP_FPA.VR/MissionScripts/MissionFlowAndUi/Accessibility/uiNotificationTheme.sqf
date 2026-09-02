/*
 * Author: WaldoTheWarfighter
 * Resolves the current player's notification-only theme. FOLLOW_MISSION inherits the authoritative
 * mission theme; a personal built-in or mission custom id changes notification presentation only.
 * Mission theme-token overrides and the player's colour-vision profile are still applied last by
 * UiTheme. The local preference is repeat/JIP safe and cannot change content, placement or authority.
 *
 * Arguments:
 * 0: notification theme id <STRING> (default local/profile choice or FOLLOW_MISSION)
 * Return Value: HASHMAP - fully resolved notification presentation tokens.
 * Current callers: ShowUiNotification, RestyleUiNotificationsLocal and notification settings preview.
 * Example: ["GRIMDARK"] call Waldo_fnc_UiNotificationTheme;
 */

params [["_requested", missionNamespace getVariable ["Waldo_UI_NotificationThemeLocal", profileNamespace getVariable ["Waldo_UI_NotificationTheme", "FOLLOW_MISSION"]], [""]]];
private _id = toUpperANSI _requested;
if (_id isEqualTo "FOLLOW_MISSION") then {_id = missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"];};
private _resolved = [_id] call Waldo_fnc_UiTheme;
if ((_resolved getOrDefault ["id", "DEFAULT"]) != _id) then {
    _id = missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"];
    _resolved = [_id] call Waldo_fnc_UiTheme;
};
_resolved
