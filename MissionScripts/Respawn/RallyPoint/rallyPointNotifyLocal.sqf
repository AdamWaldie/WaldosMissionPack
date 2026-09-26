/*
 * Author: WaldoTheWarfighter
 * Shows squad-rally status through WMP's notification UI on the receiving client.
 * Locality and authority: Interface-client only; rejects remote senders other than the server.
 * The server decides which rally operation and message to report.
 * Repeat/JIP: Each call displays one notification; it has no persistent JIP state or handler.
 * Arguments:
 * 0: message <STRING> (default "")
 * 1: notification state <STRING> (default "INFO")
 * Return Value: <BOOL> - true when a non-empty message was sent to the UI.
 * Current callers: Waldo_fnc_RallyPointRequestServer and RallyPointRemoveServer.
 * Example: ["Rally point deployed.", "SUCCESS"] call Waldo_fnc_RallyPointNotifyLocal;
 * Result: The player sees a squad-rally notification in the top-right lane.
 */
params [["_message", "", [""]], ["_state", "INFO", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {_message == ""}) exitWith {false};
["SQUAD RALLY", _message, _state, 7, "TOP_RIGHT", "RALLY_POINT"] call Waldo_fnc_ShowUiNotification;
true
