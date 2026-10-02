/*
 * Author: WaldoTheWarfighter
 * Executes one finite Cortex aircraft attack as ingress, attack and egress phases.
 * It flies physical route legs, repeatedly presents the live target to operating crew, records real
 * non-countermeasure shots and requests finite approach/departure countermeasures. A lack of travel
 * or fire aborts the run; elapsed time alone never completes it. Zeus priority, locality loss,
 * eligibility changes or a changed curator waypoint end the lease immediately without restoring an
 * obsolete order. A successful run hands the aircraft back toward its unchanged original waypoint.
 * Locality/authority: aircraft owner only. Public summary/outcome arrays support Zeus diagnostics;
 * movement commands and Fired handlers remain owner-local.
 * Repeat/JIP: one job per aircraft. Cleanup removes the owned handler, speed limit and public plan.
 * Arguments: 0: scheduler job <HASHMAP>; aircraft <OBJECT> is required; target <OBJECT> is optional
 * when an authenticated combined-arms opportunity already selected it.
 * Return Value: NUMBER delay, or -1 after cleanup.
 * Current callers: Waldo_fnc_CortexDiscover and Waldo_fnc_CortexCombinedArmsLocal through the
 * budgeted Cortex scheduler.
 * Example: [createHashMapFromArray [["aircraft",_plane]]] call Waldo_fnc_CortexAirAttack;
 */
