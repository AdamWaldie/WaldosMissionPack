/*
 * Acquires the server-owned VVD UI lock and opens the local garage only for the
 * accepted actor. This prevents two clients from opening the same depot at once.
 */
params [
    ["_terminal", objNull, [objNull]],
    ["_spawnPoint", objNull, [objNull]],
    ["_types", [], [[]]],
    ["_sideLimit", false, [true]],
    ["_removeUAVs", false, [true]],
    ["_actor", objNull, [objNull]]
];

if (!isServer) exitWith {
    _this remoteExecCall ["Waldo_fnc_VVDRequestOpenServer", 2];
};

private _requestOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
private _validOwner = !isNull _actor && {owner _actor == _requestOwner};
private _configured = !isNull _terminal
    && {!isNull _spawnPoint}
    && {_terminal getVariable ["Waldo_VVD_TerminalConfigured", false]}
    && {(_terminal getVariable ["Waldo_VVD_SpawnPoint", objNull]) isEqualTo _spawnPoint};
private _inRange = _validOwner && {_actor distance _terminal <= ((_terminal getVariable ["Waldo_VVD_UseRange", 10]) max 1)};
if (!_validOwner || {!_configured} || {!alive _actor} || {!_inRange}) exitWith {
    diag_log format ["[WMP VVD] Open rejected actor=%1 owner=%2 validOwner=%3 configured=%4 inRange=%5", _actor, _requestOwner, _validOwner, _configured, _inRange];
};

private _nearVehicles = (ASLToAGL getPosASL _spawnPoint) nearObjects ["AllVehicles", 20];
if (_nearVehicles findIf {!(_x isKindOf "Man")} >= 0) exitWith {
    ["Vehicles occupy the depot spawn area."] remoteExecCall ["Waldo_fnc_VVDNotifyLocal", _requestOwner];
};

private _now = serverTime;
private _lockedBy = _spawnPoint getVariable ["Waldo_VVD_OpenActor", objNull];
private _lockUntil = _spawnPoint getVariable ["Waldo_VVD_OpenUntil", 0];
private _lockActive = !isNull _lockedBy && {alive _lockedBy} && {_lockUntil > _now};
if (_lockActive) exitWith {
    ["This vehicle depot is already in use."] remoteExecCall ["Waldo_fnc_VVDNotifyLocal", _requestOwner];
};

private _token = format ["VVD:%1:%2:%3", netId _spawnPoint, _requestOwner, diag_tickTime];
_spawnPoint setVariable ["Waldo_VVD_OpenActor", _actor, true];
_spawnPoint setVariable ["Waldo_VVD_OpenToken", _token, true];
_spawnPoint setVariable ["Waldo_VVD_OpenUntil", _now + 600, true];
diag_log format ["[WMP VVD] Garage lock acquired pad=%1 actor=%2 owner=%3 token=%4", netId _spawnPoint, name _actor, _requestOwner, _token];

[_spawnPoint, _types, _sideLimit, _removeUAVs, _token] remoteExecCall ["Waldo_fnc_VVDOpen", _requestOwner];

[_spawnPoint, _actor, _token] spawn {
    params ["_pad", "_ownerActor", "_attemptToken"];
    waitUntil {
        uiSleep 1;
        isNull _pad
        || {isNull _ownerActor}
        || {!alive _ownerActor}
        || {(_pad getVariable ["Waldo_VVD_OpenToken", ""]) != _attemptToken}
        || {serverTime >= (_pad getVariable ["Waldo_VVD_OpenUntil", 0])}
    };
    if (!isNull _pad && {(_pad getVariable ["Waldo_VVD_OpenToken", ""]) == _attemptToken}) then {
        [_pad, _ownerActor, _attemptToken, "ABANDONED"] call Waldo_fnc_VVDReleaseOpenServer;
    };
};
