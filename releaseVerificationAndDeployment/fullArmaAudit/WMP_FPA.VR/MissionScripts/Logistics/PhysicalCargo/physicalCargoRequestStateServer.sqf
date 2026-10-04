/*
 * Author: WaldoTheWarfighter
 * Purpose: Sends the current physical-mount snapshot and revision to a joining client or headless owner.
 * Locality / Authority: Server only; replies only to the authenticated remote owner.
 * Repeat / JIP: Safe to request after initial state or locality changes.
 * Arguments: requesting player <OBJECT> or headless client owner ID <NUMBER>. Return Value: <BOOL> sent.
 * Current callers: Waldo_fnc_PhysicalCargoInitLocal and the headless path in init.sqf.
 * Example: [player] remoteExecCall ["Waldo_fnc_PhysicalCargoRequestStateServer", 2];
 * Result: The requester receives the current ordered mount snapshot.
 */
params [["_requester", objNull, [objNull, 0]]];
if (!isServer) exitWith {false};
private _target = if (_requester isEqualType objNull) then {
    if (isNull _requester) exitWith {-1};
    owner _requester
} else {_requester};
if (_target < 2 || {isRemoteExecuted && {remoteExecutedOwner isNotEqualTo _target}}) exitWith {false};
[missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []],
    missionNamespace getVariable ["Waldo_PhysicalCargo_MountRevision", 0]]
    remoteExecCall ["Waldo_fnc_PhysicalCargoReceiveStateLocal", _target];
true
