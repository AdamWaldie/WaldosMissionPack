/*
 * Author: WaldoTheWarfighter
 * Executes one finite Cortex aircraft attack as ingress, attack and egress phases.
 * It flies physical route legs, repeatedly presents the live target to operating crew, records real
 * non-countermeasure shots and requests finite approach/departure countermeasures. Standoff weapons
 * fire only after the engine reports an aim solution; lateral runs command only the retained turret
 * operator. A lack of travel, solution or fire aborts the run; elapsed time alone never completes it. Zeus priority, locality loss,
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
        // Every targeting command below is issued by this finite Cortex lease. Retire those commands
        // before handover so a curator MOVE does not keep competing with the old attack target.
        // The engine remains free to reacquire under the replacement waypoint and combat mode.
        if (_reason in ["CONTROL_RELEASED","AUTHORED_ROUTE_CHANGED"]) then {
            // flyInHeight has no getter. Preserve the aircraft's physical handover height instead
            // of leaving the Cortex attack altitude active; otherwise a replacement Zeus MOVE can
            // spend its whole useful window climbing in place before it starts translating.
            _aircraft flyInHeight (((getPosATL _aircraft) select 2) max 25);
            private _leasedTarget=_job getOrDefault ["target",objNull];
            {
                if (alive _x && {!isPlayer _x}) then {
                    _x doTarget objNull;
                    _x doWatch objNull;
                };
            } forEach crew _aircraft;
            // Cortex explicitly revealed the attack target to the group to obtain a weapon
            // solution. Merely clearing doTarget leaves that artificial knowledge at maximum
            // confidence, so an AWARE/COMBAT pilot can keep circling the old target instead of
            // accepting the curator's replacement route. Retire only the target owned by this
            // finite lease; ordinary contacts and the curator's new order remain untouched.
            if (!isNull _leasedTarget && {!isNull _finishGroup}) then {
                _finishGroup forgetTarget _leasedTarget;
            };
            // Direct sight can immediately rebuild engine knowledge after forgetTarget. Lease only
            // the pilot's TARGET/AUTOTARGET selection while the curator route takes hold. Earlier
            // suppression of AUTOCOMBAT stalled some helicopters; it deliberately remains enabled.
            // Gunners are untouched and continue sensing, aiming and returning fire.
            private _handoverPilot=driver _aircraft;
            private _handoverFeatures=["TARGET","AUTOTARGET"] select {
                _handoverPilot checkAIFeature _x
            };
            {_handoverPilot disableAI _x} forEach _handoverFeatures;
            private _handoverCombatMode=unitCombatMode _handoverPilot;
            private _handoverPilotBehaviour=combatBehaviour _handoverPilot;
            private _handoverLeasedBehaviour="";
            private _handoverToken=format ["%1:%2:%3",netId _aircraft,clientOwner,diag_tickTime];
            _aircraft setVariable ["Waldo_Cortex_AirHandoverLease",[_handoverToken,clientOwner],true];
            // Re-issue the current authored destination once at group level, after retiring Cortex
            // targeting. An individual driver doMove can compete with the active group waypoint and
            // leave a helicopter reversing in place. The group move uses Zeus's exact destination;
            // Cortex does not invent or replace a route.
            private _handoverGroup=group driver _aircraft;
            private _handoverGroupCombatMode=combatMode _handoverGroup;
            private _handoverAttackEnabled=attackEnabled _handoverGroup;
            // The attack job deliberately revealed and assigned its target. Arma can therefore
            // keep detaching the pilot to engage even after the target commands are cleared. Stop
            // only that autonomous engage-at-will delegation while the curator's replacement leg
            // takes hold. Turrets retain their weapons, target knowledge and ability to return fire.
            _handoverGroup enableAttack false;
            // RED permits engage-at-will manoeuvres that can abandon even a valid MOVE route.
            // YELLOW retains fire-at-will for every gunner while requiring the group to follow the
            // curator route. Restore the original value only if this lease still owns YELLOW.
            _handoverGroup setCombatMode "YELLOW";
            // The driver is the only crew member whose attack manoeuvre can steer the aircraft
            // away from Zeus. BLUE prevents that pilot from initiating fire during the bounded
            // handover; turret crews retain the group's YELLOW fire permission. Cleanup restores
            // the pilot's previous individual mode without changing a later curator/script value.
            _handoverPilot setUnitCombatMode "BLUE";
            private _handoverIndex=currentWaypoint _handoverGroup;
            private _handoverPosition=[];
            private _authoredBehaviour="";
            private _authoredSpeed="";
            private _authoredWaypointIndex=-1;
            private _zeusSnapshot=_handoverGroup getVariable ["Waldo_Cortex_ZeusOrderSnapshot",[]];
            // CortexZeusMark clears this snapshot for every later non-waypoint takeover and
            // replaces it for every later waypoint takeover. Its presence is therefore the
            // ownership boundary; the embedded hold token remains diagnostic evidence rather
            // than a second independently replicated gate that can race the snapshot in MP.
            private _snapshotMatches=_zeusSnapshot isNotEqualTo [];
            if (_snapshotMatches) then {
                _handoverPosition=+(_zeusSnapshot param [1,[]]);
                _authoredBehaviour=_zeusSnapshot param [2,""];
                _authoredSpeed=_zeusSnapshot param [3,""];
                _authoredWaypointIndex=_zeusSnapshot param [5,-1];
            } else {
                if (_handoverIndex >= 0 && {_handoverIndex < count waypoints _handoverGroup}) then {
                    _handoverPosition=waypointPosition [_handoverGroup,_handoverIndex];
                    _authoredBehaviour=waypointBehaviour [_handoverGroup,_handoverIndex];
                    _authoredSpeed=waypointSpeed [_handoverGroup,_handoverIndex];
                };
            };
            if (count _handoverPosition >= 2) then {
                // Reassert the curator's active group route as well as the pilot destination after
                // retiring the target knowledge introduced by this lease.
                if (_authoredBehaviour in ["CARELESS","SAFE","AWARE","COMBAT","STEALTH"]) then {
                    // Editing an already-active waypoint does not immediately apply its behaviour.
                    // setBehaviour changes the units but not the group entity, allowing the group
                    // to remain COMBAT and fly back toward Cortex's former target. Apply the
                    // curator-authored value strongly to both; the setting is deliberately retained
                    // because it belongs to the replacement waypoint. Fire permission and every
                    // gunner remain intact.
                    _handoverGroup setBehaviourStrong _authoredBehaviour;
                    // A visible hostile can immediately drive the pilot's combat FSM back to
                    // COMBAT even after the group accepted AWARE. Lease only the pilot's combat
                    // behaviour to the curator waypoint; gunners remain untouched and continue
                    // sensing, aiming and returning fire while the aircraft follows the order.
                    _handoverPilot setCombatBehaviour _authoredBehaviour;
                    _handoverLeasedBehaviour=_authoredBehaviour;
                };
                if (_authoredSpeed in ["LIMITED","NORMAL","FULL"]) then {
                    // As with behaviour, editing an active waypoint does not reliably update the
                    // group entity. Apply Zeus's authored speed so a FULL replacement order is not
                    // flown at the stale low-speed attack/hover setting.
                    _handoverGroup setSpeedMode _authoredSpeed;
                };
                // A Cortex attack drives the pilot with doMove, so changing only the group route
                // leaves that old individual destination active. Reactivate the exact waypoint
                // captured at the curator event boundary and replace the pilot destination with
                // the same point. Both command layers then agree with Zeus. The snapshot position
                // guard prevents a deleted/reused index from reviving Cortex's former ingress.
                if (_snapshotMatches
                    && {_authoredWaypointIndex >= 0}
                    && {_authoredWaypointIndex < count waypoints _handoverGroup}
                    && {waypointPosition [_handoverGroup,_authoredWaypointIndex] distance2D _handoverPosition <= 2}) then {
                    _handoverGroup setCurrentWaypoint [_handoverGroup,_authoredWaypointIndex];
                } else {
                    if (!_snapshotMatches && {_handoverIndex >= 0} && {_handoverIndex < count waypoints _handoverGroup}) then {
                        _handoverGroup setCurrentWaypoint [_handoverGroup,_handoverIndex];
                    };
                };
                _handoverGroup move _handoverPosition;
                _handoverPilot doMove _handoverPosition;
            };
            [_aircraft,_handoverPilot,_handoverToken,_handoverFeatures,_handoverPosition,
                _handoverCombatMode,_handoverGroupCombatMode,_handoverAttackEnabled,
                _handoverLeasedBehaviour,_handoverPilotBehaviour] spawn {
                params ["_handoverAircraft","_handoverPilot","_handoverToken","_handoverFeatures",
                    "_handoverPosition","_handoverCombatMode","_handoverGroupCombatMode",
                    "_handoverAttackEnabled","_handoverLeasedBehaviour","_handoverPilotBehaviour"];
                // This is a bounded cleanup lease, not a new Cortex movement profile. Give an
                // aircraft enough time to turn onto a replacement leg, but release immediately on
                // arrival, destruction, token replacement or the hard safety deadline.
                private _deadline=serverTime+([8,100] select (count _handoverPosition >= 2));
                waitUntil {
                    sleep 0.5;
                    isNull _handoverAircraft
                        || {!alive _handoverAircraft}
                        || {(_handoverAircraft getVariable ["Waldo_Cortex_AirHandoverLease",[]]) param [0,""] != _handoverToken}
                        || {serverTime >= _deadline}
                        || {count _handoverPosition >= 2 && {_handoverAircraft distance2D _handoverPosition <= 150}}
                };
                if (isNull _handoverAircraft) exitWith {};
                _handoverAircraft setVariable ["Waldo_Cortex_AirHandoverResult",[
                    serverTime,
                    if (count _handoverPosition >= 2) then {_handoverAircraft distance2D _handoverPosition} else {-1},
                    behaviour _handoverPilot,
                    unitCombatMode _handoverPilot,
                    currentCommand _handoverPilot
                ],true];
                if (local _handoverAircraft) then {
                    [_handoverAircraft,_handoverPilot,_handoverToken,_handoverFeatures,
                        _handoverCombatMode,_handoverGroupCombatMode,_handoverAttackEnabled,
                        _handoverLeasedBehaviour,_handoverPilotBehaviour]
                        call Waldo_fnc_CortexAirHandoverRestoreLocal;
                } else {
                    [_handoverAircraft,_handoverPilot,_handoverToken,_handoverFeatures,
                        _handoverCombatMode,_handoverGroupCombatMode,_handoverAttackEnabled,
                        _handoverLeasedBehaviour,_handoverPilotBehaviour]
                        remoteExecCall ["Waldo_fnc_CortexAirHandoverRestoreLocal",owner _handoverAircraft];
                };
            };
        };
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
    // Capture authored route content rather than currentWaypoint. The engine advances that index as
    // an aircraft flies, which previously looked like a replacement order and cancelled valid runs.
    private _routeSignature=waypoints _group apply {[waypointPosition _x,waypointType _x]};
    _job set ["target",_target]; _job set ["points",_plan get "points"];
    _job set ["pattern",_plan get "pattern"]; _job set ["token",_plan get "token"];
    _job set ["aaPositions",_plan get "aaPositions"];
    _job set ["lateralTurret",_plan getOrDefault ["lateralTurret",false]];
    _job set ["lateralTurretPath",_plan getOrDefault ["lateralTurretPath",[]]];
    _job set ["lateralWeapon",_plan getOrDefault ["lateralWeapon",""]];
    _job set ["standoffWeapon",_plan getOrDefault ["standoffWeapon",""]];
    _job set ["standoffTurret",_plan getOrDefault ["standoffTurret",[]]];
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
private _currentRoute=waypoints _group apply {[waypointPosition _x,waypointType _x]};
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
                _job set ["lateralTurret",_replacement getOrDefault ["lateralTurret",false]];
                _job set ["lateralTurretPath",_replacement getOrDefault ["lateralTurretPath",[]]];
                _job set ["lateralWeapon",_replacement getOrDefault ["lateralWeapon",""]];
                _job set ["standoffWeapon",_replacement getOrDefault ["standoffWeapon",""]];
                _job set ["standoffTurret",_replacement getOrDefault ["standoffTurret",[]]];
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
private _stageDistance=_aircraft distance2D _destination;
private _closestKey="closest"+_stage;
private _stageClosest=(_job getOrDefault [_closestKey,_stageDistance]) min _stageDistance;
_job set [_closestKey,_stageClosest];
private _shots=_aircraft getVariable ["Waldo_Cortex_AirAttackShots",0];
_job set ["shots",_shots];
_aircraft flyInHeight (_job get "altitude");
_aircraft limitSpeed (_job get "speed");
_pilot doMove _destination;
{if (alive _x) then {_x doTarget _target}} forEach crew _aircraft;
if (_stage == "ATTACK") then {
    if ((_job getOrDefault ["pattern",""]) == "STANDOFF") then {
        private _weapon=_job getOrDefault ["standoffWeapon",""];
        private _turret=_job getOrDefault ["standoffTurret",[]];
        // Pilot weapons use the virtual [-1] turret. turretUnit [-1] is not portable across
        // airframes, so bind that path explicitly to the driver retained by the plan.
        private _operator=if (_turret isEqualTo [-1]) then {_pilot} else {_aircraft turretUnit _turret};
        _group reveal [_target,4];
        if (!isNull _operator && {alive _operator}) then {_operator doTarget _target};
        if (_weapon != "") then {_aircraft selectWeaponTurret [_weapon,_turret]};
        private _solution=if (_weapon == "") then {0} else {_aircraft aimedAtTarget [_target,_weapon]};
        _job set ["fireSolution",_solution];
        // fireAtTarget is the engine's weapon-specific solution gate. aimedAtTarget can remain zero
        // for pilot-guided missiles even after the sensor has a valid lock, so treating that generic
        // scalar as a second hard gate prevented every AGM release. Failed requests retry at 1 Hz;
        // successful release is still proved by the Fired handler before the run can advance.
        if (!isNull _operator && {alive _operator}
            && {serverTime >= (_job getOrDefault ["nextStandoffFire",0])}) then {
            private _fired=_aircraft fireAtTarget [_target,_weapon];
            _job set ["nextStandoffFire",serverTime+([1,4] select _fired)];
        };
    } else {
        if ((_job getOrDefault ["pattern",""]) == "LATERAL") then {
            private _operator=_aircraft turretUnit (_job getOrDefault ["lateralTurretPath",[]]);
            if (!isNull _operator && {alive _operator}) then {_operator doTarget _target; _operator doFire _target};
        } else {
        {if (alive _x) then {_x doFire _target}} forEach crew _aircraft;
        };
    };
};

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
    ["HELICOPTER","PLANE"] select _isPlane,_job getOrDefault ["lateralTurret",false]
    ,_job getOrDefault ["standoffWeapon",""],_job getOrDefault ["standoffTurret",[]],
    _job getOrDefault ["fireSolution",0]
],true];

private _attackShots=_shots-(_job getOrDefault ["attackShotBaseline",0]);
if ((_job getOrDefault ["pattern",""]) == "STANDOFF" && {_stage == "ATTACK"} && {_attackShots <= 0}
    && {serverTime > (_job getOrDefault ["attackStartedAt",serverTime])+25}) exitWith {
    _aircraft setVariable ["Waldo_Cortex_AirStandoffBlockedUntil",serverTime+90];
    ["NO_FIRE_SOLUTION",true] call _finish
};
if (serverTime > (_job get "deadline")) exitWith {["STAGE_TIMEOUT"] call _finish};
private _captureRadius=if (_isPlane) then {700} else {450};
private _stagePassed=_stageClosest <= _captureRadius && {_stageDistance >= _stageClosest+([120,75] select !_isPlane)};
// Discovery can acquire a fast jet after it has already flown past the nominal ingress point.
// Continue into the firing leg when that point is physically behind the jet; ordering a turn back
// creates the observed pre-run loop and can never improve a fixed-wing attack solution.
private _ingressBehind=_isPlane && {_stage == "INGRESS"} && {_stageDistance <= 2000}
    && {(velocity _aircraft) vectorDotProduct (_destination vectorDiff getPosATL _aircraft) <= 0};
if (_stage == "EGRESS" && {(_stageDistance <= _captureRadius || {_stagePassed})}
    && {_aircraft distance2D (_points select 1) >= 400}) exitWith {["COMPLETE",true] call _finish};
private _egressTravel=if (_stage == "EGRESS") then {
    _aircraft distance2D (_job getOrDefault ["egressStartPosition",getPosATL _aircraft])
} else {0};
private _awayFromTarget=(velocity _aircraft) vectorDotProduct ((getPosATL _aircraft) vectorDiff (getPosATL _target)) > 0;
// Fast fixed-wing aircraft do not reliably capture an exact doMove point after a weapon release.
// Physical travel away from the target is an equally valid egress and avoids holding the aircraft
// under Cortex until a timeout after the attack has already succeeded.
if (_stage == "EGRESS" && {_egressTravel >= ([350,700] select _isPlane)} && {_awayFromTarget}) exitWith {["COMPLETE",true] call _finish};
switch _stage do {
    case "INGRESS": {
        // Aircraft rarely hit an exact doMove coordinate, especially at fixed-wing turn radius.
        // Accept entering or physically passing a bounded capture area; elapsed time alone still
        // cannot advance the state.
        if (_stageDistance <= _captureRadius || {_stagePassed} || {_ingressBehind}) then {
            [_group,_job,"ATTACK","INGRESS_ARRIVAL"] call Waldo_fnc_CortexDrillSetStage;
            _job set ["deadline",serverTime+50];
            _job set ["attackStartedAt",serverTime];
            _job set ["attackShotBaseline",_shots];
        };
    };
    case "ATTACK": {
        if (_attackShots > 0 && {(_stageDistance <= _captureRadius || {_stagePassed})}) then {
            [_group,_job,"EGRESS","ACTUAL_FIRE"] call Waldo_fnc_CortexDrillSetStage;
            _job set ["egressStartPosition",getPosATL _aircraft];
            _job set ["egressStartedAt",serverTime];
            _job set ["deadline",serverTime+75];
        };
    };
    case "EGRESS": {};
};
0.5
