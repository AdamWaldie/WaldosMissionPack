/* Displays vehicle-recovery feedback on the receiving interface. */
params [["_message", "", [""]], ["_state", "INFO", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {_message == ""}) exitWith {false};
["VEHICLE RECOVERY", _message, _state, 7, "TOP_RIGHT", "VEHICLE_RECOVERY"] call Waldo_fnc_ShowUiNotification;
true
