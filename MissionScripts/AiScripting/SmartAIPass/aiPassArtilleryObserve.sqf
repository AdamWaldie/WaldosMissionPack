/*
 * Author: WaldoTheWarfighter
 * Requests one owner-local observation per ranging step and returns it to the server.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: battery <OBJECT>; 1: token <STRING>; 2: spotter <OBJECT>; 3: enemy <OBJECT>; 4: last impact ATL <ARRAY>.
 * Return Value: Nothing.
 * Current callers: ArtilleryMissionStep.
 * Example: [_gun, _token, _spotter, _enemy, []] remoteExecCall ["Waldo_fnc_AIPassArtilleryObserve", owner _spotter];
 */
params ["_battery", "_token", "_spotter", "_enemy", "_impact"];
if (remoteExecutedOwner != 2 || {!local _spotter}) exitWith {};
private _fix = [_spotter, _enemy, _impact] call Waldo_fnc_AIPassSpotterFix;
[_battery, _token, _spotter, _fix] remoteExecCall ["Waldo_fnc_AIPassArtilleryReport", 2];
