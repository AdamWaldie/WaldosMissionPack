/*
 * Author: WaldoTheWarfighter
 * Confirms a pending shot using the global engine firing event and starts the flight-time plus warning interval.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: ArtilleryShellFired event payload, documented by Bohemia.
 * Return Value: Nothing.
 * Current callers: ArtilleryShellFired mission handler.
 * Example: _this call Waldo_fnc_AIPassArtilleryFired;
 */
params ["_battery", "", "_ammo", "", "", "", "_position"];
if (!isServer) exitWith {};
private _mission = (missionNamespace getVariable ["Waldo_AIPass_FireMissions", createHashMap]) getOrDefault [netId _battery, createHashMap];
if (count _mission == 0 || {!((_mission get "phase") in ["PENDING", "UNCERTAIN"])}) exitWith {};
if (_ammo != getText (configFile >> "CfgMagazines" >> (_mission get "magazine") >> "ammo")
    || {_position distance2D (_mission get "aim") > 10}) exitWith {};
if ((_mission get "fired") == 0) then {
    missionNamespace setVariable ["Waldo_AIPass_ArtilleryMissions", (missionNamespace getVariable ["Waldo_AIPass_ArtilleryMissions", 0]) + 1];
};
private _eta = (_battery getArtilleryETA [_mission get "aim", _mission get "magazine"]) max 0;
_mission set ["remaining", (_mission get "remaining") - 1];
_mission set ["fired", (_mission get "fired") + 1];
_mission set ["phase", "WAIT"];
_mission set ["due", time + _eta + ((missionNamespace getVariable ["Waldo_AIPass_Artillery_WarningInterval", 20]) max 10)];
diag_log format ["[WMP AI PASS] Ranging shot confirmed token=%1 round=%2 aim=%3 eta=%4", _mission get "token", _mission get "fired", _mission get "aim", _eta];
