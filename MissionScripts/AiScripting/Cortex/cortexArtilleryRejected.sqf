/*
 * Author: WaldoTheWarfighter
 * Releases a pending round when its addressed owner confirms no firing command was issued.
 * Locality/authority: server only; the response must match the recorded owner and mission token.
 * Repeat/JIP: stale/repeated replies do nothing; no JIP replay.
 * Arguments: 0: battery <OBJECT>; 1: token <STRING>.
 * 2: reply owner <NUMBER>, default -1; HC callers supply clientOwner.
 * Return Value: Nothing.
 * Current callers: ArtilleryShot rejection paths.
 * Example: [_gun, _token, clientOwner] remoteExecCall ["Waldo_fnc_CortexArtilleryRejected", 2];
 */
params ["_battery", "_token", ["_replyOwner",-1,[0]]];
if (!isServer) exitWith {};
private _mission = (missionNamespace getVariable ["Waldo_AIPass_FireMissions", createHashMap]) getOrDefault [netId _battery, createHashMap];
if (count _mission == 0 || {(_mission get "token") != _token}
    || {([_replyOwner,_mission getOrDefault ["gunOwner", -1]] call Waldo_fnc_HeadlessResolveSender) < 0}
    || {!((_mission get "phase") in ["PENDING", "UNCERTAIN"])}) exitWith {};
_mission set ["remaining", 0];
_mission set ["burstsLeft", 0];
_mission set ["phase", "WAIT"];
_mission set ["due", time];
_mission set ["scoot", false];
