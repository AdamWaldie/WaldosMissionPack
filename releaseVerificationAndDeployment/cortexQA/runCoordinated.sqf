/*
 * Author: WaldoTheWarfighter
 * Controller diagnostic, not combat acceptance: actors are invulnerable and the opponent
 * cannot fire. Exercises natural contact with three full squads, actual supporting/assault fire,
 * two real reinforcement arrivals, coordinated assault travel and
 * release to new ordinary group orders after both support switches are disabled.
 * Locality/authority: scheduled server fixture using normal discovery, support and assault paths.
 * Optional responder owners use WMP migration before contact; return to server after release for
 * fresh ordinary waypoint commands. No owner-local command is executed from the wrong machine.
 * Repeat/JIP: fresh pinned groups and public destinations; caller restores tuning, actors cleaned here.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required callbacks.
 * 3: responderOwners <ARRAY of NUMBER>, default []; two HC owners for the migration variant.
 * 4: exposeDuringRally <BOOL>, default false; remove the view screen after reservation
 * to verify natural contact cannot revoke rally movement. Every variant removes its rally-only
 * screen before measuring the later open-ground coordinated assault.
 * 5: localScreens <BOOL>, default false; additive fixture comparison with short screens
 * at the initial helper positions, never across the later assault corridor. The original
 * long-screen geometry remains available unchanged.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACoordinated.sqf";
 */