params [["_job",createHashMap,[createHashMap]]];
private _aircraft=_job getOrDefault ["aircraft",objNull];
if (isNull _aircraft) exitWith {-1};
private _finish={
    params ["_reason",["_resume",false]];
    private _finishGroup=group driver _aircraft;
    if (!isNull _finishGroup && {"token" in _job}) then {[_finishGroup,_job,"ENDED",_reason] call Waldo_fnc_CortexDrillSetStage};
    private _handler=_job getOrDefault ["firedHandler",-1];
    if (_handler >= 0) then {_aircraft removeEventHandler ["Fired",_handler]};
    if (local _aircraft) then {
        _aircraft limitSpeed -1;
        if (_resume) then {
            private _resumePosition=_job getOrDefault ["resumePosition",[]];
            if (count _resumePosition >= 2 && {!([group driver _aircraft] call Waldo_fnc_CortexZeusHeld)}) then {(driver _aircraft) doMove _resumePosition};
        };
    };
    _aircraft setVariable ["Waldo_Cortex_AirAttackOutcome",[_reason,serverTime,_job getOrDefault ["pattern",""],_job getOrDefault ["shots",0]],true];
    _aircraft setVariable ["Waldo_Cortex_AirAttackPlan",nil,true];
    _aircraft setVariable ["Waldo_Cortex_AirAttackJob",nil];
    _aircraft setVariable ["Waldo_Cortex_AirAttackToken",nil];
    -1
};
private _pilot=driver _aircraft;
private _group=group _pilot;
private _allowed=local _aircraft && {alive _aircraft} && {!isNull _pilot} && {alive _pilot} && {!isPlayer _pilot}
    && {!unitIsUAV _aircraft} && {missionNamespace getVariable ["Waldo_AIPass_Active",false]}
    && {!([] call Waldo_fnc_CortexIsPaused)}
    && {!([_group] call Waldo_fnc_CortexZeusHeld)}
    && {[_group,"Waldo_Cortex_AirAttack_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
    && {[_group] call Waldo_fnc_CortexIsEligible};
if (!_allowed) exitWith {["CONTROL_RELEASED"] call _finish};
private _isPlane=_aircraft isKindOf "Plane";
// A helicopter may validly begin an attack from a hover. Planes still need enough energy to enter a
// finite run; accepting a stationary plane would make its own spawn/ground state look like tactics.
if (isTouchingGround _aircraft || {_isPlane && {speed _aircraft < 40}} || {combatMode _group in ["BLUE","GREEN"]}) exitWith {["NOT_ATTACKING"] call _finish};

private _stage=_job getOrDefault ["stage",""];
private _startFailure="";
if (_stage == "") then {
    private _target=_job getOrDefault ["target",objNull];
    if (isNull _target || {!alive _target} || {(side _group) getFriend side _target >= 0.6}) then {
        _target=objNull;
        {
            private _candidate=assignedTarget _x;
            if (!isNull _candidate && {alive _candidate} && {(side _group) getFriend side _candidate < 0.6}) exitWith {_target=_candidate};
        } forEach ([effectiveCommander _aircraft,driver _aircraft,gunner _aircraft,commander _aircraft]+crew _aircraft);
    };
    if (isNull _target) then {_startFailure="NO_TARGET"};
    private _plan=if (_startFailure == "") then {[_aircraft,_target] call Waldo_fnc_CortexAirAttackPlan} else {createHashMap};
    if (_startFailure == "" && {count _plan == 0}) then {_startFailure="NO_PLAN"};
    if (_startFailure == "") then {
    private _waypointIndex=currentWaypoint _group;
    private _resumePosition=[];
    if (_waypointIndex >= 0 && {_waypointIndex < count waypoints _group}) then {_resumePosition=waypointPosition [_group,_waypointIndex]};
    private _routeSignature=[count waypoints _group,_waypointIndex,_resumePosition,
        if (_waypointIndex >= 0 && {_waypointIndex < count waypoints _group}) then {waypointType [_group,_waypointIndex]} else {""}];
    _job set ["target",_target]; _job set ["points",_plan get "points"];
    _job set ["pattern",_plan get "pattern"]; _job set ["token",_plan get "token"];
    _job set ["aaPositions",_plan get "aaPositions"];
    _job set ["altitude",_plan get "altitude"]; _job set ["speed",_plan get "speed"];
    _job set ["type","AIR_ATTACK"]; _job set ["stage",""]; _job set ["deadline",serverTime+75]; _job set ["shots",0];
    _job set ["origin",getPosATL _aircraft]; _job set ["resumePosition",_resumePosition]; _job set ["routeSignature",_routeSignature];
    _job set ["progressPosition",getPosATL _aircraft]; _job set ["progressAt",serverTime]; _job set ["replans",0];
    _aircraft setVariable ["Waldo_Cortex_AirAttackToken",_plan get "token"];
    private _handler=_aircraft addEventHandler ["Fired",{
        params ["_aircraft","_weapon"];
        if (toLowerANSI getText (configFile >> "CfgWeapons" >> _weapon >> "simulation") != "cmlauncher") then {
            _aircraft setVariable ["Waldo_Cortex_AirAttackShots",(_aircraft getVariable ["Waldo_Cortex_AirAttackShots",0])+1];
        };
    }];
    _aircraft setVariable ["Waldo_Cortex_AirAttackShots",0];
    _job set ["firedHandler",_handler];
    [_group,_job,"INGRESS","PLAN_ACCEPTED"] call Waldo_fnc_CortexDrillSetStage;
        _stage="INGRESS";
    };
};
if (_startFailure != "") exitWith {[_startFailure] call _finish};
private _waypointIndex=currentWaypoint _group;
private _currentResume=[];
if (_waypointIndex >= 0 && {_waypointIndex < count waypoints _group}) then {_currentResume=waypointPosition [_group,_waypointIndex]};
private _currentRoute=[count waypoints _group,_waypointIndex,_currentResume,
    if (_waypointIndex >= 0 && {_waypointIndex < count waypoints _group}) then {waypointType [_group,_waypointIndex]} else {""}];
if (_currentRoute isNotEqualTo (_job getOrDefault ["routeSignature",_currentRoute])) exitWith {["AUTHORED_ROUTE_CHANGED"] call _finish};
private _target=_job getOrDefault ["target",objNull];
if (isNull _target || {!alive _target}) exitWith {["TARGET_LOST",true] call _finish};
if ((getPosATL _aircraft select 2) < 25) exitWith {["GROUND_CLEARANCE"] call _finish};
private _recoveryFailure="";
if (serverTime >= (_job getOrDefault ["progressAt",serverTime])+12) then {
    private _progress=_aircraft distance2D (_job getOrDefault ["progressPosition",getPosATL _aircraft]);
    if (_progress < 15) then {
        private _replans=_job getOrDefault ["replans",0];
        if (_replans >= 1) then {_recoveryFailure="STUCK"} else {
            private _replacement=[_aircraft,_target] call Waldo_fnc_CortexAirAttackPlan;
            if (count _replacement == 0) then {_recoveryFailure="REPLAN_FAILED"} else {
                _job set ["points",_replacement get "points"]; _job set ["pattern",_replacement get "pattern"];
                _job set ["aaPositions",_replacement get "aaPositions"];
                [_group,_job,"REPLAN","STUCK_DETECTED"] call Waldo_fnc_CortexDrillSetStage;
                [_group,_job,"INGRESS","REPLAN_ACCEPTED"] call Waldo_fnc_CortexDrillSetStage;
                _job set ["deadline",serverTime+75]; _job set ["replans",_replans+1]; _stage="INGRESS";
            };
        };
    };
    _job set ["progressPosition",getPosATL _aircraft]; _job set ["progressAt",serverTime];
};
if (_recoveryFailure != "") exitWith {[_recoveryFailure] call _finish};
private _points=_job get "points";
private _stageIndex=["INGRESS","ATTACK","EGRESS"] find _stage;
if (_stageIndex < 0) exitWith {["BAD_STAGE"] call _finish};
private _destination=_points select _stageIndex;
private _shots=_aircraft getVariable ["Waldo_Cortex_AirAttackShots",0];
_job set ["shots",_shots];
_aircraft flyInHeight (_job get "altitude");
_aircraft limitSpeed (_job get "speed");
_pilot doMove _destination;
{if (alive _x) then {_x doTarget _target; if (_stage == "ATTACK") then {_x doFire _target}}} forEach crew _aircraft;

private _flareSetting=[_group,"Waldo_Cortex_AttackRunFlares_Enable",true] call Waldo_fnc_CortexFeatureEnabled;
private _flareKey="flare"+_stage;
private _flareCount=_job getOrDefault [_flareKey,0];
private _flareNextKey="flareNext"+_stage;
private _flareNext=_job getOrDefault [_flareNextKey,serverTime];
if (_flareSetting && {_stage in ["INGRESS","EGRESS"]} && {_flareCount < 3} && {serverTime >= _flareNext}) then {
    _aircraft setVariable ["Waldo_Cortex_AttackFlarePhase",["APPROACH","DEPARTURE"] select (_stage == "EGRESS"),true];
    if ([_aircraft] call Waldo_fnc_CortexFireCountermeasure) then {
        _job set [_flareKey,_flareCount+1];
    };
    // Avoid synchronized salvos across aircraft and respect launcher cycle time.
    _job set [_flareNextKey,serverTime+0.8+random 0.8];
};
_aircraft setVariable ["Waldo_Cortex_AirAttackPlan",[
    _job get "token",_job get "pattern",_stage,_target,_destination,_aircraft distance2D _destination,
    _shots,count ((_job getOrDefault ["aaPositions",[]])),speed _aircraft,getPosATL _aircraft select 2,
    _job getOrDefault ["flareINGRESS",0],_job getOrDefault ["flareEGRESS",0],
    ["HELICOPTER","PLANE"] select _isPlane
],true];

if (serverTime > (_job get "deadline")) exitWith {["STAGE_TIMEOUT"] call _finish};
if (_stage == "EGRESS" && {_aircraft distance2D _destination <= 260} && {_aircraft distance2D (_points select 1) >= 400}) exitWith {["COMPLETE",true] call _finish};
switch _stage do {
    case "INGRESS": {
        if (_aircraft distance2D _destination <= 220) then {
            [_group,_job,"ATTACK","INGRESS_ARRIVAL"] call Waldo_fnc_CortexDrillSetStage;
            _job set ["deadline",serverTime+50];
        };
    };
    case "ATTACK": {
        if (_shots > 0 && {_aircraft distance2D _destination <= 450}) then {
            [_group,_job,"EGRESS","ACTUAL_FIRE"] call Waldo_fnc_CortexDrillSetStage;
            _job set ["deadline",serverTime+75];
        };
    };
    case "EGRESS": {};
};
0.5
