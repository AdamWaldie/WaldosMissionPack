/*
 * Author: WaldoTheWarfighter
 * Runs an additive, instrumented combined-arms operation against a defended objective.
 * Three separated infantry squads receive one ordinary objective before contact; Cortex must compose
 * its existing contact, flank, advance, coordinated assault, fire-control, ground-gunnery and air-attack
 * behaviours while every element remains free to act independently. No rally, readiness schedule,
 * tactic function, shared completion barrier or scripted role assignment is injected by this fixture.
 * Locality/authority: scheduled dedicated-server fixture owns all disposable groups and vehicles;
 * production functions run on their normal group/object owners and public state feeds the client overlay.
 * Repeat/JIP: every run creates fresh actors, publishes bounded diagnostics and deletes all fixtures;
 * a joining observer can render the current public phase without replaying any orders. Ordinary
 * reinforcement is disabled and its responder count is zero, proving coordinated composition owns
 * its own two manoeuvre slots instead of inheriting a contradictory reinforcement limit.
 * Arguments: 0: check <CODE>; 1: phase <CODE>; 2: wait <CODE>.
 * Return Value: Nothing.
 * Current callers: cortexQA/runServer.sqf after the smaller combined-arms component diagnostic.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACombinedOperation.sqf";
 */
params ["_check","_phase","_wait"];
private _groups=[];
private _objects=[];
private _attackGroups=[];
private _attackTeams=[];
private _origins=[];
private _objective=[5000,4000,0];
private _makeGroup={
    params ["_side","_name"];
    private _group=createGroup [_side,true];
    _group setGroupIdGlobal [_name];
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    _group allowFleeing 0;
    _groups pushBack _group;
    _group
};
private _publish={
    params ["_stage","_requester","_target","_assets",["_note",""]];
    missionNamespace setVariable ["Waldo_CortexQA_Combined",[
        "DYNAMIC COMBINED OPERATION",_stage,_requester,_target,_assets,serverTime,_note
    ],true];
};
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIPass_LambsMode","WMP"],
    ["Waldo_AIPass_Contact_Enable",true],["Waldo_AIPass_ContactReports_Enable",true],
    ["Waldo_AIPass_CoordinatedAssault_Enable",true],["Waldo_AIPass_Flank_Enable",true],
    ["Waldo_AIPass_Advance_Enable",true],["Waldo_AIPass_FireControl_Enable",true],
    ["Waldo_AIPass_Vehicles_Enable",true],
    ["Waldo_AIPass_VehicleGunnery_Enable",true],["Waldo_Cortex_AirAttack_Enable",true],
    ["Waldo_AIPass_Aggression",2],["Waldo_AIPass_Regroup_Enable",true],
    // Prove coordinated composition does not silently depend on ordinary reinforcement movement.
    ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_Reinforce_MaxResponders",0],
    ["Waldo_AIPass_Morale_Enable",false],
    ["Waldo_AIPass_Artillery_Enable",false]
]] call Waldo_fnc_CortexTuning;
["COMBINED-OP-independent-coordination-gate",
    missionNamespace getVariable ["Waldo_AIPass_CoordinatedAssault_Enable",false]
        && {!(missionNamespace getVariable ["Waldo_AIPass_Reinforce_Enable",true])}
        && {(missionNamespace getVariable ["Waldo_AIPass_Reinforce_MaxResponders",-1]) == 0},
    "Coordinated assault enabled while ordinary reinforcement is disabled and capped at zero"] call _check;

