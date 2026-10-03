/*
 * Author: WaldoTheWarfighter
 * Executes one finite Cortex aircraft attack as ingress, attack and egress phases. Against an
 * airborne hostile these phases mean intercept, engage and disengage/rejoin: the first two
 * destinations lead the contact's measured velocity while egress remains finite and returns the
 * aircraft to its unchanged authored route. This provides responsive air-to-air contact handling
 * without pretending that fixed script geometry implements full basic fighter manoeuvring.
 * It flies physical route legs, presents the live target only to the retained weapon operator, records real
 * non-countermeasure shots and requests finite approach/departure countermeasures. Every pattern
 * uses a compatible loaded weapon and opens fire only inside a live range, alignment and engine aim
 * envelope. The engine remains the flight controller; Cortex issues one native move per finite leg
 * and leaves the engine's attack delegation enabled so ordinary combat and turret tracking continue.
 * Each leg is issued once as a group-level native movement order. Progress is measured toward
 * that leg, so broad turns are accepted while hovering, local circles and repeated replans cannot keep
 * an attack alive. Non-progress in any phase aborts rather than fabricating a transition; a validly
 * released attack exits after physically capturing or passing its firing leg.
 * A lack of travel, solution or fire aborts the run; elapsed time alone
 * never completes it. Zeus priority, locality loss,
 * eligibility changes or a changed curator waypoint end the lease immediately without restoring an
 * obsolete order. A successful run hands the aircraft back toward its unchanged original waypoint.
 * During direct Zeus handover, cleanup clears this attack's target commands, restores the exact native
 * attack policy, selects the authenticated curator waypoint and returns immediately. It creates no
 * timed guard, replacement route, pilot movement order or delayed semantic restoration.
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
        if (!isNull _finishGroup) then {_finishGroup enableAttack (_job getOrDefault ["previousAttackEnabled",true])};
        private _finishPilot=driver _aircraft;
        if (!isNull _finishPilot && {alive _finishPilot}) then {
            {_finishPilot enableAI _x} forEach (_job getOrDefault ["lateralPilotFeatures",[]]);
        };
        // Direct Zeus input owns the aircraft immediately. Retire only Cortex target commands,
        // restore the native attack policy, reselect the authenticated waypoint and leave. A timed
        // guard was observed to suppress the new route for 90 seconds and violated this boundary.
        if (_reason in ["CONTROL_RELEASED","AUTHORED_ROUTE_CHANGED"]) then {
            _aircraft flyInHeight (((getPosATL _aircraft) select 2) max 25);
            {if (alive _x && {!isPlayer _x}) then {_x doTarget objNull; _x doWatch objNull}}
                forEach crew _aircraft;
            (crew _aircraft) commandTarget objNull;
            private _handoverPilot=driver _aircraft;
            private _handoverGroup=group _handoverPilot;
            private _snapshot=_handoverGroup getVariable ["Waldo_Cortex_ZeusOrderSnapshot",[]];
            private _handoverPosition=+(_snapshot param [1,[]]);
            private _authoredBehaviour=_snapshot param [2,""];
            private _authoredSpeed=_snapshot param [3,""];
            private _authoredWaypointIndex=_snapshot param [5,currentWaypoint _handoverGroup];
            if (_authoredBehaviour in ["CARELESS","SAFE","AWARE","COMBAT","STEALTH"]) then {
                _handoverGroup setBehaviourStrong _authoredBehaviour;
            };
            if (_authoredSpeed in ["LIMITED","NORMAL","FULL"]) then {
                _handoverGroup setSpeedMode _authoredSpeed;
            };
            if (_authoredWaypointIndex >= 0 && {_authoredWaypointIndex < count waypoints _handoverGroup}) then {
                _handoverGroup setCurrentWaypoint [_handoverGroup,_authoredWaypointIndex];
            };
            (crew _aircraft) doFollow leader _handoverGroup;
            _aircraft setVariable ["Waldo_Cortex_AirHandoverLease",nil,true];
            _aircraft setVariable ["Waldo_Cortex_AirHandoverRecovery",nil,true];
            _aircraft setVariable ["Waldo_Cortex_AirHandoverResult",[
                serverTime,if (count _handoverPosition >= 2) then {_aircraft distance2D _handoverPosition} else {-1},
                behaviour _handoverPilot,unitCombatMode _handoverPilot,currentCommand _handoverPilot,
                "ZEUS_IMMEDIATE_HANDOVER",expectedDestination _handoverPilot
            ],true];
        };
        if (_resume) then {
            private _resumePosition=_job getOrDefault ["resumePosition",[]];
            private _resumeWaypointIndex=_job getOrDefault ["resumeWaypointIndex",-1];
            private _resumeGroup=group driver _aircraft;
            if (count _resumePosition >= 2 && {!([_resumeGroup] call Waldo_fnc_CortexZeusHeld)}) then {
                (crew _aircraft) doFollow leader _resumeGroup;
                if (_resumeWaypointIndex >= 0 && {_resumeWaypointIndex < count waypoints _resumeGroup}
                    && {waypointPosition [_resumeGroup,_resumeWaypointIndex] distance2D _resumePosition <= 2}) then {
                    _resumeGroup setCurrentWaypoint [_resumeGroup,_resumeWaypointIndex];
                };
            };
        };
    };
    _aircraft setVariable ["Waldo_Cortex_AirAttackOutcome",[_reason,serverTime,_job getOrDefault ["pattern",""],_job getOrDefault ["shots",0]],true];
    _aircraft setVariable ["Waldo_Cortex_AirAttackPlan",nil,true];
    _aircraft setVariable ["Waldo_Cortex_AirFireSolution",nil,true];
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
    if ((_plan get "pattern") == "LATERAL") then {
        private _lateralPilotFeatures=["AUTOCOMBAT","TARGET","AUTOTARGET"] select {_pilot checkAIFeature _x};
        _job set ["lateralPilotFeatures",_lateralPilotFeatures];
        {_pilot disableAI _x} forEach _lateralPilotFeatures;
        _pilot doTarget objNull;
        _pilot doWatch objNull;
    };
    _job set ["aaPositions",_plan get "aaPositions"];
    _job set ["lateralTurret",_plan getOrDefault ["lateralTurret",false]];
    _job set ["lateralTurretPath",_plan getOrDefault ["lateralTurretPath",[]]];
    _job set ["lateralWeapon",_plan getOrDefault ["lateralWeapon",""]];
    _job set ["lateralSimulation",_plan getOrDefault ["lateralSimulation",""]];
    _job set ["standoffWeapon",_plan getOrDefault ["standoffWeapon",""]];
    _job set ["standoffTurret",_plan getOrDefault ["standoffTurret",[]]];
    _job set ["standoffSimulation",_plan getOrDefault ["standoffSimulation",""]];
    _job set ["groundWeapon",_plan getOrDefault ["groundWeapon",""]];
    _job set ["groundTurret",_plan getOrDefault ["groundTurret",[]]];
    _job set ["groundSimulation",_plan getOrDefault ["groundSimulation",""]];
    _job set ["airToAir",_plan getOrDefault ["airToAir",false]];
    _job set ["airWeapon",_plan getOrDefault ["airWeapon",""]];
    _job set ["airWeaponTurret",_plan getOrDefault ["airWeaponTurret",[]]];
    _job set ["airSimulation",_plan getOrDefault ["airSimulation",""]];
    _job set ["selectedWeapon",_plan getOrDefault ["selectedWeapon",""]];
    _job set ["selectedTurret",_plan getOrDefault ["selectedTurret",[]]];
    _job set ["selectedSimulation",_plan getOrDefault ["selectedSimulation",""]];
    _job set ["selectedWeaponClass",_plan getOrDefault ["selectedWeaponClass",""]];
    _job set ["selectedMagazine",_plan getOrDefault ["selectedMagazine",""]];
    _job set ["altitude",_plan get "altitude"]; _job set ["speed",_plan get "speed"];
    _job set ["stageAltitudes",_plan getOrDefault ["stageAltitudes",[_plan get "altitude",_plan get "altitude",_plan get "altitude"]]];
    _job set ["stageSpeeds",_plan getOrDefault ["stageSpeeds",[_plan get "speed",_plan get "speed",_plan get "speed"]]];
    _job set ["captureRadii",_plan getOrDefault ["captureRadii",[450,450,450]]];
    _job set ["attackMinimum",_plan getOrDefault ["attackMinimum",2]];
    _job set ["type","AIR_ATTACK"]; _job set ["stage",""]; _job set ["deadline",serverTime+75]; _job set ["shots",0];
    _job set ["origin",getPosATL _aircraft]; _job set ["resumePosition",_resumePosition];
    _job set ["resumeWaypointIndex",_waypointIndex]; _job set ["routeSignature",_routeSignature];
    _job set ["previousAttackEnabled",attackEnabled _group];
    // Record the authored policy for exact cleanup, but do not disable it. Disabling group attacks
    // prevented native pilots and turrets from building a valid solution while Cortex waited to fire.
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
if (isNull _target || {!alive _target}) exitWith {
    [["TARGET_LOST","TARGET_DESTROYED"] select ((_job getOrDefault ["shots",0]) > 0),true] call _finish
};
if ((getPosATL _aircraft select 2) < 25) exitWith {["GROUND_CLEARANCE"] call _finish};
private _points=_job get "points";
private _stageIndex=["INGRESS","ATTACK","EGRESS"] find _stage;
if (_stageIndex < 0) exitWith {["BAD_STAGE"] call _finish};
private _destination=_points select _stageIndex;
// Air contacts do not remain at the point captured when the plan was built. Refresh only the
// intercept and engagement points from current target velocity; disengagement stays immutable so
// the lease has a real end and cannot orbit indefinitely.
if (_job getOrDefault ["airToAir",false] && {_stage in ["INGRESS","ATTACK"]}) then {
    private _leadSeconds=[16,5] select (_stage == "ATTACK");
    _destination=(getPosATL _target) vectorAdd ((velocity _target) vectorMultiply _leadSeconds);
    _destination set [2,(_job getOrDefault ["stageAltitudes",[_job get "altitude",_job get "altitude",_job get "altitude"]]) select _stageIndex];
    _points set [_stageIndex,_destination];
    _job set ["points",_points];
};
private _stageDistance=_aircraft distance2D _destination;
private _closestKey="closest"+_stage;
private _stageClosest=(_job getOrDefault [_closestKey,_stageDistance]) min _stageDistance;
_job set [_closestKey,_stageClosest];
private _shots=_aircraft getVariable ["Waldo_Cortex_AirAttackShots",0];
_job set ["shots",_shots];
private _stageAltitudes=_job getOrDefault ["stageAltitudes",[_job get "altitude",_job get "altitude",_job get "altitude"]];
private _stageSpeeds=_job getOrDefault ["stageSpeeds",[_job get "speed",_job get "speed",_job get "speed"]];
// A durable movement order is cheaper and smoother than restarting the engine flight planner on
// every scheduler tick. Refresh only on a real stage transition, or when a moving airborne contact
// has displaced far enough to invalidate the previous intercept destination.
private _commandedStage=_job getOrDefault ["commandedStage",""];
private _commandedDestination=_job getOrDefault ["commandedDestination",[]];
private _refreshIntercept=_job getOrDefault ["airToAir",false]
    && {count _commandedDestination >= 2}
    && {_commandedDestination distance2D _destination >= ([800,350] select !_isPlane)}
    && {serverTime >= (_job getOrDefault ["commandedAt",0])+6};
if (_commandedStage != _stage || {_refreshIntercept}) then {
    _aircraft flyInHeight (_stageAltitudes select _stageIndex);
    _aircraft limitSpeed (_stageSpeeds select _stageIndex);
    // An individual pilot doMove/commandMove competes with the crew group's planner and was the
    // root of the observed stop/start circles. One group-level move gives the native flight FSM a
    // single coherent leg without an update loop fighting it. The unchanged waypoint is reselected
    // after the finite lease ends.
    (crew _aircraft) doFollow leader _group;
    _group move _destination;
    _job set ["commandedStage",_stage];
    _job set ["commandedDestination",+_destination];
    _job set ["commandedAt",serverTime];
    _job set ["stageBestDistance",_stageDistance];
    _job set ["stageProgressAt",serverTime];
};

// Measure useful approach to the active leg rather than raw displacement. Orbiting 300 metres and
// returning to the same range is not progress. A single threshold update is cheap and lets the
// engine use a broad turn without Cortex continuously rewriting its path.
private _stageBest=_job getOrDefault ["stageBestDistance",_stageDistance];
if (_stageDistance <= _stageBest-40) then {
    _stageBest=_stageDistance;
    _job set ["stageBestDistance",_stageBest];
    _job set ["stageProgressAt",serverTime];
};
private _routeStalled=serverTime >= (_job getOrDefault ["stageProgressAt",serverTime])+([35,24] select !_isPlane);
if (_stage == "ATTACK") then {
    private _pattern=_job getOrDefault ["pattern",""];
    private _airContact=_job getOrDefault ["airToAir",false];
    private _weapon=_job getOrDefault ["selectedWeapon",""];
    private _turret=_job getOrDefault ["selectedTurret",[]];
    private _simulation=_job getOrDefault ["selectedSimulation",""];
    private _weaponClass=_job getOrDefault ["selectedWeaponClass",""];
    private _operator=if (_turret isEqualTo [-1]) then {_pilot} else {_aircraft turretUnit _turret};
    if (!isNull _operator && {alive _operator} && {!(_job getOrDefault ["targetCommanded",false])}) then {
        _operator doWatch _target;
        _operator doTarget _target;
        _operator commandTarget _target;
        _job set ["targetCommanded",true];
    };
    if (_weapon != "") then {_aircraft selectWeaponTurret [_weapon,_turret]};
    private _range=_aircraft distance _target;
    private _weaponVector=if (_weapon == "") then {[0,0,0]} else {_aircraft weaponDirection _weapon};
    private _targetVector=(aimPos _target) vectorDiff (getPosASL _aircraft);
    private _alignment=if (vectorMagnitude _weaponVector > 0.01 && {vectorMagnitude _targetVector > 0.01}) then {
        (vectorNormalized _weaponVector) vectorDotProduct (vectorNormalized _targetVector)
    } else {-1};
    private _aimed=if (_weapon == "") then {0} else {_aircraft aimedAtTarget [_target,_weapon]};
    private _loaded=(magazinesAllTurrets _aircraft) findIf {
        (_x select 1) isEqualTo _turret && {(_x select 2) > 0}
            && {(_x select 0) in compatibleMagazines _weapon}
    } >= 0;
    private _envelope=switch _weaponClass do {
        case "GUN": {if (_airContact) then {[100,1800,0.995]} else {[120,1800,0.992]}};
        case "ROCKET": {[450,3000,0.998]};
        case "GUIDED": {if (_airContact) then {[700,7000,0.985]} else {[900,6500,0.985]}};
        case "BOMB": {[900,5000,0.975]};
        default {[0,0,1]};
    };
    _envelope params ["_minimumRange","_maximumRange","_minimumAlignment"];
    private _guided=_weaponClass == "GUIDED";
    private _bomb=_weaponClass == "BOMB";
    private _airForward=vectorDir _aircraft;
    private _horizontalTarget=+_targetVector;
    _horizontalTarget set [2,0];
    private _horizontalForward=+_airForward;
    _horizontalForward set [2,0];
    private _forwardAlignment=if (vectorMagnitude _horizontalTarget > 0.01 && {vectorMagnitude _horizontalForward > 0.01}) then {
        (vectorNormalized _horizontalForward) vectorDotProduct (vectorNormalized _horizontalTarget)
    } else {-1};
    private _deliveryAngle=acos ((_alignment max -1) min 1);
    private _minimumAim=if (_guided) then {0.45} else {if (_bomb) then {0.15} else {0.05}};
    private _closing=_forwardAlignment > 0.35;
    private _validSolution=_loaded && {!isNull _operator} && {alive _operator}
        && {_range >= _minimumRange} && {_range <= _maximumRange}
        && {_closing} && {_alignment >= _minimumAlignment}
        && {!_bomb || {(getPosATL _aircraft select 2) >= 350}}
        && {_aimed >= _minimumAim};
    private _solution=[_validSolution,_range,_alignment,_aimed,_weapon,_simulation,_loaded,
        _weaponClass,_envelope,_deliveryAngle,_forwardAlignment,_minimumAim,_closing];
    _job set ["fireSolution",_solution];
    _aircraft setVariable ["Waldo_Cortex_AirFireSolution",_solution,true];
    if (_validSolution && {serverTime >= (_job getOrDefault ["nextWeaponFire",0])}) then {
        private _fired=_aircraft fireAtTarget [_target,_weapon];
        _job set ["nextWeaponFire",serverTime+([0.7+random 0.8,2+random 1.5] select _fired)];
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
    _job getOrDefault ["fireSolution",[]],
    _job getOrDefault ["stageAltitudes",[]],_job getOrDefault ["stageSpeeds",[]],
    _job getOrDefault ["captureRadii",[]],_job getOrDefault ["attackMinimum",0],
    +(_job getOrDefault ["points",[]]),
    _job getOrDefault ["selectedWeapon",""],_job getOrDefault ["selectedSimulation",""],
    _job getOrDefault ["selectedTurret",[]],_job getOrDefault ["selectedWeaponClass",""],
    _job getOrDefault ["selectedMagazine",""]
],true];

private _attackShots=_shots-(_job getOrDefault ["attackShotBaseline",0]);
if ((_job getOrDefault ["pattern",""]) == "STANDOFF" && {_stage == "ATTACK"} && {_attackShots <= 0}
    && {serverTime > (_job getOrDefault ["attackStartedAt",serverTime])+25}) exitWith {
    _aircraft setVariable ["Waldo_Cortex_AirStandoffBlockedUntil",serverTime+90];
    ["NO_FIRE_SOLUTION",true] call _finish
};
if (serverTime > (_job get "deadline")) exitWith {["STAGE_TIMEOUT"] call _finish};
private _captureRadii=_job getOrDefault ["captureRadii",[if (_isPlane) then {700} else {450},if (_isPlane) then {700} else {450},if (_isPlane) then {700} else {450}]];
private _captureRadius=_captureRadii select _stageIndex;
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
if (_stage == "EGRESS" && {_routeStalled}) exitWith {["EGRESS_NONPROGRESS",true] call _finish};
if (_stage in ["INGRESS","ATTACK"] && {_routeStalled}) exitWith {
    [["INGRESS_NONPROGRESS","ATTACK_NONPROGRESS"] select (_stage == "ATTACK"),true] call _finish
};
switch _stage do {
    case "INGRESS": {
        // Aircraft rarely hit an exact doMove coordinate, especially at fixed-wing turn radius.
        // Accept entering or physically passing a bounded capture area; elapsed time alone still
        // cannot advance the state.
        if (_stageDistance <= _captureRadius || {_stagePassed} || {_ingressBehind}) then {
            [_group,_job,"ATTACK","INGRESS_ARRIVAL"] call Waldo_fnc_CortexDrillSetStage;
            _job set ["commandedStage",""];
            _job set ["deadline",serverTime+50];
            _job set ["attackStartedAt",serverTime];
            _job set ["attackShotBaseline",_shots];
        };
    };
    case "ATTACK": {
        private _attackDwell=serverTime-(_job getOrDefault ["attackStartedAt",serverTime]);
        private _deliveryComplete=(_job getOrDefault ["selectedWeaponClass",""]) in ["GUIDED","BOMB"]
            || {_stageDistance <= _captureRadius || {_stagePassed}};
        if (_attackShots > 0 && {_attackDwell >= (_job getOrDefault ["attackMinimum",2])}
            && {_deliveryComplete}) then {
            [_group,_job,"EGRESS","ACTUAL_FIRE"] call Waldo_fnc_CortexDrillSetStage;
            _job set ["commandedStage",""];
            _job set ["egressStartPosition",getPosATL _aircraft];
            _job set ["egressStartedAt",serverTime];
            _job set ["deadline",serverTime+75];
        };
    };
    case "EGRESS": {};
};
0.5
