/*
 * Author: WaldoTheWarfighter
 * Applies one validated server-side gunship state transition, publishes the current state for JIP,
 * releases invalid weapon control and sends optional feedback to the assigned controller and/or
 * explicitly addressed players on the configured operational side. Repeating the same state with
 * no message is a no-op.
 * Locality and authority: server-only registry mutation. UI feedback runs only on each intended
 * player's interface owner; state callbacks run once on the server.
 *
 * Arguments:
 * 0: system id <STRING>
 * 1: new status <STRING>
 * 2: optional player-facing message <STRING> (default generated from callsign/status)
 *
 * Return Value: BOOL - true when a valid system was accepted.
 * Current callers: gunship server controller, orbit and service state machines.
 * Example: ["spectre_1", "ON_STATION", "Spectre is ready."] call Waldo_fnc_GunshipSetState;
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
// Once back on station there is nothing left to explain to Waldo_fnc_GunshipStatusHud - clear the
// stale reason rather than leave a REQUEST/AUTO/RETASK tag from the previous cycle sitting unread.
if (_status in ["ON_STATION", "CONTROLLED"]) then {
    _state set ["offStationReason", ""];
};
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
    private _sideRecipientOwners = (allPlayers select {
        side group _x == (_config getOrDefault ["side", west])
        && {isNull _controller || {_x != _controller} || {!(_config getOrDefault ["notifyController", true])}}
    }) apply {owner _x};
    _sideRecipientOwners = _sideRecipientOwners arrayIntersect _sideRecipientOwners;
    {
        ["AIRBORNE GUNSHIP", _message, "INFO", "AIRBORNE_GUNSHIP"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _x];
    } forEach _sideRecipientOwners;
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
