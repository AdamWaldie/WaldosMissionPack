/*
 * Author: WaldoTheWarfighter
 * Sends one gameplay notification through the shared WMP card presentation on the local client.
 *
 * The adapter standardises feature messages in the TOP_RIGHT stack and uses a channel key for
 * coalescing/overflow control. It rejects unauthorized remote callers and malformed payloads, logs
 * the rejected payload/remote owner, and counts malformed attempts for Mission Diagnostics. It does
 * nothing on machines without an interface. It is currently called by hazardous environments,
 * accessibility, recovery, rally points, gunship support, resupply and other gameplay systems.
 *
 * Arguments:
 * 0: title <STRING> (default: NOTICE)
 * 1: message <STRING> (default: empty)
 * 2: state <STRING> - INFO|SUCCESS|WARNING|ERROR (default: INFO)
 * 3: channel <STRING> - replacement/queue key (default: MISSION)
 * 4: duration <NUMBER> - seconds, 0 is persistent (default: 7)
 *
 * Return Value:
 * Boolean - true when a local notification was submitted
 *
 * Example:
 * ["HAZARDOUS AREA", "You have entered a hazardous zone.", "WARNING", "HAZARD_REACTOR", 6] call Waldo_fnc_FeatureNotifyLocal;
 */
private _payloadValid = _this isEqualType []
    && {count _this >= 2}
    && {(_this param [0, nil]) isEqualType ""}
    && {(_this param [1, nil]) isEqualType ""};
if (!_payloadValid) exitWith {
    private _invalidCount = (missionNamespace getVariable ["Waldo_FeatureNotify_InvalidPayloadCount", 0]) + 1;
    missionNamespace setVariable ["Waldo_FeatureNotify_InvalidPayloadCount", _invalidCount];
    diag_log format ["[WMP UI] FeatureNotifyLocal rejected malformed payload=%1 remoteOwner=%2 count=%3.", _this, remoteExecutedOwner, _invalidCount];
    false
};
params [
    ["_title", "NOTICE", [""]], ["_message", "", [""]],
    ["_state", "INFO", [""]], ["_channel", "MISSION", [""]],
    ["_duration", 7, [0]]
];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {_message == ""}) exitWith {false};
[_title, _message, _state, _duration, "TOP_RIGHT", _channel] call Waldo_fnc_ShowUiNotification;
true
