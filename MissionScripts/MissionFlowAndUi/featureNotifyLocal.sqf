/* Shared adapter for gameplay systems that need the pack notification presentation. */
params [
    ["_title", "NOTICE", [""]], ["_message", "", [""]],
    ["_state", "INFO", [""]], ["_channel", "MISSION", [""]],
    ["_duration", 7, [0]]
];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {_message == ""}) exitWith {false};
[_title, _message, _state, _duration, "TOP_RIGHT", _channel] call Waldo_fnc_ShowUiNotification;
true
