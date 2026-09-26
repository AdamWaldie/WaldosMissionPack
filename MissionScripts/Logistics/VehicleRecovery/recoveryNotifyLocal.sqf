/*
 * Author: WaldoTheWarfighter
 * Shows a vehicle-recovery outcome through the shared WMP notification UI.
 * Locality and authority: Only a server-dispatched call on the recipient's interface client
 * can display the message. Repeated messages use the UI's normal queue/coalescing policy;
 * transient feedback is not replayed for JIP.
 * Arguments: 0: message <STRING>; 1: notification state <STRING> ("INFO").
 * Return Value: <BOOL> true when a valid message was shown; false without an interface.
 * Current callers: RecoveryRequestServer and RecoveryRestoreServer outcome paths.
 * Example: ["Vehicle packaged for recovery.", "SUCCESS"]
 *   remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner player];
 * Result: The intended player sees a top-right VEHICLE RECOVERY notification.
 */
params [["_message", "", [""]], ["_state", "INFO", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {_message == ""}) exitWith {false};
["VEHICLE RECOVERY", _message, _state, 7, "TOP_RIGHT", "VEHICLE_RECOVERY"] call Waldo_fnc_ShowUiNotification;
true
