/* Displays group-rally feedback on the receiving interface. */
params [["_message", "", [""]], ["_state", "INFO", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {_message == ""}) exitWith {false};
["SQUAD RALLY", _message, _state, 7, "TOP_RIGHT", "RALLY_POINT"] call Waldo_fnc_ShowUiNotification;
true
