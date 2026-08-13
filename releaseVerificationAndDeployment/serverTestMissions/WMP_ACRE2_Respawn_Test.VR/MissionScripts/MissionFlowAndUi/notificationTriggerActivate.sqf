/*
 * Author: WaldoTheWarfighter
 * Sends the notification stored on a WMP notification trigger when that server-local trigger
 * activates. This is an internal server helper: mission makers call Waldo_fnc_NotificationTrigger
 * instead. It performs no interface work on the server; Waldo_fnc_SendNotification resolves the
 * configured audience and delivers the card to each current player owner. Notifications are
 * transient and are not replayed to JIP players.
 *
 * Locality and repeat/JIP behaviour:
 * Runs only on the server because the owning trigger is server-local. Each trigger activation sends
 * exactly one notification. Repeatability is controlled by the trigger created by
 * Waldo_fnc_NotificationTrigger; no state is broadcast for JIP.
 *
 * Arguments:
 * 0: trigger <OBJECT> - server-local trigger containing Waldo_NotificationTrigger_Arguments.
 *
 * Return Value:
 * Number - players reached, or 0 when the trigger/configuration is invalid.
 *
 * Current callers:
 * The activation statement installed by Waldo_fnc_NotificationTrigger.
 *
 * Example:
 * [thisTrigger] call Waldo_fnc_NotificationTriggerActivate;
 */
params [["_trigger", objNull, [objNull]]];
if (!isServer || {isNull _trigger}) exitWith {0};

private _arguments = _trigger getVariable ["Waldo_NotificationTrigger_Arguments", []];
if !(_arguments isEqualType [] && {count _arguments >= 3}) exitWith {0};
_arguments call Waldo_fnc_SendNotification
