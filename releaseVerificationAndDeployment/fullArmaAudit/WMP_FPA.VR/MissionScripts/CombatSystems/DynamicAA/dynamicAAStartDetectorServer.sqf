/*
 * Author: WaldoTheWarfighter
 * Starts one Dynamic AA detector from a clean server-owned remote-execution context. ZEN creation
 * begins inside the curator client's remoteExec context; spawning the detector directly from that
 * call can preserve the curator owner ID and cause the owner-local fire-gate security checks to
 * reject every update. A server-to-server handoff gives Eden and ZEN systems the same authority.
 *
 * Locality and authority: server only. The call must be server-local or originate from owner 2.
 * The server registry remains authoritative; repeated starts terminate the previous stored handle.
 * The detector itself exits when the registry entry is removed/deactivated, so JIP needs no worker.
 *
 * Arguments:
 * 0: system ID <STRING> - existing Dynamic AA registry key.
 *
 * Return Value:
 * Boolean - true when a fresh detector was stored; false for invalid authority/state.
 *
 * Current caller:
 * Waldo_fnc_DynamicAACreate through a server-self remoteExecCall after registration is complete.
 *
 * Example:
 * ["AA_NORTH"] remoteExecCall ["Waldo_fnc_DynamicAAStartDetectorServer", 2];
 */

params [["_id", "", [""]]];
if (!isServer || {_id == ""}) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {
    diag_log format ["[WMP DYNAMIC AA] Detector start rejected for '%1': remote owner %2 is not server authority.", _id, remoteExecutedOwner];
    false
};

private _registry = missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap];
private _state = _registry getOrDefault [_id, createHashMap];
if (_state isEqualTo createHashMap || {!(_state getOrDefault ["active", false])}) exitWith {false};

private _oldHandle = _state getOrDefault ["handle", scriptNull];
if !(scriptDone _oldHandle) then {terminate _oldHandle};
private _handle = [_id] spawn Waldo_fnc_DynamicAADetectorLoop;
_state set ["handle", _handle];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_DynamicAA_Registry", _registry];
diag_log format ["[WMP DYNAMIC AA] Detector started with server authority: system=%1 remoteOwner=%2.", _id, remoteExecutedOwner];
true
