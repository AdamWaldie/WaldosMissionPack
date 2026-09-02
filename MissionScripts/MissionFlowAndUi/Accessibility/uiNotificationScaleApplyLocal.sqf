/*
 * Author: WaldoTheWarfighter
 * Applies and profile-persists one personal WMP notification size. The choice is local to the
 * interface client, survives reconnects and immediately resizes every visible notification card;
 * it never changes mission authority, notification content, placement or JIP state.
 *
 * Arguments:
 * 0: size id <STRING> SMALL | MEDIUM | LARGE (default MEDIUM)
 * 1: show a confirmation notification <BOOL> (default true)
 *
 * Return Value: BOOL - true when a supported size was applied.
 * Current callers: compatibility scripts; the custom Notification UI screen uses the combined
 * settings apply function.
 * Example: ["SMALL", true] call Waldo_fnc_UiNotificationScaleApplyLocal;
 */

if (!hasInterface) exitWith {false};
params [["_sizeId", "MEDIUM", [""]], ["_preview", true, [true]]];
_sizeId = toUpperANSI _sizeId;
if !(_sizeId in ["SMALL", "MEDIUM", "LARGE"]) exitWith {false};

profileNamespace setVariable ["Waldo_UI_NotificationScale", _sizeId];
saveProfileNamespace;
missionNamespace setVariable ["Waldo_UI_NotificationScaleLocal", _sizeId];
[] call Waldo_fnc_RestyleUiNotificationsLocal;

if (_preview) then {
    private _label = switch (_sizeId) do {
        case "SMALL": {"Small"};
        case "LARGE": {"Large"};
        default {"Medium (default)"};
    };
    [
        "NOTIFICATION SIZE",
        format ["%1 notifications are now active for this player.", _label],
        "INFO",
        6,
        "TOP_RIGHT",
        "UI_NOTIFICATION_SCALE",
        "WMP UI OPTIONS",
        "REPLACE"
    ] call Waldo_fnc_ShowUiNotification;
};
true
