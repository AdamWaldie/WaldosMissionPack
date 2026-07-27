/* Accepts a diagnostic snapshot from its owning client and stores it for the active server run. */
if (!isServer) exitWith {false};
params [
    ["_runId", "", [""]],
    ["_ownerId", -1, [0]],
    ["_playerName", "", [""]],
    ["_uid", "", [""]],
    ["_checks", [], [[]]]
];

private _sender = if (isRemoteExecuted) then {remoteExecutedOwner} else {2};
if (_runId != (missionNamespace getVariable ["Waldo_Diagnostics_ActiveRun", ""])) exitWith {
    ["clients", "report", "WARN", "REJECT", format ["reason=stale owner=%1", _ownerId], _runId, "SERVER"] call Waldo_fnc_DiagnosticLog;
    false
};
if (_sender > 2 && {_sender != _ownerId}) exitWith {
    ["clients", "report", "WARN", "REJECT", format ["reason=owner-mismatch sender=%1 claimed=%2", _sender, _ownerId], _runId, "SERVER"] call Waldo_fnc_DiagnosticLog;
    false
};
private _ownerIsPlayer = (allPlayers findIf {owner _x == _ownerId}) >= 0;
private _malformedAt = _checks findIf {
    !(_x isEqualType [])
    || {count _x < 4}
    || {!((_x select 0) isEqualType "")}
    || {!((_x select 1) isEqualType "")}
    || {!((_x select 2) isEqualType "")}
    || {!((_x select 3) isEqualType "")}
};
if (!_ownerIsPlayer || {count _checks > 128} || {_malformedAt >= 0}) exitWith {
    ["clients", "report", "WARN", "REJECT", format ["reason=malformed owner=%1 checks=%2", _ownerId, count _checks], _runId, "SERVER"] call Waldo_fnc_DiagnosticLog;
    false
};

private _reports = missionNamespace getVariable ["Waldo_Diagnostics_ClientReports", []];
private _at = _reports findIf {(_x select 0) == _ownerId};
private _row = [_ownerId, _playerName, _uid, _checks, serverTime];
if (_at < 0) then {_reports pushBack _row} else {_reports set [_at, _row]};
missionNamespace setVariable ["Waldo_Diagnostics_ClientReports", _reports];
["clients", "report", "INFO", "RECEIVED", format ["owner=%1 player=%2 checks=%3 errors=%4", _ownerId, _playerName, count _checks, {_x select 2 == "ERROR"} count _checks], _runId, "SERVER"] call Waldo_fnc_DiagnosticLog;
true