// The squads begin on separate axes and share only the defended objective. The ordinary SAD
// waypoint represents a Zeus/mission task; Cortex chooses how each group fights toward it.
private _starts=[[4820,3600,0],[5000,3540,0],[5180,3600,0]];
{
    private _teamIndex=_forEachIndex;
    private _group=[east,format ["Cortex manoeuvre %1",_teamIndex+1]] call _makeGroup;
    _group setVariable ["Waldo_AIPass_Profile","ELITE",true];
    _group setCombatMode "YELLOW";
    _group setFormation (["WEDGE","LINE","WEDGE"] select _teamIndex);
    private _members=[];
    for "_memberIndex" from 0 to 5 do {
        private _position=_x getPos [(_memberIndex mod 3)*3,180+30*floor (_memberIndex/3)];
        private _class=["O_Soldier_SL_F","O_Soldier_AR_F","O_Soldier_F"] select (_memberIndex min 2);
        private _unit=_group createUnit [_class,_position,[],0,"NONE"];
        _unit setDir (_unit getDir _objective);
        _unit setSkill ["spotDistance",0.95];
        _unit setSkill ["spotTime",0.95];
        _unit allowDamage false;
        _unit setVariable ["Waldo_CortexQA_CombinedShots",[]];
        _unit addEventHandler ["FiredMan",{
            params ["_unit","_weapon"];
            if !(_weapon in ["Put"]) then {
                private _shots=_unit getVariable ["Waldo_CortexQA_CombinedShots",[]];
                _shots pushBack [serverTime,abs speed _unit > 1,_weapon];
                _unit setVariable ["Waldo_CortexQA_CombinedShots",_shots,true];
            };
        }];
        _unit setVariable ["Waldo_CortexQA_Label",format ["MANOEUVRE %1.%2",_teamIndex+1,_memberIndex+1],true];
        _members pushBack _unit;
        _objects pushBack _unit;
        _origins pushBack [_unit,getPosATL _unit];
    };
    private _waypoint=_group addWaypoint [_objective,45];
    _waypoint setWaypointType "SAD";
    _waypoint setWaypointBehaviour "AWARE";
    _waypoint setWaypointCombatMode "YELLOW";
    _waypoint setWaypointSpeed "FULL";
    _attackGroups pushBack _group;
    _attackTeams pushBack _members;
} forEach _starts;

private _defenders=[west,"Cortex defended objective"] call _makeGroup;
_defenders setVariable ["Waldo_AIPass_Exclude",true,true];
_defenders setCombatMode "RED";
private _defenderUnits=[];
for "_index" from 0 to 7 do {
    private _position=[4910+(_index mod 4)*60,3975+floor (_index/4)*25,0];
    private _unit=_defenders createUnit [["B_Soldier_F","B_Soldier_AR_F"] select (_index mod 3 == 0),_position,[],0,"NONE"];
    _unit setDir 180;
    _unit setSkill ["spotDistance",0.9];
    _unit setSkill ["spotTime",0.9];
    _unit setUnitPos (["MIDDLE","UP"] select (_index mod 2));
    _unit disableAI "PATH";
    _unit allowDamage false;
    _unit setVariable ["Waldo_CortexQA_Label",format ["OBJECTIVE DEFENDER %1",_index+1],true];
    _objects pushBack _unit;
    _defenderUnits pushBack _unit;
};
for "_index" from 0 to 3 do {
    private _cover=createVehicle ["Land_HBarrier_3_F",[4910+_index*60,3990,0],[],0,"CAN_COLLIDE"];
    _cover setDir 0;
    _objects pushBack _cover;
};

private _apc=createVehicle ["O_APC_Tracked_02_cannon_F",[4660,3600,0],[],0,"NONE"];
_apc setDir (_apc getDir _objective);
createVehicleCrew _apc;
private _apcGroup=group driver _apc;
_apcGroup setGroupIdGlobal ["Cortex mobile fire support"];
_apcGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_apcGroup setVariable ["acex_headless_blacklist",true,true];
_apcGroup setCombatMode "RED";
_groups pushBackUnique _apcGroup;
_apc allowDamage false;
_apc limitSpeed 35;
_apc setVariable ["Waldo_CortexQA_CombinedShots",[]];
_apc addEventHandler ["Fired",{
    params ["_vehicle","_weapon"];
    private _shots=_vehicle getVariable ["Waldo_CortexQA_CombinedShots",[]];
    _shots pushBack [serverTime,_weapon];
    _vehicle setVariable ["Waldo_CortexQA_CombinedShots",_shots,true];
}];
private _apcDestination=[4820,3940,0];
private _apcStartDistance=_apc distance2D _apcDestination;
(driver _apc) doMove _apcDestination;
_apc setVariable ["Waldo_CortexQA_Label","MOBILE GROUND FIRE SUPPORT",true];
_objects pushBack _apc;
_objects append crew _apc;

private _air=createVehicle ["O_Heli_Attack_02_dynamicLoadout_F",[4650,3700,160],[],0,"FLY"];
_air setDir 90;
_air setVelocityModelSpace [0,45,0];
createVehicleCrew _air;
private _airGroup=group driver _air;
_airGroup setGroupIdGlobal ["Cortex air support"];
_airGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_airGroup setVariable ["acex_headless_blacklist",true,true];
_airGroup setCombatMode "RED";
_groups pushBackUnique _airGroup;
_air allowDamage false;
_air flyInHeight 160;
_air limitSpeed 170;
private _airOrigin=getPosATL _air;
(driver _air) doMove [5350,3700,160];
_air setVariable ["Waldo_CortexQA_Label","MOVING AIR SUPPORT",true];
_objects pushBack _air;
_objects append crew _air;

