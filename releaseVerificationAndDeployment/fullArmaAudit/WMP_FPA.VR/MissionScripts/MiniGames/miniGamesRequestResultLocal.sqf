/*
 * Author: WaldoTheWarfighter
 * Receives one targeted MiniGames acknowledgement and refreshes only the owning client's active view.
 *
 * Locality/authority: Target interface client only. No authoritative state is changed.
 * Repeat/JIP: Duplicate tokens are ignored by the existing local result handler.
 * Arguments: [token String, accepted Boolean, reason String, revision Number].
 * Return Value: Nothing.
 * Current callers: MiniGamesRequestServer and server rule processors through resultServer.
 * Example: ["JOIN_1", true, "Seat assigned.", 4] call Waldo_fnc_MiniGamesRequestResultLocal;
 */

params [["_token", "", [""]], ["_accepted", false, [false]], ["_reason", "", [""]], ["_revision", -1, [0]]];
if (!hasInterface || {_token == ""}) exitWith {};
if (isNil "Waldo_MG_fnc_showRequestResultLocal") then {call Waldo_fnc_MiniGamesEnsureRuntime;};
missionNamespace setVariable ["Waldo_MG_RequestResultLocal", [_token, _accepted, _reason, _revision]];
player setVariable ["Waldo_MG_RequestResult", [_token, _reason]];
call Waldo_MG_fnc_showRequestResultLocal;
call Waldo_MG_fnc_maintainSeatStateLocal;
call Waldo_MG_fnc_maintainGameTransitionLocal;
