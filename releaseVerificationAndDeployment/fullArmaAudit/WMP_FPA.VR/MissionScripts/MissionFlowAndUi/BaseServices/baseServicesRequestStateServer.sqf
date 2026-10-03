/*
 * Author: WaldoTheWarfighter
 * Purpose: Replays the complete service-network registry to a joining player.
 * Locality / Authority: Server only, replying to the owner's interface client.
 * Repeat / JIP: Safe to request repeatedly; local setup reconciles old ACE paths.
 * Arguments: player <OBJECT>. Return Value: <BOOL> sent.
 * Current caller: Waldo_fnc_BaseServicesSetupLocal during player startup.
 * Example: [player] remoteExecCall ["Waldo_fnc_BaseServicesRequestStateServer", 2];
 * Result: The joining player's client receives the current base-service group snapshot.
 */
params [["_player", objNull, [objNull]]];
if (!isServer || {isNull _player}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}) exitWith {false};
[missionNamespace getVariable ["Waldo_BaseServices_Registry", []]]
    remoteExecCall ["Waldo_fnc_BaseServicesSetupLocal", _player];
true