private _visualAssets=[];
{
    _visualAssets pushBack [_x,leader _x,format ["MANOEUVRE AXIS %1",_forEachIndex+1]];
} forEach _attackGroups;
_visualAssets append [[_apcGroup,_apc,"MOBILE GROUND FIRE"],[_airGroup,_air,"AIR ATTACK"]];
missionNamespace setVariable ["Waldo_CortexQA_Actors",(_objects select {_x isKindOf "CAManBase"})+[_apc,_air],true];

["CONTACT",_attackGroups select 1,_defenderUnits select 3,_visualAssets,
    "Three squads approach on separate axes. There is no assembly timer: contact, movement and support may begin independently."] call _publish;
["Combined operation / 1. Natural contact",
    "A defended objective faces three separated manoeuvre squads, mobile armour and moving air support. The squads have one ordinary objective; Cortex must compose tactics from live contact without a rally schedule or shared start barrier.",
    [5000,3780,0]] call _phase;
private _contact=[{
    ({private _leader=leader _x; _defenderUnits findIf {_leader knowsAbout _x >= 1} >= 0} count _attackGroups) >= 2
},60] call _wait;
["COMBINED-OP-natural-contact",_contact,str (_attackGroups apply {private _leader=leader _x; _defenderUnits apply {_leader knowsAbout _x}})] call _check;

["MANOEUVRE",_attackGroups select 1,_defenderUnits select 3,_visualAssets,
    "Existing squad behaviours and support arms act concurrently. Watch actual movement, shots and changing drill states."] call _publish;
["Combined operation / 2. Concurrent manoeuvre and fires",
    "Look for distinct approaches, more than one squad moving, fire during movement, APC route progress and an aircraft attack controller. A role, waypoint or accepted drill alone cannot pass.",
    [5000,3850,0]] call _phase;
