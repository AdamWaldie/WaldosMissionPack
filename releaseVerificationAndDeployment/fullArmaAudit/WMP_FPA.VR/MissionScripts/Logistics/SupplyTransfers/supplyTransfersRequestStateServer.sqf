/*
 * Author: WaldoTheWarfighter
 * Purpose: Replays registered supply containers to a joining client's ACE interaction installer.
 * Locality / Authority: Server only; validates the requesting player's ownership.
 * Repeat / JIP: Safe on every client startup or explicit refresh.
 * Arguments: player <OBJECT>. Return Value: <BOOL> sent.
 * Current caller: Waldo_fnc_SupplyTransfersSetupLocal during player startup.
 * Example: [player] remoteExecCall ["Waldo_fnc_SupplyTransfersRequestStateServer", 2];
 * Result: The requester receives the current registered-container snapshot.
 */
params [["_player", objNull, [objNull]]];
if (!isServer || {isNull _player}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}) exitWith {false};
[missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []]]
    remoteExecCall ["Waldo_fnc_SupplyTransfersSetupLocal", _player];
true
