/*
 * Author: WaldoTheWarfighter
 * Releases a pending round when its addressed owner confirms no firing command was issued.
 * Locality/authority: server only; the response must match the recorded owner and mission token.
 * Repeat/JIP: stale/repeated replies do nothing; no JIP replay.
 * Arguments: 0: battery <OBJECT>; 1: token <STRING>.
 * Return Value: Nothing.
 * Current callers: ArtilleryShot rejection paths.
 * Example: [_gun, _token] remoteExecCall ["Waldo_fnc_AIPassArtilleryRejected", 2];
 */
params ["_battery", "_token"];
if (!isServer) exitWith {};
private _mission = (missionNamespace getVariable ["Waldo_AIPass_FireMissions", createHashMap]) getOrDefault [netId _battery, createHashMap];
if (count _mission == 0 || {(_mission get "token") != _token}
    || {remoteExecutedOwner != (_mission getOrDefault ["gunOwner", -1])}
    || {!((_mission get "phase") in ["PENDING", "UNCERTAIN"])}) exitWith {};
_mission set ["remaining", 0];
_mission set ["burstsLeft", 0];
_mission set ["phase", "WAIT"];
_mission set ["due", time];
_mission set ["scoot", false];
