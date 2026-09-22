/*
 * Author: WaldoTheWarfighter
 * Purpose: Sends the current physical-mount snapshot to a joining interface client.
 * Locality / Authority: Server only; replies only to the requesting player's owner.
 * Repeat / JIP: Safe to request after initial state or locality changes.
 * Arguments: requesting player <OBJECT>. Return Value: <BOOL> sent.
 * Current caller: Waldo_fnc_PhysicalCargoInitLocal.
 * Example: [player] remoteExecCall ["Waldo_fnc_PhysicalCargoRequestStateServer", 2];
 */
params [["_player", objNull, [objNull]]];
if (!isServer || {isNull _player}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}) exitWith {false};
[missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]]
    remoteExecCall ["Waldo_fnc_PhysicalCargoReceiveStateLocal", _player];
true
