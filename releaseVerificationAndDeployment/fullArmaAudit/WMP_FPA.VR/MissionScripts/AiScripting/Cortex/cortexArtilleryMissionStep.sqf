/*
 * Author: WaldoTheWarfighter
 * Server-owned fire sequence. One observer query per burst; lethal HE bursts receive four red warning smoke shells.
 * Warning smoke surrounds the reported target, ten seconds before the first shot; later shots do not repeat it.
 * Smoke is globally created by the server and deleted after sixty seconds; no per-unit polling is added.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: mission <HASHMAP>, created by ArtilleryFire.
 * Return Value: Number next delay, or -1 to finish.
 * Current callers: Smart AI scheduler.
 * Example: [Waldo_fnc_CortexArtilleryMissionStep, _mission, 0] call Waldo_fnc_CortexQueueJob;
 */
params ["_mission"];
if (!isServer) exitWith {-1};
private _battery = _mission get "battery";
private _finish = {
    private _counter = (_mission get "purpose") == "COUNTER";
    private _cooldown = time + (missionNamespace getVariable [["Waldo_AIPass_Artillery_Cooldown", "Waldo_AIPass_CounterBattery_Interval"] select _counter, 120]);
    private _spotter = _mission get "spotter";
    if (!isNull _spotter) then {_spotter setVariable ["Waldo_AIPass_NextFireRequest_" + (_mission get "purpose"), _cooldown]};
    if (_counter && {!isNull (_mission get "enemy")}) then {(_mission get "enemy") setVariable ["Waldo_AIPass_CounterUntil_" + str (_mission get "side"), _cooldown]};
    (missionNamespace getVariable ["Waldo_AIPass_FireMissions", createHashMap]) deleteAt (_mission get "key");
    _battery setVariable ["Waldo_AIPass_FireToken", nil, true];
    _battery setVariable ["Waldo_AIPass_BusyUntil", nil, true];
    -1
};
if ((_mission get "phase") in ["PENDING", "UNCERTAIN"] && {alive _battery}) then {
    // The engine may still hold this one firing order. Retain its lock until an event or explicit stop.
    _mission set ["deadline", time + 900];
};
private _requester=_mission getOrDefault ["requester",grpNull];
private _requesterBlocked=!isNull _requester && {!([_requester,"Waldo_AIPass_Artillery_Enable",false] call Waldo_fnc_CortexFeatureEnabled) || {!([_requester,"Waldo_AIPass_ArtillerySmoke_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}};
private _blocked = _requesterBlocked || {!alive _battery} || {!alive gunner _battery}
    || {combatMode group gunner _battery == "BLUE"} || {unitCombatMode gunner _battery == "BLUE"} || {time > (_mission get "deadline")}
    || {side group gunner _battery != (_mission get "side")}
    || {!([group gunner _battery] call Waldo_fnc_CortexIsEligible)}
    || {!([_battery, _mission get "purpose"] call Waldo_fnc_CortexArtilleryRole)}
    || {!([group gunner _battery, ["Waldo_AIPass_Artillery_Enable", "Waldo_AIPass_CounterBattery_Enable"] select ((_mission get "purpose") == "COUNTER"), false] call Waldo_fnc_CortexFeatureEnabled)};
if (_blocked) exitWith {
    if (alive _battery && {(_mission get "phase") in ["PENDING", "UNCERTAIN"]}) then {
        _mission set ["remaining", 0];
    _mission set ["burstsLeft", 0];
        _mission set ["phase", "UNCERTAIN"];
        10
    } else {call _finish}
};
private _phase = _mission get "phase";
if (time < (_mission get "due")) exitWith {1};
// A missing firing event is uncertain. Never reissue it, including after an HC disconnect.
if (_phase in ["PENDING", "UNCERTAIN"]) exitWith {
    if (_phase == "PENDING") then {diag_log "[WMP CORTEX] Unconfirmed artillery shot quarantined; no retry."};
    _mission set ["phase", "UNCERTAIN"];
    _mission set ["remaining", 0];
    _mission set ["burstsLeft", 0];
    _mission set ["deadline", time + 900];
    _mission set ["due", time + 10];
    10
};
if ((_mission get "burstsLeft") <= 0) exitWith {
    if (_mission get "scoot" && {(_mission get "fired") > 0} && {!(_battery isKindOf "StaticWeapon")}) then {
        private _scootToken = _mission get "token";
        _battery setVariable ["Waldo_Cortex_ArtilleryScootToken",_scootToken,true];
        _battery setVariable ["Waldo_Cortex_ArtilleryScootDeadline",serverTime+120,true];
        _battery setVariable ["Waldo_Cortex_ArtilleryScootPurpose",_mission get "purpose",true];
        [_battery,_scootToken] remoteExecCall ["Waldo_fnc_CortexArtilleryScoot", owner _battery];
    };
    call _finish
};
if (_phase == "WAIT") then {
    _mission set ["remaining", _mission get "burstSize"];
    private _spotter = _mission get "spotter";
    if ((_mission get "purpose") != "COUNTER" && {alive _spotter} && {_spotter getVariable ["Waldo_AIPass_Spotter", false]}) then {
        _mission set ["phase", "OBSERVE"];
        _mission set ["observerOwner", owner _spotter];
        _mission set ["due", time + 3];
        [_battery, _mission get "token", _spotter, _mission get "enemy", _mission getOrDefault ["aim", []]] remoteExecCall ["Waldo_fnc_CortexArtilleryObserve", owner _spotter];
    } else {
        if ((_mission get "purpose") == "COUNTER") then {
            // Only firing-event snapshots supply new enemy positions, never its live transform.
            private _emission = (_mission get "enemy") getVariable ["Waldo_AIPass_LastEmission", []];
            if (_emission isNotEqualTo [] && {(_emission select 1) distance2D (_mission get "location") >= (missionNamespace getVariable ["Waldo_AIPass_Artillery_LocationResetDistance", 150])}) then {
                _mission set ["fix", [+(_emission select 1), 30]];
                _mission set ["location", +(_emission select 1)];
                _mission set ["offset", 300];
                _mission set ["opening", true];
                _mission set ["bearing", random 360];
            } else {
                if ((_mission get "burstsCompleted") > 0) then {
                    _mission set ["offset", ((_mission get "offset") * 0.55) max 40];
                    _mission set ["opening", false];
                };
            };
        };
        _mission set ["phase", "READY"];
    };
};
if ((_mission get "phase") == "OBSERVE" && {time >= (_mission get "due")}) then {_mission set ["phase", "READY"]};
if (!((_mission get "phase") in ["READY", "WARNED", "FIRING"])) exitWith {1};
private _aim = if ((_mission get "phase") in ["WARNED", "FIRING"]) then {_mission get "aim"} else {[_mission] call Waldo_fnc_CortexArtilleryAim};
if (_aim isEqualTo []) exitWith {diag_log "[WMP CORTEX] No safe in-range ranging point; fire mission cancelled."; call _finish};
_mission set ["aim", _aim];
// Server-owned phase guarantees one spread per burst, including across gun-owner migration.
// Warn around the reported target, not the deliberately offset opening ranging point.
if ((_mission get "phase") == "READY" && {(_mission get "mode") == "HE"}) exitWith {
    private _target=(_mission get "fix") select 0;
    private _smokes=[];
    for "_index" from 0 to 3 do {
        private _position=_target getPos [25,90*_index];
        _position set [2,0.2];
        private _smoke=createVehicle ["SmokeShellRed",_position,[],0,"CAN_COLLIDE"];
        _smokes pushBack _smoke;
    };
    [{params ["_smokes"]; {if (!isNull _x) then {deleteVehicle _x}} forEach _smokes},[_smokes],60] call CBA_fnc_waitAndExecute;
    _mission set ["phase","WARNED"];
    _mission set ["due",time+10];
    diag_log format ["[WMP CORTEX] Artillery warning token=%1 burst=%2 target=%3 smoke=%4",_mission get "token",(_mission get "burstsCompleted")+1,_target,count _smokes];
    10
};
_mission set ["phase", "PENDING"];
_mission set ["due", time + 60];
_mission set ["gunOwner", owner _battery];
[_battery, _aim, _mission get "magazine", _mission get "purpose", _mission get "mode", _mission get "token"] remoteExecCall ["Waldo_fnc_CortexArtilleryShot", owner _battery];
1
