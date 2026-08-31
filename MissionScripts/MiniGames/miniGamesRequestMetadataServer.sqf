/*
 * Author: WaldoTheWarfighter
 * Returns canonical registered-table metadata to one authenticated JIP/interface client.
 *
 * Locality/authority: Server only; requester ownership must match remoteExecutedOwner.
 * Repeat/JIP: Read-only and repeat-safe. Sends data, never executable code or game-private state.
 * Arguments: 0 Object - requesting player.
 * Return Value: Nothing; targeted metadata response.
 * Current callers: MiniGamesInitPlayerLocal after the public registry becomes non-empty.
 * Example: [player] remoteExecCall ["Waldo_fnc_MiniGamesRequestMetadataServer", 2];
 */

params [["_actor", objNull, [objNull]]];
if (!isServer || {isNull _actor}) exitWith {};
if (remoteExecutedOwner > 0 && {owner _actor != remoteExecutedOwner}) exitWith {
    diag_log format ["[WMP MINIGAMES] Rejected forged metadata request actorOwner=%1 remoteOwner=%2", owner _actor, remoteExecutedOwner];
};
private _rows = [];
{
    if (!isNull _x && {_x getVariable ["Waldo_MG_IsPartyTable", false]}) then {
        _rows pushBack [_x, _x getVariable ["Waldo_MG_TableRegistration", []]];
    };
} forEach (missionNamespace getVariable ["Waldo_MG_Tables", []]);
[_rows] remoteExecCall ["Waldo_fnc_MiniGamesApplyMetadataLocal", owner _actor];
