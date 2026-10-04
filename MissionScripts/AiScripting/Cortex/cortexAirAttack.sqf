/*
 * Author: WaldoTheWarfighter
 * Executes one finite Cortex aircraft attack as ingress, attack and egress phases. Against an
 * airborne hostile these phases mean intercept, engage and disengage/rejoin: the first two
 * destinations lead the contact's measured velocity while egress remains finite and returns the
 * aircraft to its unchanged authored route. This provides responsive air-to-air contact handling
 * without pretending that fixed script geometry implements full basic fighter manoeuvring.
 * It flies physical route legs, presents the live target only to the retained weapon operator, records real
 * non-countermeasure shots and requests finite approach/departure countermeasures. Every pattern
 * uses a compatible loaded weapon and opens fire only inside a live range and alignment envelope.
 * On attack entry the selected living operator receives one native reveal/target instruction;
 * Cortex then asks that operator to release the selected weapon only after live range, route,
 * ammunition and seeker checks pass. This joins route geometry to the engine's weapon FSM instead of treating an ATTACK
 * label as an attack. The engine remains the flight controller; Cortex owns one named temporary
 * waypoint for the finite lease and one terrain-relative altitude hint when each leg changes. A
 * fixed-wing ground ATTACK leg retains the target-crossing MOVE route throughout delivery; the
 * selected operator receives repeated native fire-control requests inside a broad delivery basket;
 * independently aimed turrets retain native fire control. This keeps the aircraft on its useful
 * approach instead of replacing it with an unreliable spatial DESTROY search at the release point,
 * and lets the engine solve the aircraft's real muzzle, pylon and momentum rather than predicting
 * those from a generic weapon direction. Air intercepts attach immediately because the contact itself is
 * moving. Egress, abort and Zeus interruption detach and delete the order. The real hostile remains the
 * fire-control, guidance and damage/result target; Cortex does not insert a friendly laser proxy
 * that can invalidate native seeker guidance.
 * Each leg updates the one Cortex-owned native waypoint once. Progress is measured toward
 * that leg, so broad turns are accepted while hovering, local circles and repeated replans cannot keep
 * an attack alive. Non-progress in any phase aborts rather than fabricating a transition; a validly
 * released attack exits after a bounded weapon-class delivery: one bomb, a short guided/rocket
 * salvo or a gun burst. It never waits indefinitely for a single engine fire callback.
 * A lack of travel, solution or fire aborts the run; elapsed time alone
 * never completes it. Zeus priority, locality loss, explicit exclusions, runtime disablement or a
 * changed curator waypoint end the lease immediately. Cleanup deletes only that named temporary
 * waypoint. A successful run hands the aircraft back toward its unchanged original waypoint.
 * During direct Zeus handover, cleanup clears this attack's target commands, restores the native
 * attack policy, selects the authenticated curator waypoint and returns immediately. It creates no
 * timed guard, replacement route, pilot movement/behaviour order or delayed semantic restoration.
 * Locality/authority: aircraft owner only. Public summary/outcome arrays support Zeus diagnostics;
 * movement commands and Fired handlers remain owner-local.
 * Repeat/JIP: one job per aircraft. Cleanup removes the owned handler,
 * named waypoint, speed limit and public plan; a short owner-local re-attack interval prevents immediate duplicate runs.
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
    // A kill completes the weapon phase, not the flight lease. Preserve that semantic result after
    // the aircraft has flown its real egress instead of ending control over the target wreck.
    if (_reason == "COMPLETE" && {_job getOrDefault ["targetDestroyed",false]}) then {
        _reason="TARGET_DESTROYED";
    };
    private _finishGroup=group driver _aircraft;
    if (!isNull _finishGroup && {"token" in _job}) then {[_finishGroup,_job,"ENDED",_reason] call Waldo_fnc_CortexDrillSetStage};
    private _handler=_job getOrDefault ["firedHandler",-1];
    if (_handler >= 0) then {_aircraft removeEventHandler ["Fired",_handler]};
    private _guidanceTarget=_job getOrDefault ["guidanceTarget",objNull];
    if (!isNull _guidanceTarget) then {deleteVehicle _guidanceTarget};
    if (local _aircraft) then {
        _aircraft limitSpeed -1;
        // Remove exactly the lease-owned waypoint before selecting any authored route. Searching
        // by name remains correct when Zeus added or removed other waypoints and shifted indices.
        private _ownedWaypointName=_job getOrDefault ["ownedWaypointName",""];
        if (!isNull _finishGroup && {_ownedWaypointName != ""}) then {
            private _ownedWaypointIndex=(waypoints _finishGroup) findIf {waypointName _x == _ownedWaypointName};
            if (_ownedWaypointIndex >= 0) then {deleteWaypoint ((waypoints _finishGroup) select _ownedWaypointIndex)};
        };
        if (!isNull _finishGroup) then {_finishGroup enableAttack (_job getOrDefault ["previousAttackEnabled",true])};
        private _finishPilot=driver _aircraft;
        if (!isNull _finishPilot && {alive _finishPilot}) then {
            {_finishPilot enableAI _x} forEach (_job getOrDefault ["lateralPilotFeatures",[]]);
        };
        // Direct Zeus input owns the aircraft immediately. Retire only Cortex target commands,
        // restore the native attack policy, reselect the authenticated waypoint and leave. A timed
        // guard was observed to suppress the new route for 90 seconds and violated this boundary.
        if (_reason in ["CONTROL_RELEASED","AUTHORED_ROUTE_CHANGED"]) then {
            {if (alive _x && {!isPlayer _x}) then {_x doTarget objNull; _x doWatch objNull}}
                forEach crew _aircraft;
            (crew _aircraft) commandTarget objNull;
            private _handoverPilot=driver _aircraft;
            private _handoverGroup=group _handoverPilot;
            private _snapshot=_handoverGroup getVariable ["Waldo_Cortex_ZeusOrderSnapshot",[]];
            private _handoverPosition=+(_snapshot param [1,[]]);
            private _handoverWaypoints=waypoints _handoverGroup;
            private _authoredWaypointOffset=_handoverWaypoints findIf {
                count _handoverPosition >= 2 && {waypointPosition _x distance2D _handoverPosition <= 2}
            };
            // Re-select the exact curator waypoint and immediately apply its own movement semantics.
            // This is a one-time replay of authenticated Zeus intent, not a Cortex route. Without
            // it Arma retained the pre-attack RED/COMBAT state and ignored AWARE/FULL movement.
            // Use the actual waypoint handle:
            // deleting the Cortex waypoint leaves engine-ID gaps, so a findIf list offset is not a
            // valid waypoint ID and previously selected the deleted slot/waypoint zero.
            private _authoredWaypoint=if (_authoredWaypointOffset >= 0) then {
                _handoverWaypoints select _authoredWaypointOffset
            } else {
                [_handoverGroup,_snapshot param [5,currentWaypoint _handoverGroup]]
            };
            if ((_authoredWaypoint select 1) >= 0) then {
                _handoverGroup setCurrentWaypoint _authoredWaypoint;
                private _authoredBehaviour=_snapshot param [2,waypointBehaviour _authoredWaypoint];
                private _authoredSpeed=_snapshot param [3,waypointSpeed _authoredWaypoint];
                private _authoredCombatMode=_snapshot param [6,waypointCombatMode _authoredWaypoint];
                if (_authoredBehaviour != "NO CHANGE") then {_handoverGroup setBehaviourStrong _authoredBehaviour};
                if (_authoredSpeed != "UNCHANGED") then {_handoverGroup setSpeedMode _authoredSpeed};
                if (_authoredCombatMode != "NO CHANGE") then {_handoverGroup setCombatMode _authoredCombatMode};
            };
            // flyInHeight persists after a waypoint changes. Restore it once from the curator's
            // selected destination so a helicopter does not hover at Cortex's attack altitude while
            // Zeus is already waiting at a low waypoint. Cortex issues no later correction.
            if (count _handoverPosition >= 3) then {
                _aircraft flyInHeight ([((_handoverPosition select 2) max 40),300] select (_aircraft isKindOf "Plane"));
            };
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
            private _resumeGroup=group driver _aircraft;
            private _resumeWaypointIndex=(waypoints _resumeGroup) findIf {
                waypointPosition _x distance2D _resumePosition <= 2
            };
            if (count _resumePosition >= 2 && {!([_resumeGroup] call Waldo_fnc_CortexZeusHeld)}) then {
                (crew _aircraft) doFollow leader _resumeGroup;
                if (_resumeWaypointIndex >= 0 && {_resumeWaypointIndex < count waypoints _resumeGroup}
                    && {waypointPosition [_resumeGroup,_resumeWaypointIndex] distance2D _resumePosition <= 2}) then {
                    _resumeGroup setCurrentWaypoint [_resumeGroup,_resumeWaypointIndex];
                };
            };
        };
    };
    _aircraft setVariable ["Waldo_Cortex_AirAttackOutcome",[
        _reason,serverTime,_job getOrDefault ["pattern",""],_job getOrDefault ["shots",0],
        _job getOrDefault ["releaseDetail",[]]
    ],true];
    // Prevent immediate rediscovery of the same known contact after a finite run. This is a short
    // re-attack interval, not a movement controller or Zeus order guard.
    _aircraft setVariable ["Waldo_Cortex_AirAttackBlockedUntil",serverTime+(
        if (_reason in ["CONTROL_RELEASED","AUTHORED_ROUTE_CHANGED"]) then {5}
        else {if (_reason in ["COMPLETE","TARGET_DESTROYED"]) then {20}
            else {if (_reason == "DELIVERY_SAFETY_FLOOR") then {120} else {35}}}
    )];
    _aircraft setVariable ["Waldo_Cortex_AirAttackPlan",nil,true];
    _aircraft setVariable ["Waldo_Cortex_AirFireSolution",nil,true];
    _aircraft setVariable ["Waldo_Cortex_AirAttackTarget",nil];
    _aircraft setVariable ["Waldo_Cortex_AirAttackGuidedWeapon",nil];
    _aircraft setVariable ["Waldo_Cortex_AirAttackGuidanceTarget",nil];
    _aircraft setVariable ["Waldo_Cortex_AirAttackJob",nil];
    _aircraft setVariable ["Waldo_Cortex_AirAttackToken",nil];
    -1
};
private _pilot=driver _aircraft;
private _group=group _pilot;
private _stage=_job getOrDefault ["stage",""];
// Generic eligibility is a start gate. Re-evaluating every broad filter during a finite owned run
// allowed a transient locality/filter marker to cancel a valid attack just before weapon release.
// Runtime master/feature changes, locality, explicit exclusions and Zeus still release immediately.
private _explicitlyExcluded=_group getVariable ["Waldo_AI_ExternalControl",false]
    || {"ALL" in (_group getVariable ["Waldo_AIPass_DisabledFeatures",[]])}
    || {_group getVariable ["Waldo_AI_Exclude",false]}
    || {_group getVariable ["Waldo_AIPass_Exclude",false]};
private _allowed=local _aircraft && {alive _aircraft} && {!isNull _pilot} && {alive _pilot} && {!isPlayer _pilot}
    && {!unitIsUAV _aircraft} && {missionNamespace getVariable ["Waldo_AIPass_Active",false]}
    && {!([] call Waldo_fnc_CortexIsPaused)}
    && {!([_group] call Waldo_fnc_CortexZeusHeld)}
    && {[_group,"Waldo_Cortex_AirAttack_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
    && {!_explicitlyExcluded}
    && {_stage != "" || {[_group] call Waldo_fnc_CortexIsEligible}};
if (!_allowed) exitWith {
    // Preserve the exact authority/control gate which ended the run. Without this, locality loss,
    // a curator interruption and an explicit exclusion all appeared as the same opaque failure in
    // the WMP diagnostics and audit overlay.
    _job set ["releaseDetail",[
        "local",local _aircraft,"aircraftAlive",alive _aircraft,"pilotAlive",!isNull _pilot && {alive _pilot},
        "runtime",missionNamespace getVariable ["Waldo_AIPass_Active",false],
        "paused",[] call Waldo_fnc_CortexIsPaused,"zeus",[_group] call Waldo_fnc_CortexZeusHeld,
        "feature",[_group,"Waldo_Cortex_AirAttack_Enable",true] call Waldo_fnc_CortexFeatureEnabled,
        "excluded",_explicitlyExcluded,"stage",_stage,"vehicleOwner",owner _aircraft,"groupOwner",groupOwner _group
    ]];
    ["CONTROL_RELEASED"] call _finish
};
private _isPlane=_aircraft isKindOf "Plane";
// A helicopter may validly begin an attack from a hover. Planes still need enough energy to enter a
// finite run; accepting a stationary plane would make its own spawn/ground state look like tactics.
if (isTouchingGround _aircraft || {_isPlane && {speed _aircraft < 40}} || {combatMode _group in ["BLUE","GREEN"]}) exitWith {["NOT_ATTACKING"] call _finish};

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
    // Keep the real hostile as both the semantic and engine fire-control target. An attached laser
    // proxy gave fireAtTarget a friendly-side object and missiles flew their launch vector without
    // useful guidance. The Fired handler reinforces this exact hostile on guided projectiles.
    private _guidanceTarget=objNull;
    _job set ["guidanceTarget",_guidanceTarget];
    _job set ["fireTarget",_target];
    _job set ["altitude",_plan get "altitude"]; _job set ["speed",_plan get "speed"];
    _job set ["stageAltitudes",_plan getOrDefault ["stageAltitudes",[_plan get "altitude",_plan get "altitude",_plan get "altitude"]]];
    _job set ["stageSpeeds",_plan getOrDefault ["stageSpeeds",[_plan get "speed",_plan get "speed",_plan get "speed"]]];
    _job set ["captureRadii",_plan getOrDefault ["captureRadii",[450,450,450]]];
    _job set ["attackMinimum",_plan getOrDefault ["attackMinimum",2]];
    _job set ["terrainLift",_plan getOrDefault ["terrainLift",0]];
    _job set ["terrainClearanceMinimum",_plan getOrDefault ["terrainClearanceMinimum",0]];
    _job set ["terrainSampleCount",_plan getOrDefault ["terrainSampleCount",0]];
    _job set ["terrainCorridor",_plan getOrDefault ["terrainCorridor",0]];
    _job set ["targetPosition",+(_plan getOrDefault ["targetPosition",getPosATL _target])];
    _job set ["type","AIR_ATTACK"]; _job set ["stage",""]; _job set ["deadline",serverTime+75]; _job set ["shots",0];
    _job set ["origin",getPosATL _aircraft]; _job set ["resumePosition",_resumePosition];
    _job set ["resumeWaypointIndex",_waypointIndex]; _job set ["routeSignature",_routeSignature];
    _job set ["ownedWaypointName",format ["WMP_CORTEX_AIR_%1",_plan get "token"]];
    _job set ["previousAttackEnabled",attackEnabled _group];
    // Record the authored policy for exact cleanup, but do not disable it. Disabling group attacks
    // prevented native pilots and turrets from building a valid solution while Cortex waited to fire.
    _aircraft setVariable ["Waldo_Cortex_AirAttackToken",_plan get "token"];
    _aircraft setVariable ["Waldo_Cortex_AirAttackTarget",_target];
    // simulation=shotMissile also covers unguided rockets and bombs. Only a planner-classified
    // GUIDED station may receive missile target commands; assigning them to bombs prevented normal
    // fuzing, while assigning them to fixed rockets contradicted their delivery geometry.
    _aircraft setVariable ["Waldo_Cortex_AirAttackGuidedWeapon",
        ["",_plan getOrDefault ["selectedWeapon",""]] select ((_plan getOrDefault ["selectedWeaponClass",""]) == "GUIDED")];
    _aircraft setVariable ["Waldo_Cortex_AirAttackGuidanceTarget",_target];
    private _handler=_aircraft addEventHandler ["Fired",{
        params ["_aircraft","_weapon","","","","","_projectile"];
        if (toLowerANSI getText (configFile >> "CfgWeapons" >> _weapon >> "simulation") != "cmlauncher") then {
            _aircraft setVariable ["Waldo_Cortex_AirAttackShots",(_aircraft getVariable ["Waldo_Cortex_AirAttackShots",0])+1];
            // Preserve native ballistics and seeker behaviour, but give the projectile the hostile
            // already selected by its operator. fireAtTarget alone can launch a guided pylon round
            // without a missile target, producing the observed straight-line ground and A2A misses.
            private _guidedWeapon=_aircraft getVariable ["Waldo_Cortex_AirAttackGuidedWeapon",""];
            private _guidedTarget=_aircraft getVariable ["Waldo_Cortex_AirAttackGuidanceTarget",objNull];
            if (_weapon == _guidedWeapon && {!isNull _projectile} && {!isNull _guidedTarget} && {alive _guidedTarget}) then {
                private _targetAccepted=_projectile setMissileTarget [_guidedTarget,true];
                // Air seekers track the object directly. Ground seekers also need one immutable
                // aim point when their ammo explicitly supports manual point guidance. This is one
                // release-time assignment, not a scripted homing loop or an airframe correction.
                if (!(_guidedTarget isKindOf "Air")) then {
                    _projectile setMissileTargetPos (aimPos _guidedTarget);
                };
                _aircraft setVariable ["Waldo_Cortex_AirGuidanceAssignment",[
                    serverTime,_weapon,_targetAccepted,missileTarget _projectile,missileTargetPos _projectile
                ],true];
            };
        };
    }];
    _aircraft setVariable ["Waldo_Cortex_AirAttackShots",0];
    _job set ["firedHandler",_handler];
    [_group,_job,"INGRESS","PLAN_ACCEPTED"] call Waldo_fnc_CortexDrillSetStage;
        _stage="INGRESS";
    };
};
if (_startFailure != "") exitWith {[_startFailure] call _finish};
private _ownedWaypointName=_job getOrDefault ["ownedWaypointName",""];
private _currentRoute=(waypoints _group select {waypointName _x != _ownedWaypointName}) apply {
    [waypointPosition _x,waypointType _x]
};
if (_currentRoute isNotEqualTo (_job getOrDefault ["routeSignature",_currentRoute])) exitWith {["AUTHORED_ROUTE_CHANGED"] call _finish};
private _target=_job getOrDefault ["target",objNull];
if (!isNull _target) then {_job set ["lastTargetPosition",getPosATL _target]};
// Destroying the target must not strand the aircraft at the firing point. Complete the full
// INGRESS -> ATTACK -> EGRESS contract, using the wreck's stable position for departure geometry.
// A target lost before an actual attack remains a failed run and hands native control back at once.
// Some missions delete a killed vehicle immediately. In that case the object is already objNull by
// the next budgeted tick, so use the attack-stage shot baseline as the durable distinction between
// a pre-attack disappearance and a target removed after this aircraft physically fired.
private _targetUnavailable=isNull _target || {!alive _target};
if (_targetUnavailable && {!(_job getOrDefault ["targetDestroyed",false])}) then {
    // The engine may report the kill after the shot has already moved the finite plan into EGRESS.
    // Treat a destroyed target as this run's result when the aircraft physically fired during the
    // attack, without requiring the damage event and the ATTACK label to land on the same scheduler
    // tick. A target lost before real weapon fire remains a failed run.
    private _liveShots=_aircraft getVariable ["Waldo_Cortex_AirAttackShots",0];
    if (_liveShots > 0) then {
        _job set ["targetDestroyed",true];
        // A turret can validly destroy a contact while the pilot is still closing. Record that
        // physical fire as ATTACK before beginning egress so a real kill is not labelled TARGET_LOST.
        if (_stage == "INGRESS") then {
            [_group,_job,"ATTACK","ACTUAL_FIRE"] call Waldo_fnc_CortexDrillSetStage;
            _stage="ATTACK";
        };
        if (_stage == "ATTACK") then {
            [_group,_job,"EGRESS","TARGET_DESTROYED"] call Waldo_fnc_CortexDrillSetStage;
            _job set ["commandedStage",""];
            _job set ["egressStartPosition",getPosATL _aircraft];
            _job set ["egressStartedAt",serverTime];
            _job set ["deadline",serverTime+75];
            _stage="EGRESS";
        };
    };
};
if (_targetUnavailable && {!(_job getOrDefault ["targetDestroyed",false])}) exitWith {["TARGET_LOST",true] call _finish};
if ((getPosATL _aircraft select 2) < 25) exitWith {["GROUND_CLEARANCE"] call _finish};
// A failed fixed-wing solution must never continue following the descending delivery leg into the
// terrain. This is an abort, not a successful attack: delete the lease waypoint and return the
// native route while the aircraft still has enough height to recover.
if (_isPlane && {_stage == "ATTACK"} && {(getPosATL _aircraft select 2) < 220}) exitWith {
    ["DELIVERY_SAFETY_FLOOR",true] call _finish
};
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
// A durable named waypoint is cheaper and smoother than restarting the engine flight planner on
// every scheduler tick. Update it only on a real stage transition. The attack-stage target order
// lets the native air-combat FSM handle subsequent contact movement without Cortex chasing it.
private _commandedStage=_job getOrDefault ["commandedStage",""];
if (_commandedStage != _stage) then {
    _aircraft limitSpeed (_stageSpeeds select _stageIndex);
    // MOVE waypoint height is not a reliable flight-profile input for native aircraft: the live
    // fixed-wing audit retained its 900 m cruise height while flying a 378 m rocket leg. Apply one
    // native terrain-relative height hint when the leg changes, then leave the flight model alone.
    // This is deliberately not refreshed by the scheduler. Zeus handover deletes the lease waypoint
    // and does not issue a replacement movement command or delayed repair after curator ownership.
    _aircraft flyInHeight (_stageAltitudes select _stageIndex);
    private _ownedWaypointIndex=(waypoints _group) findIf {waypointName _x == _ownedWaypointName};
    private _ownedWaypoint=if (_ownedWaypointIndex < 0) then {
        private _created=_group addWaypoint [_destination,0];
        _created setWaypointName _ownedWaypointName;
        _created setWaypointType "MOVE";
        _created setWaypointBehaviour "COMBAT";
        _created setWaypointSpeed "FULL";
        _created setWaypointCompletionRadius ([450,220] select !_isPlane);
        _created
    } else {(waypoints _group) select _ownedWaypointIndex};
    // A moving air contact is the route, so native pursuit begins with the intercept leg. Ground
    // attacks retain the immutable target-crossing MOVE route until their live weapon basket is met;
    // attaching DESTROY here made Arma fire guns and rockets several kilometres before roll-in.
    if (_isPlane && {_stage == "ATTACK"} && {_job getOrDefault ["airToAir",false]} && {!isNull _target}) then {
        _ownedWaypoint setWaypointType "DESTROY";
        _ownedWaypoint waypointAttachVehicle _target;
    } else {
        _ownedWaypoint waypointAttachVehicle objNull;
        _ownedWaypoint setWaypointType "MOVE";
    };
    _ownedWaypoint setWaypointPosition [_destination,0];
    _group setCurrentWaypoint _ownedWaypoint;
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
    private _fireTarget=_job getOrDefault ["fireTarget",_target];
    if (isNull _fireTarget) then {_fireTarget=_target};
    // Select and acquire once at attack entry. Targeting lets the native FSM begin aligning, but
    // weapon release remains behind the live delivery basket below.
    if (_weapon != "") then {_aircraft selectWeaponTurret [_weapon,_turret]};
    if (!isNull _operator && {alive _operator} && {!(_job getOrDefault ["targetCommanded",false])}) then {
        // A MOVE leg alone never asks the engine weapon FSM to prosecute the contact. Reveal only
        // the already selected hostile at attack entry, then let the retained operator and native
        // flight model solve the shot. This runs once and is cleared during every handover path.
        _group reveal [_fireTarget,4];
        _aircraft doWatch _fireTarget;
        _aircraft doTarget _fireTarget;
        _operator doWatch _fireTarget;
        _operator doTarget _fireTarget;
        _job set ["targetCommanded",true];
    };
    private _range=_aircraft distance _target;
    private _horizontalRange=_aircraft distance2D _target;
    private _weaponVector=if (_weapon == "") then {[0,0,0]} else {_aircraft weaponDirection _weapon};
    private _targetVector=(aimPos _target) vectorDiff (getPosASL _aircraft);
    private _alignment=if (vectorMagnitude _weaponVector > 0.01 && {vectorMagnitude _targetVector > 0.01}) then {
        (vectorNormalized _weaponVector) vectorDotProduct (vectorNormalized _targetVector)
    } else {-1};
    private _aimed=if (_weapon == "") then {0} else {_aircraft aimedAtTarget [_target,_weapon]};
    private _selectedMagazine=_job getOrDefault ["selectedMagazine",""];
    private _magazineConfig=configFile >> "CfgMagazines" >> _selectedMagazine;
    private _ammoClass=getText (_magazineConfig >> "ammo");
    private _muzzleSpeed=getNumber (_magazineConfig >> "initSpeed");
    if (_muzzleSpeed <= 0 && {_ammoClass != ""}) then {
        _muzzleSpeed=getNumber (configFile >> "CfgAmmo" >> _ammoClass >> "typicalSpeed");
    };
    if (_muzzleSpeed <= 0) then {_muzzleSpeed=[900,180] select (_weaponClass == "ROCKET")};
    private _predictedLaunchVelocity=((vectorNormalized _weaponVector) vectorMultiply _muzzleSpeed)
        vectorAdd (velocity _aircraft);
    private _launchAlignment=if (vectorMagnitude _predictedLaunchVelocity > 0.01
        && {vectorMagnitude _targetVector > 0.01}) then {
        (vectorNormalized _predictedLaunchVelocity) vectorDotProduct (vectorNormalized _targetVector)
    } else {-1};
    private _loaded=(magazinesAllTurrets _aircraft) findIf {
        (_x select 1) isEqualTo _turret && {(_x select 2) > 0}
            && {(_x select 0) == _selectedMagazine || {(_x select 0) in compatibleMagazines _weapon}}
    } >= 0;
    private _envelope=switch _weaponClass do {
        case "GUN": {if (_airContact) then {[100,2200,0.999]} else {[120,1400,0.9995]}};
        // Native CAS opens fixed gun and rocket fire close to the aim point. A 3.6 km rocket basket
        // let the engine accept a request while the aircraft was merely pointed into the broad
        // target sector; real rounds then passed 500-950 metres away. Retain the long ingress but
        // reserve release for the final 1.8 km of a measured delivery line.
        case "ROCKET": {[400,1800,0.998]};
        // A guided seeker needs a clean forward launch sector, not a gun-quality boresight solution.
        // The Fired handler assigns the selected hostile to the real projectile after release.
        // Fixed forward weapons release synchronously below. Keep a clean seeker launch cone so the
        // target remains inside its acquisition basket without scripting projectile flight.
        case "GUIDED": {if (_airContact) then {[800,9000,0.96]} else {[1100,9000,0.97]}};
        case "BOMB": {[700,6500,0.9]};
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
    // A bomb rack points with the airframe and cannot be validated by comparing weaponDirection to
    // the target. Use a cheap ballistic release basket from live AGL and horizontal speed instead.
    // This does not steer the bomb or guarantee a hit; it only prevents firing after overflight and
    // gives the native projectile a physically credible release.
    private _horizontalVelocity=velocity _aircraft;
    _horizontalVelocity set [2,0];
    private _heightAGL=(getPosATL _aircraft select 2) max 1;
    private _verticalSpeed=velocity _aircraft select 2;
    private _fallTime=(_verticalSpeed+sqrt ((_verticalSpeed*_verticalSpeed)+(2*9.81*_heightAGL)))/9.81;
    private _bombReleaseDistance=(vectorMagnitude _horizontalVelocity)*_fallTime;
    private _predictedBombImpact=(getPosATL _aircraft) vectorAdd (_horizontalVelocity vectorMultiply _fallTime);
    private _bombImpactError=_predictedBombImpact distance2D getPosATL _target;
    private _bombWindow=_bombImpactError <= 140 && {_forwardAlignment >= 0.92};
    // A nose-mounted weapon needs forward closure. A retained lateral turret is specifically
    // selected to fire abeam, so forcing the helicopter nose onto the target defeats that pattern.
    private _closing=_pattern == "LATERAL" || {_forwardAlignment > 0.35};
    private _fixedUnguided=_turret isEqualTo [-1] && {_weaponClass in ["GUN","ROCKET"]};
    // Bohemia's native fire-control contract is doWatch, wait for a positive aimedAtTarget result,
    // then fireAtTarget. Seeker weapons can legitimately report zero before launch, but fixed guns
    // and rockets must demonstrate an engine solution before a release request is accepted.
    private _minimumAim=[0,0.05] select _fixedUnguided;
    // Fixed aircraft weapons are released through the real operator's fire-control state. The
    // vector returned by weaponDirection is not the launch vector of every aircraft muzzle or
    // pylon; the audit proved a nominally valid predicted solution could put an entire cannon burst
    // more than 400 metres beyond the target. Keep only a broad airframe/route basket here, then let
    // fireAtTarget solve the configured muzzle, aircraft momentum, seeker and burst mode.
    private _nativeFixedBasket=!_fixedUnguided || {
        _forwardAlignment >= ([0.985,0.975] select (_weaponClass == "ROCKET"))
    };
    private _validSolution=_loaded && {!isNull _operator} && {alive _operator}
        && {_range >= _minimumRange} && {_range <= _maximumRange}
        && {_closing} && {_nativeFixedBasket}
        && {_bombWindow || {!_bomb && {!_fixedUnguided || {_forwardAlignment >= 0.94}}}}
        && {!_bomb || {(getPosATL _aircraft select 2) >= 250}}
        && {_aimed >= _minimumAim};
    private _solution=[_validSolution,_range,_alignment,_aimed,_weapon,_simulation,_loaded,
        _weaponClass,_envelope,_deliveryAngle,_forwardAlignment,_minimumAim,_closing,
        _horizontalRange,_bombReleaseDistance,_bombWindow,_muzzleSpeed,_launchAlignment,
        _predictedBombImpact,_bombImpactError];
    _job set ["fireSolution",_solution];
    _job set ["deliveryLoaded",_loaded];
    _aircraft setVariable ["Waldo_Cortex_AirFireSolution",_solution,true];
    // Keep ground delivery on the target-crossing MOVE leg. A DESTROY waypoint attached at the
    // release basket proved engine-dependent: when attachment was rejected it became a spatial
    // target search, stalled the run and emitted a warning every simulation tick. The release below
    // hands only the compatible loaded station to its living operator at the measured solution.
    // Arma's own CAS path repeatedly asks the living operator to fire at a revealed target during a
    // bounded release window. That retains native muzzle, pylon and seeker logic. A scripted trigger
    // press bypassed that solution and produced consistent long misses even on a correct flight path.
    private _requestAt=_job getOrDefault ["fireRequestAt",-1];
    private _requestShotBaseline=_job getOrDefault ["fireRequestShotBaseline",-1];
    private _requestPending=_requestAt >= 0 && {_shots <= _requestShotBaseline}
        && {serverTime < _requestAt+0.35};
    if (_validSolution && {!_requestPending}
        && {serverTime >= (_job getOrDefault ["nextWeaponFire",0])}) then {
        // One native request at a time. Repeating a rejected request after a short interval is
        // intentional: the operator may enter the engine's exact solution later in the same pass.
        // No request steers the aircraft and no projectile is corrected after launch.
        private _fired=_aircraft fireAtTarget [_fireTarget,_weapon];
        if (_fired) then {
            _job set ["fireRequestAt",serverTime];
            _job set ["fireRequestShotBaseline",_shots];
        };
        private _fireDelay=if (!_fired) then {0.7+random 0.8} else {
            switch _weaponClass do {
                case "GUN": {0.15+random 0.25};
                case "ROCKET": {0.45+random 0.55};
                default {2+random 1.5};
            }
        };
        _job set ["nextWeaponFire",serverTime+_fireDelay];
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
    _job getOrDefault ["selectedMagazine",""],
    _job getOrDefault ["terrainLift",0],_job getOrDefault ["terrainClearanceMinimum",0],
    _job getOrDefault ["terrainSampleCount",0],_job getOrDefault ["terrainCorridor",0],
    +(_job getOrDefault ["targetPosition",getPosATL _target])
],true];

private _attackShots=_shots-(_job getOrDefault ["attackShotBaseline",0]);
if (_stage == "ATTACK" && {_attackShots > 0} && {(_job getOrDefault ["firstAttackShotAt",-1]) < 0}) then {
    _job set ["firstAttackShotAt",serverTime];
};
if ((_job getOrDefault ["pattern",""]) == "STANDOFF" && {_stage == "ATTACK"} && {_attackShots <= 0}
    && {serverTime > (_job getOrDefault ["attackStartedAt",serverTime])+25}) exitWith {
    _aircraft setVariable ["Waldo_Cortex_AirStandoffBlockedUntil",serverTime+90];
    ["NO_FIRE_SOLUTION",true] call _finish
};
if (serverTime > (_job get "deadline")) exitWith {["STAGE_TIMEOUT"] call _finish};
private _captureRadii=_job getOrDefault ["captureRadii",[if (_isPlane) then {700} else {450},if (_isPlane) then {700} else {450},if (_isPlane) then {700} else {450}]];
private _captureRadius=_captureRadii select _stageIndex;
// Rotorcraft do not capture exact three-dimensional move points under native combat flight. A
// modest approach tolerance advances into the real attack instruction before the pilot starts a
// local orbit; fixed-wing profiles retain their larger authored capture radii unchanged.
private _effectiveCapture=_captureRadius+([0,150] select !_isPlane);
private _stagePassed=_stageClosest <= _captureRadius && {_stageDistance >= _stageClosest+([120,75] select !_isPlane)};
// Discovery can acquire a fast jet after it has already flown past the nominal ingress point.
// Continue into the firing leg when that point is physically behind the jet; ordering a turn back
// creates the observed pre-run loop and can never improve a fixed-wing attack solution.
private _ingressBehind=_isPlane && {_stage == "INGRESS"}
    && {(velocity _aircraft) vectorDotProduct (_destination vectorDiff getPosATL _aircraft) <= 0}
    && {_aircraft distance2D _target <= 9500}
    && {(velocity _aircraft) vectorDotProduct ((getPosATL _target) vectorDiff getPosATL _aircraft) > 0};
// A lateral helicopter ingress is complete when the live aircraft enters its turret's practical
// engagement range. Native rotary-wing combat flight does not reliably capture an arbitrary offset
// point while a gunner is tracking a contact; waiting for that coordinate caused useful flight and
// gunfire to be labelled INGRESS_NONPROGRESS instead of beginning the abeam attack.
private _lateralWeaponEntry=!_isPlane && {_stage == "INGRESS"}
    && {(_job getOrDefault ["pattern",""]) == "LATERAL"}
    && {_aircraft distance2D _target <= 1800};
if (_stage == "EGRESS" && {(_stageDistance <= _effectiveCapture || {_stagePassed})}
    && {_aircraft distance2D (_points select 1) >= 400}) exitWith {["COMPLETE",true] call _finish};
private _egressTravel=if (_stage == "EGRESS") then {
    _aircraft distance2D (_job getOrDefault ["egressStartPosition",getPosATL _aircraft])
} else {0};
private _awayFromTarget=(velocity _aircraft) vectorDotProduct ((getPosATL _aircraft) vectorDiff
    (_job getOrDefault ["lastTargetPosition",getPosATL _aircraft])) > 0;
// Fast fixed-wing aircraft do not reliably capture an exact doMove point after a weapon release.
// Physical travel away from the target is an equally valid egress and avoids holding the aircraft
// under Cortex until a timeout after the attack has already succeeded.
if (_stage == "EGRESS" && {_egressTravel >= ([350,900] select _isPlane)}
    && {_awayFromTarget || {_egressTravel >= ([700,1400] select _isPlane)}}) exitWith {["COMPLETE",true] call _finish};
if (_stage == "EGRESS" && {_routeStalled}) exitWith {["EGRESS_NONPROGRESS",true] call _finish};
if (_stage in ["INGRESS","ATTACK"] && {_routeStalled}) exitWith {
    [["INGRESS_NONPROGRESS","ATTACK_NONPROGRESS"] select (_stage == "ATTACK"),true] call _finish
};
switch _stage do {
    case "INGRESS": {
        // Aircraft rarely hit an exact doMove coordinate, especially at fixed-wing turn radius.
        // Accept entering or physically passing a bounded capture area; elapsed time alone still
        // cannot advance the state.
        if (_stageDistance <= _effectiveCapture || {_stagePassed} || {_ingressBehind} || {_lateralWeaponEntry}) then {
            [_group,_job,"ATTACK","INGRESS_ARRIVAL"] call Waldo_fnc_CortexDrillSetStage;
            _stage="ATTACK";
            _job set ["commandedStage",""];
            _job set ["deadline",serverTime+50];
            _job set ["attackStartedAt",serverTime];
            _job set ["attackShotBaseline",_shots];
            // The public plan drives diagnostics and Fired-event attribution. Publish the accepted
            // transition immediately instead of leaving it one budget tick behind the real job;
            // otherwise successful rounds are incorrectly labelled as ingress fire.
            private _publishedPlan=_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]];
            if (_publishedPlan isNotEqualTo []) then {
                _publishedPlan set [2,"ATTACK"];
                _publishedPlan set [4,_points select 1];
                _aircraft setVariable ["Waldo_Cortex_AirAttackPlan",_publishedPlan,true];
            };
        };
    };
    case "ATTACK": {
        private _attackDwell=serverTime-(_job getOrDefault ["attackStartedAt",serverTime]);
        private _weaponClass=_job getOrDefault ["selectedWeaponClass",""];
        private _desiredShots=switch _weaponClass do {
            // A short cannon burst damaged the live MRAP but left it operational. Forty requested
            // rounds remains a finite one-pass burst while tolerating natural dispersion and armour.
            case "GUN": {40};
            case "ROCKET": {8};
            // One valid seeker launch can still be defeated or near-miss. Keep this a finite salvo.
            case "GUIDED": {3};
            // Release the paired bomb rack when fitted. One verified direct pass in the audit left
            // the tracked target untouched; a two-weapon ripple is the credible finite delivery.
            case "BOMB": {2};
            default {1};
        };
        // The release basket is the delivery point. Let finite gun/rocket/guided salvos develop
        // across a few native fire-control cycles, then leave promptly. A one-round rack and an
        // engine that refuses a follow-up cannot strand the aircraft: empty ammunition or six
        // bounded class-specific interval after the first real shot closes the delivery. A turreted
        // cannon needs longer than a missile rail because dispersion is intentionally applied to
        // vehicle crews. Target destruction still ends the attack immediately at the top of the
        // next scheduler tick; no hit or kill is fabricated here.
        private _deliveryWindow=switch _weaponClass do {
            case "GUN": {18};
            case "ROCKET": {12};
            default {10};
        };
        private _deliveryComplete=_attackShots >= _desiredShots
            || {_attackShots > 0 && {!(_job getOrDefault ["deliveryLoaded",true])}}
            || {_attackShots > 0 && {serverTime >= (_job getOrDefault ["firstAttackShotAt",serverTime])+_deliveryWindow}};
        if (_attackShots > 0 && {_attackDwell >= (_job getOrDefault ["attackMinimum",2])}
            && {_deliveryComplete}) then {
            [_group,_job,"EGRESS","ACTUAL_FIRE"] call Waldo_fnc_CortexDrillSetStage;
            _stage="EGRESS";
            _job set ["commandedStage",""];
            _job set ["egressStartPosition",getPosATL _aircraft];
            _job set ["egressStartedAt",serverTime];
            _job set ["deadline",serverTime+75];
            private _publishedPlan=_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]];
            if (_publishedPlan isNotEqualTo []) then {
                _publishedPlan set [2,"EGRESS"];
                _publishedPlan set [4,_points select 2];
                _aircraft setVariable ["Waldo_Cortex_AirAttackPlan",_publishedPlan,true];
            };
        };
    };
    case "EGRESS": {};
};
0.5
