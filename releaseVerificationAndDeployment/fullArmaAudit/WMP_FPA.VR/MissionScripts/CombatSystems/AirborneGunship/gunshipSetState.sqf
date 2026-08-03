/*
 * Author: WaldoTheWarfighter
 * Applies one validated server-side gunship state transition.
 * Arguments: 0: id <STRING>; 1: status <STRING>; 2: message <STRING>
 * Return Value: Boolean
 */

params ["_id", "_status", ["_message", "", [""]]];
if !(isServer) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
if !(_id in keys _registry) exitWith {false};
private _state = _registry get _id;
private _previous = _state getOrDefault ["status", "UNAVAILABLE"];
_status = toUpperANSI _status;
if (_status == _previous && {_message == ""}) exitWith {true};
_state set ["status", _status];
_state set ["statusChangedAt", diag_tickTime];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
[] call Waldo_fnc_GunshipPublishState;

private _config = _state get "config";
private _controller = _state getOrDefault ["controller", objNull];
if (_status in ["RTB", "SERVICING", "DESTROYED", "UNAVAILABLE"] && {!isNull _controller}) then {
    [_id] remoteExecCall ["Waldo_fnc_GunshipReleaseControlLocal", owner _controller];
};
if (_message == "") then {
    _message = format ["%1: %2", _config getOrDefault ["callsign", _id], _status];
};
if (!isNull _controller && {_config getOrDefault ["notifyController", true]}) then {
    [_message] remoteExecCall ["Waldo_fnc_GunshipNotifyLocal", owner _controller];
};
if (_config getOrDefault ["announceSide", false]) then {
    ["AIRBORNE GUNSHIP", _message, "INFO", "AIRBORNE_GUNSHIP"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", (_config getOrDefault ["side", west])];
};
private _callback = _config getOrDefault ["onStateChanged", {}];
if (_callback isEqualType {}) then {[_id, _previous, _status, _state] call _callback};
private _specificCallbackName = switch (_status) do {
    case "ON_STATION": {"onArrive"};
    case "RTB": {"onDepart"};
    case "SERVICING": {"onService"};
    case "DESTROYED": {"onDestroyed"};
    default {""};
};
if (_specificCallbackName != "") then {
    private _specificCallback = _config getOrDefault [_specificCallbackName, {}];
    if (_specificCallback isEqualType {}) then {[_id, _state] call _specificCallback};
};
true