params ["_check","_phase","_wait",["_responderOwners",[],[[]]],["_exposeDuringRally",false,[true]],["_localScreens",false,[true]]];
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIPass_LambsMode","WMP"],["Waldo_AIPass_Contact_Enable",true],
    ["Waldo_AIPass_Reinforce_Enable",true],["Waldo_AIPass_Reinforce_MaxResponders",2],
    ["Waldo_AIPass_CoordinatedAssault_Enable",false],["Waldo_AIPass_Aggression",2],
    ["Waldo_AIPass_Flank_Enable",false],["Waldo_AIPass_Advance_Enable",false],
    ["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_Morale_Enable",false],
    ["Waldo_AIPass_ContactReports_Enable",false],["Waldo_AIPass_Investigate_Enable",false],
    ["Waldo_AIPass_Artillery_Enable",false],["Waldo_AIPass_FireControl_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _groups=[]; private _actors=[];
// Build real view geometry before any soldier can acquire the enemy.
// The requester stands beyond the screen; helpers rally behind it and must route around it.
private _walls=[];
private _screenCentres=if (_localScreens) then {[[1408,1410,0],[1608,1410,0]]} else {[[1500,1470,0]]};
private _screenHalfCount=if (_localScreens) then {4} else {24};
{
    private _centre=_x;
    for "_i" from (-_screenHalfCount) to _screenHalfCount do {
        private _wall=createVehicle ["Land_CncWall4_F",_centre vectorAdd [_i*4,0,0],[],0,"CAN_COLLIDE"];
        _wall setDir 0;
        _walls pushBack _wall;
    };
} forEach _screenCentres;
diag_log format ["WMP CORTEX QA COORD GEOMETRY: localScreens=%1 centres=%2 halfSegments=%3",_localScreens,_screenCentres,_screenHalfCount];
private _makeGroup={
    params ["_side"];
    private _group=createGroup [_side,true];
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    _group setVariable ["Waldo_AIPass_Profile","ELITE",true];
    _group setCombatMode "BLUE"; _group allowFleeing 0;
    _groups pushBack _group; _group
};
private _makeUnit={
    params ["_group","_position","_label"];
    private _unit=_group createUnit [["O_Soldier_F","B_Soldier_F"] select (side _group == west),_position,[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",_label,true];
    _unit setVariable ["Waldo_CortexQA_Shots",0];
    _unit setVariable ["Waldo_CortexQA_MovingShots",0,true];
    _unit addEventHandler ["FiredMan",{
        params ["_unit","_weapon"];
        if (_weapon in ["Throw","Put"]) exitWith {};
        _unit setVariable ["Waldo_CortexQA_Shots",(_unit getVariable ["Waldo_CortexQA_Shots",0])+1,true];
        // Measure speed at discharge, not at the next one-second observer sample.
        private _teams=(group _unit) getVariable ["Waldo_Cortex_SupportTeams",[]];
        if (abs speed _unit > 2 && {count _teams == 6} && {_unit in (_teams select 5)}) then {
            _unit setVariable ["Waldo_CortexQA_MovingShots",(_unit getVariable ["Waldo_CortexQA_MovingShots",0])+1,true];
        };
    }];
    _unit allowDamage false; _actors pushBack _unit; _unit
};
private _requester=[east] call _makeGroup;
private _observer=[_requester,[1500,1500,0],"CONTACT / BASE OF FIRE"] call _makeUnit;
_observer setDir 0; _observer disableAI "PATH";
private _base=[_observer];
for "_i" from 1 to 5 do {
    private _unit=[_requester,[1485+_i*6,1500,0],format ["BASE OF FIRE / %1",_i+1]] call _makeUnit;
    _unit setDir 0; _unit disableAI "PATH"; _base pushBack _unit;
};
private _baseOrigins=_base apply {getPosATL _x};
private _helpers=[]; private _teams=[];
for "_team" from 0 to 1 do {
    private _group=[east] call _makeGroup;
    private _members=[];
    for "_i" from 0 to 5 do {
        private _unit=[_group,[1400+_team*200+_i*3,1400,0],format ["ASSAULT TEAM %1 / %2",_team+1,_i+1]] call _makeUnit;
        _members pushBack _unit; _helpers pushBack _unit;
        _unit setVariable ["Waldo_CortexQA_Target",[1500,1420,0],true];
    };
    _teams pushBack _members;
};
private _attackBaseline=_teams apply {attackEnabled (group (_x select 0))};
private _featureBaseline=_helpers apply {[_x checkAIFeature "TARGET",_x checkAIFeature "AUTOTARGET",_x checkAIFeature "AUTOCOMBAT",_x checkAIFeature "PATH"]};
private _migrateTeam={
    params ["_members","_owner","_stage"];
    private _g=group (_members select 0);
    _g setVariable ["Waldo_Headless_ExcludeGroup",false,true];
    {_x setVariable ["acex_headless_blacklist",false,true]} forEach _members;
    diag_log format ["WMP CORTEX QA COORD MIGRATION REQUEST: group=%1 members=%2 actualMembers=%3 target=%4",_g,_members apply {netId _x},(units _g) apply {netId _x},_owner];
    private _requested=[_g,_owner] call Waldo_fnc_HeadlessMigrateGroup;
    private _adopted=[{groupOwner _g == _owner && {_members findIf {owner _x != _owner} < 0}},30] call _wait;
    ["COORD-owner-"+_stage,_requested && {_adopted},str [groupOwner _g,_members apply {owner _x}]] call _check;
    _g setVariable ["Waldo_Headless_ExcludeGroup",true,true];
};
if (count _responderOwners == 2) then {
    {[_x,_responderOwners select _forEachIndex,format ["team-%1-headless",_forEachIndex+1]] call _migrateTeam} forEach _teams;
};
private _enemyGroup=[west] call _makeGroup;
_enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
private _enemy=[_enemyGroup,[1500,1600,0],"OBSERVED OBJECTIVE"] call _makeUnit;
_enemy setDir 180; _enemy disableAI "PATH";
// The observation stimulus is a visible standing sentry, not a prone target concealed
// by its own profile. Restore normal stance before the combat movement phase.
_enemy setUnitPos "UP";
missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors,true];
["Coordinated assault: rally first","The base squad must see the opponent naturally. Two helper squads start behind a concrete screen; each must physically reach its own separate rear rally area. Coordinated assault is disabled during this stage.",[1500,1460,0]] call _phase;
private _blocked=_helpers findIf {
    private _rays=lineIntersectsSurfaces [eyePos _x,eyePos _enemy,_x,_enemy,true,-1,"VIEW","GEOM"];
    _rays findIf {(_x select 2) in _walls || {(_x select 3) in _walls}} < 0
} < 0;
["COORD-helper-view-blocked",_blocked] call _check;
private _nearestPlayer=1e9;
{if (!(_x isKindOf "HeadlessClient_F") && {alive _x}) then {_nearestPlayer=_nearestPlayer min (_observer distance2D _x)}} forEach allPlayers;
["COORD-fixture-tactical-range",_nearestPlayer <= (missionNamespace getVariable ["Waldo_AIPass_FarRange",2500]),format ["nearestPlayer=%1 farRange=%2",_nearestPlayer,missionNamespace getVariable ["Waldo_AIPass_FarRange",2500]]] call _check;
["COORD-natural-contact",[{_observer knowsAbout _enemy >= 1},30] call _wait] call _check;
if (_exposeDuringRally) then {
    private _reserved=[{
        _teams findIf {
            private _g=group (_x select 0);
            private _lease=_g getVariable ["Waldo_AIPass_SupportLease",[]];
            private _status=_g getVariable ["Waldo_AIPass_SupportStatus",[]];
            count _lease != 6 || {count _status != 4} || {!(_status select 2)}
        } < 0
    },30] call _wait;
    ["COORD-contact-rally-reservations",_reserved] call _check;
    {deleteVehicle _x} forEach _walls;
    _walls=[];
    // Establish an observation direction without injecting enemy knowledge.
    {if (local _x) then {_x doWatch (getPosATL _enemy)}} forEach _helpers;
    ["Coordinated rally under observation","The screen has been removed after reservation. Helpers must naturally see the enemy and still finish the reserved rally. Contact must not silently cancel their movement.",[1500,1460,0]] call _phase;
    private _seen=[{_teams findIf {leader (group (_x select 0)) knowsAbout _enemy < 1} < 0},30] call _wait;
    ["COORD-contact-rally-natural-sight",_reserved && {_seen},str (_helpers apply {[netId _x,getDir _x,_x knowsAbout _enemy,_x targetKnowledge _enemy]})] call _check;
};
private _prematureReady=false;
private _rallied=[{
    {
        private _g=group (_x select 0);
        private _status=_g getVariable ["Waldo_AIPass_SupportStatus",[]];
        private _lease=_g getVariable ["Waldo_AIPass_SupportLease",[]];
        if (count _status == 4 && {count _lease == 6} && {(_status select 0) == (_lease select 0)}
            && {(_status select 1) >= 0} && {!(_status select 3)}
            && {_x findIf {[_x] call Waldo_fnc_CortexCombatEffective && {_x distance2D (_lease select 3) > 45}} >= 0}) then {
            _prematureReady=true;
        };
    } forEach _teams;
    _teams findIf {
        private _lease = (group (_x select 0)) getVariable ["Waldo_AIPass_SupportLease",[]];
        if (count _lease != 6) exitWith {true};
        private _area = _lease select 3;
        {_x setVariable ["Waldo_CortexQA_Target",_area,true]} forEach _x;
        _x findIf {_x distance2D _area > 45} >= 0
    } < 0
},120] call _wait;
["COORD-no-premature-rally-readiness",!_prematureReady] call _check;
["COORD-two-teams-physical-rally",_rallied,str (_helpers apply {getPosATL _x})] call _check;
private _rallyLeases = _teams apply {(group (_x select 0)) getVariable ["Waldo_AIPass_SupportLease",[]]};
["COORD-distinct-rally-areas",_rallyLeases findIf {count _x != 6} < 0 && {
    ((_rallyLeases select 0) select 3) distance2D ((_rallyLeases select 1) select 3) >= 109
},str _rallyLeases] call _check;
diag_log format ["WMP CORTEX QA COORD RALLY: requesterPhase=%1 helperStates=%2",_requester getVariable ["Waldo_AIPass_PublicPhase","NONE"],(_teams apply {private _g=group (_x select 0); [groupId _g,_g getVariable ["Waldo_AIPass_PublicPhase","NONE"],_g getVariable ["Waldo_AIPass_SupportLease",[]],_g getVariable ["Waldo_AIPass_SupportStatus",[]]]})];
sleep 10;
["COORD-disabled-no-objective-advance",_rallied && {_helpers findIf {_x distance2D _enemy < 100} < 0}] call _check;
// The screen validates rally routing and sight isolation only. Leaving it in the assault
// corridor made the two squads route around opposite ends of a 192 m wall, so the later
// open-ground backtracking, idle and cohesion checks measured fixture geometry rather than
// coordinated movement. Obstacle and avenue-of-approach behaviour belongs in a separate case.
private _movementScreens=+_walls;
{deleteVehicle _x} forEach _movementScreens;
_walls=[];
sleep 0.1;
["COORD-assault-corridor-clear",_movementScreens findIf {!isNull _x} < 0,str (count _movementScreens)] call _check;
_enemy setUnitPos "AUTO";
private _origins=_helpers apply {getPosATL _x};
[createHashMapFromArray [["Waldo_AIPass_CoordinatedAssault_Enable",true],["Waldo_AIPass_FireControl_Enable",true]]] call Waldo_fnc_CortexTuning;
// Open fire only after the independently measured rally stage. Combat mode is global;
// the production owner-local fire controller issues the actual engagement commands.
{_x setCombatMode "RED"} forEach ([_requester]+(_teams apply {group (_x select 0)}));
{_x setVariable ["Waldo_CortexQA_Target",getPosATL _enemy,true]} forEach _helpers;
["Movement diagnostic: coordinated bounds","DIAGNOSTIC ONLY: invulnerable actors and a non-firing target. This does not validate combat effectiveness. Squads exchange MOVE and COVER roles. Inside the moving squad, one fire team bounds while the other covers, then follows. Watch role labels, actual shots and cyan trails. Both squads must travel at least 60 m and reach within 50 m of the objective. No lease or waypoint is injected by this test.",[1500,1550,0]] call _phase;
private _lastSample=-1;
private _lastMovementDiagnostic=-1;
private _lastSquad=-1;
private _roleSwitches=0;
private _boundTravel=createHashMap;
private _largestBacktrack=0;
private _interCover=0;
private _intraCover=[0,0];
private _movingShots=[0,0];
private _idleSince=createHashMap;
private _longestMovingIdle=0;
private _shotCounts=_helpers apply {_x getVariable ["Waldo_CortexQA_Shots",0]};
private _advanced=[{
    if (diag_tickTime-_lastSample >= 1) then {
        _lastSample=diag_tickTime;
        private _movingTeams=[];
        private _firingTeams=[];
        {
            private _ti=_forEachIndex;
            private _members=_x;
            private _g=group (_members select 0);
            private _role=_g getVariable ["Waldo_Cortex_SupportRole",[]];
            private _fireTeams=_g getVariable ["Waldo_Cortex_SupportTeams",[]];
            private _moving=0; private _firing=0; private _coverShots=0;
            {
                private _i=_ti*6+_forEachIndex;
                private _shots=_x getVariable ["Waldo_CortexQA_Shots",0];
                private _delta=_shots-(_shotCounts select _i);
                _shotCounts set [_i,_shots];
                if (abs speed _x > 2) then {_moving=_moving+1};
                _firing=_firing+_delta;
                // Measure actual retreat along this bound's axis on the empty range.
                // Fresh sequence = fresh origin; neither role flags nor waypoints prove travel.
                if (count _role == 5 && {(_role select 2) == "MOVE"}) then {
                    private _key=format ["%1:%2:%3",netId _x,_role select 0,_role select 1];
                    private _track=_boundTravel getOrDefault [_key,[]];
                    private _position=getPosATL _x;
                    if (_track isEqualTo []) then {
                        private _axis=(_role select 3) vectorDiff _position;
                        _axis set [2,0];
                        _track=[+_position,vectorNormalized _axis,0];
                        _boundTravel set [_key,_track];
                    };
                    private _progress=(_position vectorDiff (_track select 0)) vectorDotProduct (_track select 1);
                    private _peak=(_track select 2) max _progress;
                    _track set [2,_peak];
                    _largestBacktrack=_largestBacktrack max (_peak-_progress);
                };

                if (count _fireTeams == 6 && {!(_x in (_fireTeams select 5))}) then {_coverShots=_coverShots+_delta};
                private _roleName=if (count _role == 5) then {_role select 2} else {if ((_g getVariable ["Waldo_AIPass_SupportLease",[]]) isEqualTo []) then {"RELEASED"} else {"RALLY"}};
                private _element=if (count _fireTeams == 6) then {["COVER","MOVE"] select (_x in (_fireTeams select 5))} else {_roleName};
                _x setVariable ["Waldo_CortexQA_Label",format ["S%1.%2 %3 / %4 | shots %5",_ti+1,_forEachIndex+1,_roleName,_element,_shots],true];
                if (count _role == 5 && {(_role select 3) isNotEqualTo []}) then {_x setVariable ["Waldo_CortexQA_Target",_role select 3,true]};
            } forEach _members;
            // Measure an outstanding movement role, not a stationary covering task.
            // This empty-range inactivity criterion is not a real-combat timing limit.
            if (count _role == 5 && {(_role select 2) == "MOVE"}) then {
                private _idleKey=format ["%1:%2",_ti,_role select 1];
                private _outstanding=_members findIf {_x distance2D (_role select 3) > 20} >= 0;
                if (_moving == 0 && {_outstanding}) then {
                    private _since=_idleSince getOrDefault [_idleKey,diag_tickTime];
                    _idleSince set [_idleKey,_since];
                    _longestMovingIdle=_longestMovingIdle max (diag_tickTime-_since);
                } else {_idleSince deleteAt _idleKey};
            };
            _movingTeams pushBack _moving;
            _firingTeams pushBack _firing;
            if (_moving >= 2 && {_coverShots > 0}) then {_intraCover set [_ti,(_intraCover select _ti)+1]};
            if (count _role == 5 && {(_role select 2) == "MOVE"} && {_moving >= 2}) then {
                if (_lastSquad >= 0 && {_lastSquad != _ti}) then {_roleSwitches=_roleSwitches+1};
                _lastSquad=_ti;
            };
        } forEach _teams;
        if ((_movingTeams select 0) >= 2 && {(_movingTeams select 1) <= 1} && {(_firingTeams select 1) > 0}
            || {(_movingTeams select 1) >= 2 && {(_movingTeams select 0) <= 1} && {(_firingTeams select 0) > 0}}) then {_interCover=_interCover+1};
    };
    if (diag_tickTime-_lastMovementDiagnostic >= 15) then {
        _lastMovementDiagnostic=diag_tickTime;
        {
            private _g=group (_x select 0);
            private _state=_g getVariable ["Waldo_AIPass_State",createHashMap];
            private _drill=_state getOrDefault ["drill",createHashMap];
            diag_log format ["WMP CORTEX QA COORD MOVEMENT: group=%1 owner=%2 role=%3 stage=%4 result=%5 actors=%6",
                _g,groupOwner _g,_g getVariable ["Waldo_Cortex_SupportRole",[]],
                _drill getOrDefault ["stage","REMOTE_OR_NONE"],_g getVariable ["Waldo_Cortex_SupportBoundResult",[]],
                _x apply {[netId _x,getPosATL _x,currentCommand _x,expectedDestination _x,
                    _x checkAIFeature "PATH",behaviour _x,unitCombatMode _x]}];
        } forEach _teams;
    };
    private _ok=true;
    {if (!alive _x || {_x distance2D (_origins select _forEachIndex) < 60} || {_x distance2D _enemy > 50}) then {_ok=false}} forEach _helpers;
    _ok
},600] call _wait;
["COORD-inter-squad-role-exchange",_roleSwitches >= 2,str _roleSwitches] call _check;
{private _total=0; {_total=_total+(_x getVariable ["Waldo_CortexQA_MovingShots",0])} forEach _x; _movingShots set [_forEachIndex,_total]} forEach _teams;
["COORD-movers-fire-during-travel",_movingShots findIf {_x <= 0} < 0,str _movingShots] call _check;
["COORD-no-prolonged-empty-range-idle",_advanced && {_longestMovingIdle <= 15},format ["longest outstanding MOVE idle=%1 s; empty-range limit=15 s",_longestMovingIdle]] call _check;
["COORD-open-ground-bound-backtracking",_roleSwitches >= 2 && {_largestBacktrack <= 8},format ["largest physical reverse travel=%1 m; empty-range limit=8 m",_largestBacktrack]] call _check;
["COORD-inter-squad-physical-cover",_interCover > 0,str _interCover] call _check;
["COORD-intra-squad-physical-cover",_intraCover findIf {_x == 0} < 0,str _intraCover] call _check;
["COORD-both-teams-physical-advance",_rallied && {_advanced},str (_helpers apply {getPosATL _x})] call _check;
// Report viable-element progress separately; never replace all-actor acceptance with it.
// Four of six is the same rounded-up 60 percent threshold used by movement recovery.
private _viableCounts = [];
{
    private _teamIndex = _forEachIndex;
    private _arrivedCount = 0;
    {
        if (alive _x && {_x distance2D (_origins select (_teamIndex*6+_forEachIndex)) >= 60}
            && {_x distance2D _enemy <= 50}) then {_arrivedCount = _arrivedCount+1};
    } forEach _x;
    _viableCounts pushBack _arrivedCount;
} forEach _teams;
["COORD-two-viable-elements-advance",_rallied && {_viableCounts findIf {_x < 4} < 0},str _viableCounts] call _check;
private _centres=_teams apply {
    private _team=_x;
    private _sum=0; {_sum=_sum+(getPosATL _x select 0)} forEach _team; _sum/count _team
};
private _sideApproach=true;
{if (_x distance2D (_origins select _forEachIndex) < 60) then {_sideApproach=false}} forEach _helpers;
["COORD-opposite-objective-sides",_rallied && {_sideApproach} && {(_centres select 0)-1500 > 5 && {(_centres select 1)-1500 < -5} || {(_centres select 1)-1500 > 5 && {(_centres select 0)-1500 < -5}}},str _centres] call _check;
// Keep per-soldier arrival evidence separate from team geometry; an outside
// soldier still fails the unchanged aggregate arrival requirement above.
{
    diag_log format ["WMP CORTEX QA COORD ARRIVAL: unit=%1 travelled=%2 remaining=%3 command=%4 phase=%5 lease=%6 status=%7",
        _x getVariable ["Waldo_CortexQA_Label",str _x],_x distance2D (_origins select _forEachIndex),
        _x distance2D _enemy,currentCommand _x,(group _x) getVariable ["Waldo_AIPass_PublicPhase","NONE"],
        (group _x) getVariable ["Waldo_AIPass_SupportLease",[]],(group _x) getVariable ["Waldo_AIPass_SupportStatus",[]]];
} forEach _helpers;
private _baseHeld=true;
{if (_x distance2D (_baseOrigins select _forEachIndex) >= 3) then {_baseHeld=false}} forEach _base;
["COORD-base-position-retained",_baseHeld] call _check;
["COORD-base-actual-supporting-fire",_base findIf {(_x getVariable ["Waldo_CortexQA_Shots",0]) > 0} >= 0,str (_base apply {_x getVariable ["Waldo_CortexQA_Shots",0]})] call _check;
{
    [format ["COORD-team-%1-actual-fire",_forEachIndex+1],_x findIf {(_x getVariable ["Waldo_CortexQA_Shots",0]) > 0} >= 0,str (_x apply {_x getVariable ["Waldo_CortexQA_Shots",0]})] call _check;
} forEach _teams;
[createHashMapFromArray [["Waldo_AIPass_CoordinatedAssault_Enable",false],["Waldo_AIPass_Reinforce_Enable",false]]] call Waldo_fnc_CortexTuning;
["Coordinated assault: disable and hand back","Support is now disabled. Both squads must release their support assignments and temporary orders, then physically follow fresh ordinary movement orders. The cyan trails show real travel.",[1500,1580,0]] call _phase;
private _released=[{
    _teams findIf {
        private _g=group (_x select 0);
        private _status=_g getVariable ["Waldo_AIPass_SupportStatus",[]];
        !((_g getVariable ["Waldo_AIPass_SupportLease",[]]) isEqualTo [])
            || {_status isNotEqualTo []}
            || {(waypoints _g) findIf {waypointDescription _x == "WMP AI PASS"} >= 0}
    } < 0
},20] call _wait;
["COORD-disabled-release",_released] call _check;
if (count _responderOwners == 2) then {
    {[_x,2,format ["team-%1-return",_forEachIndex+1]] call _migrateTeam} forEach _teams;
};
private _attackRestored=true;
{if (attackEnabled (group (_x select 0)) != (_attackBaseline select _forEachIndex)) then {_attackRestored=false}} forEach _teams;
["COORD-autonomous-attack-restored",_attackRestored,str (_teams apply {attackEnabled (group (_x select 0))})] call _check;
private _restoredFeatures=_helpers apply {[_x checkAIFeature "TARGET",_x checkAIFeature "AUTOTARGET",_x checkAIFeature "AUTOCOMBAT",_x checkAIFeature "PATH"]};
["COORD-movement-features-restored",_restoredFeatures isEqualTo _featureBaseline,str [_featureBaseline,_restoredFeatures]] call _check;
private _releaseOrigins=_helpers apply {getPosATL _x};
{
    private _g=group (_x select 0);
    private _destination=(leader _g) getPos [90,[270,90] select (_forEachIndex == 1)];
    private _wp=_g addWaypoint [_destination,0];
    _wp setWaypointType "MOVE"; _wp setWaypointCompletionRadius 5;
    _wp setWaypointDescription "QA FRESH ORDINARY ORDER";
    _g setCurrentWaypoint _wp;
    {
        _x setVariable ["Waldo_CortexQA_Target",_destination,true];
        _x setVariable ["Waldo_CortexQA_Label",format ["%1 / ORDINARY ORDER",groupId _g],true];
    } forEach _x;
} forEach _teams;
private _handedBack=[{
    private _okay=true;
    {if (!alive _x || {_x distance2D (_releaseOrigins select _forEachIndex) < 50}) then {_okay=false}} forEach _helpers;
    _okay
},75] call _wait;
["COORD-fresh-orders-physical-travel",_released && {_handedBack},str (_helpers apply {getPosATL _x})] call _check;
{
    diag_log format ["WMP CORTEX QA COORD HANDOVER: unit=%1 travel=%2 remaining=%3 speed=%4 behaviour=%5 command=%6",
        _x getVariable ["Waldo_CortexQA_Label",str _x],_x distance2D (_releaseOrigins select _forEachIndex),
        _x distance2D (_x getVariable ["Waldo_CortexQA_Target",getPosATL _x]),speed _x,behaviour _x,currentCommand _x];
} forEach _helpers;
// Separate Zeus takeover from the existing ordinary-order handover result.
// The marker is the production event endpoint; curator UI delivery is tested separately.
private _zeusOrigins=_helpers apply {getPosATL _x};
{
    private _g=group (_x select 0);
    [_g,true] call Waldo_fnc_CortexZeusMark;
    private _destination=(getPosATL leader _g) vectorAdd [0,100,0];
    private _wp=_g addWaypoint [_destination,0];
    _wp setWaypointType "MOVE"; _wp setWaypointCompletionRadius 5;
    _wp setWaypointDescription "QA ZEUS REPLACEMENT";
    _g setCurrentWaypoint _wp;
    {
        _x setVariable ["Waldo_CortexQA_Target",_destination,true];
        _x setVariable ["Waldo_CortexQA_Label",format ["%1 / ZEUS ORDER",groupId _g],true];
    } forEach _x;
} forEach _teams;
["Coordinated assault: Zeus replacement","Zeus now takes control of both squads. Every soldier must travel at least 50 m toward the new northbound order. Earlier assault and ordinary-handover failures remain recorded.",[1500,1680,0]] call _phase;
private _zeusTravel=[{
    private _okay=true;
    {if (!alive _x || {(getPosATL _x select 1)-(_zeusOrigins select _forEachIndex select 1) < 50}) then {_okay=false}} forEach _helpers;
    _okay
},120] call _wait;
["COORD-zeus-replacement-physical-travel",_zeusTravel,str (_helpers apply {getPosATL _x})] call _check;
// Additive diagnostic: retain both threatened-order failures above. Removing only
// the fixture opponent distinguishes persistent movement ownership from combat
// engagement. Do not alter actor positions, AI features, behaviour or ROE here.
deleteVehicle _enemy;
private _unopposedOrigins=_helpers apply {getPosATL _x};
{
    private _g=group (_x select 0);
    private _destination=(getPosATL leader _g) vectorAdd [0,100,0];
    private _wp=_g addWaypoint [_destination,0];
    _wp setWaypointType "MOVE";
    _wp setWaypointDescription "QA UNOPPOSED HANDOVER DIAGNOSTIC";
    _g setCurrentWaypoint _wp;
    {
        _x setVariable ["Waldo_CortexQA_Target",_destination,true];
        _x setVariable ["Waldo_CortexQA_Label",format ["%1 / UNOPPOSED ORDER",groupId _g],true];
    } forEach _x;
} forEach _teams;
["Handover without the test enemy","Earlier threatened-order results remain recorded. The fixture opponent has now been removed. Check whether the same soldiers follow a new ordinary waypoint without any AI feature, behaviour or position reset.",[1500,1680,0]] call _phase;
private _unopposedTravel=[{
    private _okay = true;
    {if (!alive _x || {_x distance2D (_unopposedOrigins select _forEachIndex) < 50}) then {_okay=false}} forEach _helpers;
    _okay
},90] call _wait;
["COORD-unopposed-handover-diagnostic",_unopposedTravel,str (_helpers apply {getPosATL _x})] call _check;

{deleteVehicle _x} forEach (_actors+_walls); {deleteGroup _x} forEach _groups;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
