/* Releases a VVD lock only when actor and opaque token still match. */
params [
    ["_spawnPoint", objNull, [objNull]],
    ["_actor", objNull, [objNull]],
    ["_token", "", [""]],
    ["_reason", "CLOSED", [""]]
];

if (!isServer) exitWith {
    _this remoteExecCall ["Waldo_fnc_VVDReleaseOpenServer", 2];
};
if (isNull _spawnPoint || {_token == ""}) exitWith {false};

private _requestOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
private _matches = (_spawnPoint getVariable ["Waldo_VVD_OpenToken", ""]) == _token
    && {(_spawnPoint getVariable ["Waldo_VVD_OpenActor", objNull]) isEqualTo _actor}
    && {!isRemoteExecuted || {owner _actor == _requestOwner}};
if (!_matches) exitWith {
    diag_log format ["[WMP VVD] Lock release rejected pad=%1 actor=%2 owner=%3 reason=%4", netId _spawnPoint, _actor, _requestOwner, _reason];
    false
};

_spawnPoint setVariable ["Waldo_VVD_OpenActor", objNull, true];
_spawnPoint setVariable ["Waldo_VVD_OpenToken", "", true];
_spawnPoint setVariable ["Waldo_VVD_OpenUntil", 0, true];
diag_log format ["[WMP VVD] Garage lock released pad=%1 actor=%2 reason=%3", netId _spawnPoint, _actor, _reason];
true
