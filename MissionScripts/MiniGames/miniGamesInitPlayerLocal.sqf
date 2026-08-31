/*
 * Author: WaldoTheWarfighter
 * Requests one registered seated-table metadata snapshot for this interface client without
 * transmitting executable code. Arma has already replayed the public table membership and object
 * variables before initPlayerLocal; WMP requests the canonical row once so local ACE/vanilla
 * interactions are installed after the joining player's interface exists.
 *
 * Locality/authority: Interface client only; reads the engine-replicated membership registry and
 * asks the server for presentation metadata. Runtime table registration uses the direct
 * MiniGamesRegisterTableLocal path, so no permanent public-variable listener is required.
 * Repeat/JIP: Repeat-safe and intended for initPlayerLocal and respawn/local-player replacement.
 * One invocation sends at most one metadata request and creates no event handler or JIP entry.
 * Arguments: None.
 * Return Value: Boolean.
 * Current callers: initPlayerLocal.sqf.
 * Example: [] call Waldo_fnc_MiniGamesInitPlayerLocal;
 */

if (!hasInterface) exitWith {false};
private _tables = missionNamespace getVariable ["Waldo_MG_Tables", []];
if ((count _tables) == 0) exitWith {true};
[player] remoteExecCall ["Waldo_fnc_MiniGamesRequestMetadataServer", 2];
true