private _drillSeen=[false,false,false];
private _peakTravel=[0,0,0];
private _firstInfantryFire=-1;
private _firstGroundFire=-1;
private _firstAirControl=-1;
private _maxMovingGroups=0;
private _idleTicks=0;
private _maxIdleTicks=0;
private _lastInfantryShotCount=0;
private _until=diag_tickTime+150;
while {diag_tickTime < _until} do {
    private _movingGroups=0;
    private _infantryShotCount=0;
    {
        private _teamIndex=_forEachIndex;
        private _state=_x getVariable ["Waldo_AIPass_State",createHashMap];
        private _drill=_state getOrDefault ["drill",createHashMap];
        if (count _drill > 0) then {_drillSeen set [_teamIndex,true]};
        private _moving={alive _x && {abs speed _x > 1.5}} count (_attackTeams select _teamIndex);
        if (_moving >= 2) then {_movingGroups=_movingGroups+1};
        private _teamPeak=0;
        {
            private _origin=(_origins select ((_teamIndex*6)+_forEachIndex)) select 1;
            _teamPeak=_teamPeak max (_x distance2D _origin);
            private _shots=_x getVariable ["Waldo_CortexQA_CombinedShots",[]];
            _infantryShotCount=_infantryShotCount+count _shots;
            if (_firstInfantryFire < 0 && {_shots isNotEqualTo []}) then {_firstInfantryFire=(_shots select 0) select 0};
            _x setVariable ["Waldo_CortexQA_Label",format ["M%1.%2 | %3/%4 | %5 | %6 km/h | shots %7",
                _teamIndex+1,_forEachIndex+1,
                _drill getOrDefault ["type",_state getOrDefault ["phase","CONTACT"]],
                _drill getOrDefault ["stage","FREE"],stance _x,round abs speed _x,count _shots],true];
        } forEach (_attackTeams select _teamIndex);
        _peakTravel set [_teamIndex,(_peakTravel select _teamIndex) max _teamPeak];
    } forEach _attackGroups;
    _maxMovingGroups=_maxMovingGroups max _movingGroups;
    // A base of fire is deliberately stationary. Count fresh real fire as activity so this
    // assertion detects an operation-wide lull rather than mislabelling effective cover as idle.
    if (_movingGroups == 0 && {_infantryShotCount == _lastInfantryShotCount}) then {_idleTicks=_idleTicks+1} else {_idleTicks=0};
    _lastInfantryShotCount=_infantryShotCount;
    _maxIdleTicks=_maxIdleTicks max _idleTicks;
    private _groundShots=_apc getVariable ["Waldo_CortexQA_CombinedShots",[]];
    if (_firstGroundFire < 0 && {_groundShots isNotEqualTo []}) then {_firstGroundFire=(_groundShots select 0) select 0};
    if (_firstAirControl < 0 && {_air getVariable ["Waldo_Cortex_AirAttackJob",false]
        || {(_air getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []}}) then {_firstAirControl=serverTime};
    sleep 2;
};
private _squadShots=_attackTeams apply {
    private _total=0;
    {_total=_total+count (_x getVariable ["Waldo_CortexQA_CombinedShots",[]])} forEach _x;
    _total
};
private _movingShots=_attackTeams apply {
    private _total=0;
    {_total=_total+({_x select 1} count (_x getVariable ["Waldo_CortexQA_CombinedShots",[]]))} forEach _x;
    _total
};
private _activeFireSquads={_x > 0} count _squadShots;
private _travelSquads={_x >= 35} count _peakTravel;
private _drillSquads={_x} count _drillSeen;
["COMBINED-OP-separated-approaches",(_starts select 0) distance2D (_starts select 1) >= 100
    && {(_starts select 1) distance2D (_starts select 2) >= 100},str _starts] call _check;
["COMBINED-OP-multiple-squads-manoeuvred",_travelSquads >= 2 && {_maxMovingGroups >= 2},str [_peakTravel,_maxMovingGroups]] call _check;
["COMBINED-OP-composed-tactics",_drillSquads >= 2,str _drillSeen] call _check;
["COMBINED-OP-infantry-actual-fire",_activeFireSquads >= 2,str _squadShots] call _check;
["COMBINED-OP-fire-while-moving",({_x > 0} count _movingShots) >= 1,str _movingShots] call _check;
["COMBINED-OP-no-operation-wide-pause",_maxIdleTicks <= 10,format ["longest infantry movement/fire lull=%1 seconds",_maxIdleTicks*2]] call _check;
["COMBINED-OP-ground-route-and-fire",_apc distance2D _apcDestination < _apcStartDistance-50
    && {count (_apc getVariable ["Waldo_CortexQA_CombinedShots",[]]) > 0},
    str [_apcStartDistance,_apc distance2D _apcDestination,_apc getVariable ["Waldo_CortexQA_CombinedShots",[]]]] call _check;
["COMBINED-OP-air-controller-and-travel",_firstAirControl >= 0 && {_air distance2D _airOrigin >= 100},
    str [_firstAirControl,_air distance2D _airOrigin,_air getVariable ["Waldo_Cortex_AirAttackPlan",[]]]] call _check;
private _actionTimes=[_firstInfantryFire,_firstGroundFire,_firstAirControl] select {_x >= 0};
["COMBINED-OP-concurrent-arms",count _actionTimes == 3 && {(selectMax _actionTimes)-(selectMin _actionTimes) <= 60},str _actionTimes] call _check;

["HANDOVER",_attackGroups select 1,_defenderUnits select 3,_visualAssets,
    "Support roles expire independently; infantry retains its ordinary objective and no global completion gate is installed."] call _publish;
["Combined operation / 3. Independent handover",
    "The operation must remain usable when a support arm is late or finishes. Check that no common readiness token or operation-wide movement lease exists and ordinary objectives remain available.",
    [5000,3900,0]] call _phase;
private _leaseTokens=[];
{
    private _lease=_x getVariable ["Waldo_AIPass_SupportLease",[]];
    if (_lease isNotEqualTo []) then {_leaseTokens pushBack (_lease param [0,""])};
} forEach _attackGroups;
private _sharedLease=count _leaseTokens > 1 && {{_x == (_leaseTokens select 0)} count _leaseTokens > 1};
["COMBINED-OP-no-shared-completion-barrier",!_sharedLease,
    str [_leaseTokens,_attackGroups apply {waypoints _x}]] call _check;

missionNamespace setVariable ["Waldo_CortexQA_Combined",["DYNAMIC COMBINED OPERATION","CLEANUP",grpNull,objNull,[],serverTime,
    "The component diagnostic remains separate; all operation fixtures are now being removed."],true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{if (!isNull _x) then {deleteVehicle _x}} forEach _objects;
{if (!isNull _x) then {deleteGroup _x}} forEach _groups;
missionNamespace setVariable ["Waldo_CortexQA_Combined",[],true];
