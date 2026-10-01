/*
 * Author: WaldoTheWarfighter
 * Compares physical building entry using independent engine commands across small and large,
 * single- and multi-storey house models, then exercises production garrison and clearance.
 * Locality/authority: scheduled dedicated-server audit; all actors are pinned to this owner.
 * Repeat/JIP: disposable actors and houses are removed; observer state is public for joining clients.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; all required audit callbacks.
 * Return: Nothing. Current callers: cortexQA/runServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQABuildings.sqf";
 */
params ["_check","_phase","_wait"];
private _cases = [];
private _actors = [];
{
    private _class = _x;
    private _row = _forEachIndex;
    {
        private _method = _x;
        private _house = createVehicle [_class,[6250+_forEachIndex*60,5800+_row*60,0],[],0,"NONE"];
        _house enableSimulationGlobal true;
        private _group = createGroup [east,true];
        _group setVariable ["Waldo_AIPass_Exclude",true,true];
        _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        _group setVariable ["acex_headless_blacklist",true,true];
        private _unit = _group createUnit ["O_Soldier_F",_house getPos [25,180],[],0,"NONE"];
        _unit setVariable ["acex_headless_blacklist",true,true];
        _unit allowDamage false;
        private _target = (_house buildingPos -1) param [0,[]];
        private _label = format ["%1 / model %2",_method,_row+1];
        _unit setVariable ["Waldo_CortexQA_Label",_label,true];
        _unit setVariable ["Waldo_CortexQA_Target",_target,true];
        _actors pushBack _unit;
        _cases pushBack [_group,_unit,_house,_target,_method,_label,false];
    } forEach ["DIRECT","HOUSE-WAYPOINT","REPLAN"];
} forEach ["Land_i_House_Small_03_V1_F","Land_i_House_Small_01_V1_F","Land_i_House_Big_01_V1_F","Land_i_House_Big_02_V1_F"];
missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors,true];
["Building entry: independent comparisons","Twelve excluded soldiers compare direct movement, a building-attached waypoint and forced path replanning across small and large, single- and multi-storey houses. Cyan trails show actual movement; targets show remaining distance. Each model reports independently and does not replace the production clearance cases.",[6280,5890,0]] call _phase;
{
    _x params ["_group","_unit","_house","_target","_method","_label"];
    private _valid = simulationEnabled _house && {simulationEnabled _unit} && {local _unit} && {_target isNotEqualTo []};
    [format ["BUILD-%1-ready",_label],_valid] call _check;
    if (_valid) then {
        if (_method in ["DIRECT","REPLAN"]) then {doStop _unit; _unit doMove _target; if (_method == "REPLAN") then {_unit setDestination [_target,"LEADER PLANNED",true]}} else {
            private _wp = _group addWaypoint [getPosATL _house,0];
            _wp setWaypointType "MOVE";
            _wp waypointAttachObject _house;
            _wp setWaypointHousePosition 0;
            _group setCurrentWaypoint _wp;
        };
    };
} forEach _cases;
private _deadline = time + 90;
waitUntil {
    sleep 2;
    {
        _x params ["_group","_unit","_house","_target","_method","_label"];
        if (_target isNotEqualTo [] && {alive _unit} && {_unit distance _target <= 2}) then {_x set [6,true]};
    } forEach _cases;
    time >= _deadline || {_cases findIf {!(_x select 6)} < 0}
};
{
    _x params ["_group","_unit","_house","_target","_method","_label","_arrived"];
    [format ["BUILD-%1-arrival",_label],_arrived,format ["class=%1 owner=%2 simulation=%3 position=%4 target=%5 command=%6 expected=%7",typeOf _house,groupOwner _group,simulationEnabled _unit,getPosATL _unit,_target,currentCommand _unit,expectedDestination _unit]] call _check;
} forEach _cases;
sleep 15;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{_x params ["_group","_unit","_house"]; deleteVehicle _unit; deleteGroup _group; deleteVehicle _house} forEach _cases;

// Primary integration path: installed LAMBS Waypoints owns the public GARRISON and CQB orders.
// Native Cortex fallback cases remain below and are always invoked with useLambs=false.
private _lambsWaypointsLoaded=isClass (configFile >> "CfgPatches" >> "lambs_wp");
["LAMBS-building-backend-available-or-optional",true,
    ["Optional LAMBS Waypoints is absent; its primary-backend cases are skipped and native fallback still runs.",
     "Installed LAMBS Waypoints detected; primary-backend cases are active."] select _lambsWaypointsLoaded] call _check;
if (_lambsWaypointsLoaded) then {
private _house=createVehicle ["Land_i_House_Small_01_V1_F",[6250,5800,0],[],0,"NONE"];
_house enableSimulationGlobal true;
private _group=createGroup [east,true];
_group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_group setVariable ["acex_headless_blacklist",true,true];
private _members=[];
for "_i" from 0 to 2 do {
    private _unit=_group createUnit ["O_Soldier_F",[6250+_i*3,5770,0],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["LAMBS BUILDING %1",_i+1],true];
    _members pushBack _unit;
};
missionNamespace setVariable ["Waldo_CortexQA_Actors",_members,true];
private _rooms=_house buildingPos -1;
private _visits=_rooms apply {false};
private _memberVisits=_members apply {[]};
["LAMBS garrison: physical occupation","The ordinary Cortex garrison order must delegate to installed LAMBS Waypoints. Every soldier must physically enter a real building position and remain there. Backend selection or a waypoint alone does not pass.",getPosATL _house] call _phase;
private _garrisonAccepted=[_group,_house,20] call Waldo_fnc_CortexGarrison;
private _garrisonBackend=_group getVariable ["Waldo_Cortex_BuildingBackend",[]];
["GARRISON-lambs-backend",_garrisonAccepted && {(_garrisonBackend param [0,""]) == "LAMBS"} && {(_garrisonBackend param [1,""]) == "GARRISON"},str _garrisonBackend] call _check;
private _garrisonArrived=[{
    _members findIf {
        private _unit=_x;
        !alive _unit || {_rooms findIf {_unit distance _x <= 2.5} < 0}
    } < 0
},120] call _wait;
["GARRISON-lambs-physical-arrival",_garrisonArrived,str (_members apply {[getPosATL _x,currentCommand _x,expectedDestination _x]})] call _check;
sleep 8;
private _garrisonHeld=_garrisonArrived && {_members findIf {
    private _unit=_x;
    !alive _unit || {_rooms findIf {_unit distance _x <= 3} < 0}
} < 0};
["GARRISON-lambs-physical-hold",_garrisonHeld,str (_members apply {getPosATL _x})] call _check;
{_x setUnitPos "DOWN"} forEach _members;
["LAMBS garrison release","The soldiers now have an explicit prone stance. Releasing the delegated task must stop its controller while preserving that later stance.",getPosATL _house] call _phase;
private _garrisonReleased=[_group] call Waldo_fnc_CortexGarrisonRelease;
sleep 2;
["GARRISON-lambs-release-preserves-later-stance",_garrisonReleased
    && {_members findIf {!alive _x || {unitPos _x != "DOWN"}} < 0}
    && {(_group getVariable ["Waldo_Cortex_BuildingBackend",[]]) isEqualTo []},
    str (_members apply {unitPos _x})] call _check;
{_x setUnitPos "AUTO"} forEach _members;
{private _exit=[6250+_forEachIndex*3,5770,0]; doStop _x; _x doMove _exit; _x setDestination [_exit,"LEADER PLANNED",true]} forEach _members;
["LAMBS-CLEAR-outside-start",[{_members findIf {_x distance2D [6253,5770,0] > 8} < 0},45] call _wait] call _check;
["LAMBS CQB: physical flow","The ordinary Cortex clearance order must delegate to installed LAMBS Waypoints. At least two soldiers must physically enter, and the team must traverse multiple real room positions. A running task marker alone does not pass.",getPosATL _house] call _phase;
private _clearStart=_members apply {getPosATL _x};
private _clearAccepted=[_group,_house] call Waldo_fnc_CortexClearBuilding;
private _clearBackend=_group getVariable ["Waldo_Cortex_BuildingBackend",[]];
["CLEAR-lambs-backend",_clearAccepted && {(_clearBackend param [0,""]) == "LAMBS"} && {(_clearBackend param [1,""]) == "CQB"},str _clearBackend] call _check;
private _clearObserved=[{
    {
        private _room=_x;
        private _roomIndex=_forEachIndex;
        {
            private _worker=_x;
            if (alive _worker && {(getPosASL _worker) vectorDistance (AGLToASL _room) <= 2}) then {
                _visits set [_roomIndex,true];
                (_memberVisits select _forEachIndex) pushBackUnique _roomIndex;
            };
        } forEach _members;
    } forEach _rooms;
    missionNamespace setVariable ["Waldo_CortexQA_Rooms",[_rooms,_visits],true];
    ({_x isNotEqualTo []} count _memberVisits) >= 2 && {({_x} count _visits) >= 2}
},150] call _wait;
private _participants={_x isNotEqualTo []} count _memberVisits;
private _visitedCount={_x} count _visits;
["CLEAR-lambs-multiple-soldiers-enter",_clearObserved && {_participants >= 2},str _memberVisits] call _check;
["CLEAR-lambs-multiple-rooms-traversed",_clearObserved && {_visitedCount >= 2},str _visits] call _check;
private _physicallyTravelled=false;
for "_memberIndex" from 0 to ((count _members)-1) do {
    if ((_members select _memberIndex) distance2D (_clearStart select _memberIndex) >= 12) then {
        _physicallyTravelled=true;
    };
};
["CLEAR-lambs-physical-travel",_physicallyTravelled,str (_members apply {getPosATL _x})] call _check;
private _released=[_group,false] call Waldo_fnc_CortexClearRelease;
private _handoverStart=_members apply {getPosATL _x};
private _handoverDestination=[6330,5770,0];
private _waypoint=_group addWaypoint [_handoverDestination,0];
_waypoint setWaypointType "MOVE";
_group setCurrentWaypoint _waypoint;
["LAMBS CQB handover","The delegated CQB loop has been released. The same squad must obey a fresh ordinary waypoint without returning to the building.",_handoverDestination] call _phase;
private _handoverMoved=[{
    private _allMoved=true;
    for "_memberIndex" from 0 to ((count _members)-1) do {
        private _unit=_members select _memberIndex;
        if (!alive _unit || {_unit distance2D (_handoverStart select _memberIndex) < 20}) then {
            _allMoved=false;
        };
    };
    _allMoved
},90] call _wait;
["CLEAR-lambs-release-clears-backend",_released && {(_group getVariable ["Waldo_Cortex_BuildingBackend",[]]) isEqualTo []}] call _check;
["CLEAR-lambs-replacement-order-physical",_handoverMoved,str (_members apply {[getPosATL _x,currentCommand _x]})] call _check;
missionNamespace setVariable ["Waldo_CortexQA_Rooms",[],true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach _members;
deleteGroup _group;
deleteVehicle _house;
};

// Fresh groups distinguish clearance defects from state left by a previous garrison.
// Keep all original comparisons above, including their failures.
{
    _x params ["_size","_class"];
    private _house=createVehicle [_class,[6250,5800,0],[],0,"NONE"];
    _house enableSimulationGlobal true;
    private _group=createGroup [east,true];
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    private _members=[];
    for "_i" from 0 to (_size-1) do {
        private _unit=_group createUnit ["O_Soldier_F",[6235+(_i mod 4)*4,5760-floor(_i/4)*4,0],[],0,"NONE"];
        _unit setVariable ["acex_headless_blacklist",true,true];
        _unit setVariable ["Waldo_CortexQA_Label",format ["FRESH CLEAR %1 / soldier %2",_size,_i+1],true];
        _members pushBack _unit;
    };
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_members,true];
    [format ["Fresh clearance: %1 soldiers / %2",_size,_class],"This fresh group has never garrisoned. Watch clearing pairs physically enter and continue through their assigned sector. The 2/6/12-person cases use progressively larger building models. Markers are navigation positions, not proof that a hostile room is safe. No test-side teleport, door opening or forced completion is applied.",getPosATL _house] call _phase;
    private _rooms=_house buildingPos -1;
    private _visits=_rooms apply {false};
    // Every committed soldier, including the leader, owns a production clearance lane.
    // Audit exactly that set rather than preserving the superseded exterior-leader assumption.
    private _clearingMembers=+_members;
    private _memberVisits=_clearingMembers apply {[]};
    private _accepted=[_group,_house,createHashMapFromArray [["useLambs",false]]] call Waldo_fnc_CortexClearBuilding;
    [format ["CLEAR-fresh-%1-accepted",_size],_accepted] call _check;
    [{
        {private _room=_x; private _roomIndex=_forEachIndex; if (_clearingMembers findIf {alive _x && {(getPosASL _x) vectorDistance (AGLToASL _room) <= 1.5}} >= 0) then {_visits set [_roomIndex,true]}} forEach _rooms;
        {
            private _worker=_x;
            private _seen=_memberVisits select _forEachIndex;
            {if (alive _worker && {(getPosASL _worker) vectorDistance (AGLToASL _x) <= 1.5}) then {_seen pushBackUnique _forEachIndex}} forEach _rooms;
        } forEach _clearingMembers;
        missionNamespace setVariable ["Waldo_CortexQA_Rooms",[_rooms,_visits],true];
        ((_group getVariable ["Waldo_Cortex_ClearResult",[]]) param [0,""]) in ["COMPLETE","INCOMPLETE"]
    },245] call _wait;
    private _physical=_rooms isNotEqualTo [] && {_visits findIf {!_x} < 0};
    [format ["CLEAR-fresh-%1-physical-room-visits",_size],_physical,format ["visits=%1 units=%2",_visits,_members apply {[getPosATL _x,currentCommand _x,expectedDestination _x,_x checkAIFeature "PATH",_x checkAIFeature "MOVE",behaviour _x]}]] call _check;
    [format ["CLEAR-fresh-%1-result-agrees",_size],_physical && {((_group getVariable ["Waldo_Cortex_ClearResult",[]]) param [0,""]) == "COMPLETE"}] call _check;
    [format ["CLEAR-fresh-%1-successive-positions",_size],_memberVisits findIf {count _x >= 2} >= 0,str _memberVisits] call _check;
    if (_size == 2) then {
        ["CLEAR-fresh-2-both-participate",_memberVisits findIf {_x isEqualTo []} < 0,str _memberVisits] call _check;
    };
    // Exercise natural completion/failure cleanup before invoking any explicit release.
    // A fresh ordinary waypoint must take control even when some rooms were unreachable.
    private _destination=[6325,5770,0];
    private _beforeMove=_members apply {getPosATL _x};
    private _waypoint=_group addWaypoint [_destination,0];
    _waypoint setWaypointType "MOVE";
    _group setCurrentWaypoint _waypoint;
    [format ["Clearance handover: %1 soldiers",_size],"After the recorded clearance result, the same soldiers must follow an ordinary waypoint away from the building. No cleanup function or movement reset is injected before this check.",_destination] call _phase;
    private _moved=[{
        private _allMoved=true;
        {
            if (!alive _x || {_x distance2D (_beforeMove select _forEachIndex) < 25} || {_x distance2D _destination > 18}) then {_allMoved=false};
        } forEach _members;
        _allMoved
    },90] call _wait;
    [format ["CLEAR-fresh-%1-handover-physical",_size],_moved,str (_members apply {getPosATL _x})] call _check;
    sleep 8;
    [_group] call Waldo_fnc_CortexClearRelease;
    missionNamespace setVariable ["Waldo_CortexQA_Rooms",[],true];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    {deleteVehicle _x} forEach _members;
    deleteGroup _group;
    deleteVehicle _house;
} forEach [[2,"Land_i_House_Small_01_V1_F"],[6,"Land_i_House_Big_01_V1_F"],[12,"Land_i_House_Big_02_V1_F"]];

// A casualty inside the clearing element must not strand the shared room queue. Use ten soldiers
// so the production eight-worker cap leaves a genuine squad reserve available as a replacement.
private _casualtyHouse=createVehicle ["Land_i_House_Big_01_V1_F",[6250,5800,0],[],0,"NONE"];
_casualtyHouse enableSimulationGlobal true;
private _casualtyGroup=createGroup [east,true];
_casualtyGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_casualtyGroup setVariable ["acex_headless_blacklist",true,true];
private _casualtyMembers=[];
for "_i" from 0 to 9 do {
    private _unit=_casualtyGroup createUnit ["O_Soldier_F",[6230+(_i mod 5)*4,5760-floor(_i/5)*4,0],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["CQB CASUALTY / soldier %1",_i+1],true];
    _casualtyMembers pushBack _unit;
};
missionNamespace setVariable ["Waldo_CortexQA_Actors",_casualtyMembers,true];
["CQB casualty reinforcement","The ten-person squad starts with eight independent clearing workers and two reserves. One clearing soldier becomes a real casualty. A surviving reserve must join the clear and physically move toward the building; the remaining room queue must stay active.",getPosATL _casualtyHouse] call _phase;
private _casualtyAccepted=[_casualtyGroup,_casualtyHouse,createHashMapFromArray [["useLambs",false]]] call Waldo_fnc_CortexClearBuilding;
["CLEAR-casualty-order-accepted",_casualtyAccepted] call _check;
private _jobStarted=[{_casualtyGroup getVariable ["Waldo_AIPass_ClearBuilding",false]},15] call _wait;
["CLEAR-casualty-job-started",_jobStarted] call _check;
private _casualty=_casualtyMembers select 1;
private _reserve=_casualtyMembers select 9;
private _reserveStart=getPosATL _reserve;
private _evidenceBefore=count (_casualtyGroup getVariable ["Waldo_Cortex_ClearReinforcements",[]]);
_casualty setDamage 1;
private _reinforced=[{
    private _evidence=_casualtyGroup getVariable ["Waldo_Cortex_ClearReinforcements",[]];
    count _evidence > _evidenceBefore
        && {_evidence findIf {(_x param [1,""]) == netId _casualty && {(_x param [2,""]) == netId _reserve}} >= 0}
},30] call _wait;
["CLEAR-casualty-reserve-assigned",_reinforced,str (_casualtyGroup getVariable ["Waldo_Cortex_ClearReinforcements",[]])] call _check;
private _replacementMoved=[{
    alive _reserve
        && {_reserve distance2D _reserveStart >= 8
            || {(_casualtyHouse buildingPos -1) findIf {(getPosASL _reserve) vectorDistance (AGLToASL _x) <= 1.5} >= 0}}
},60] call _wait;
["CLEAR-casualty-reserve-physical-movement",_replacementMoved,format ["start=%1 actual=%2 command=%3 expected=%4",_reserveStart,getPosATL _reserve,currentCommand _reserve,expectedDestination _reserve]] call _check;
private _continuing=(_casualtyGroup getVariable ["Waldo_AIPass_ClearBuilding",false])
    || {((_casualtyGroup getVariable ["Waldo_Cortex_ClearResult",[]]) param [0,""]) in ["COMPLETE","INCOMPLETE"]};
["CLEAR-casualty-controller-continues",_continuing] call _check;
[_casualtyGroup] call Waldo_fnc_CortexClearRelease;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach _casualtyMembers;
deleteGroup _casualtyGroup;
deleteVehicle _casualtyHouse;

// Exercise door handling through the real clearance job, never by calling its helper directly.
private _doorHouse=createVehicle ["Land_i_House_Small_01_V1_F",[6250,5800,0],[],0,"NONE"];
_doorHouse enableSimulationGlobal true;
private _doorGroup=createGroup [east,true];
_doorGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_doorGroup setVariable ["acex_headless_blacklist",true,true];
private _doorMembers=[];
for "_i" from 0 to 1 do {
    private _unit=_doorGroup createUnit ["O_Soldier_F",[6250+_i*3,5770,0],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["DOOR ORDER %1",_i+1],true];
    _doorMembers pushBack _unit;
};
missionNamespace setVariable ["Waldo_CortexQA_Actors",_doorMembers,true];
private _doorSource="Door_1_sound_source";
private _doorReady=isClass (configOf _doorHouse >> "AnimationSources" >> _doorSource)
    && {_doorHouse animationSourcePhase _doorSource < 0.1}
    && {(_doorHouse selectionPosition ["Door_1_trigger","Memory"]) isNotEqualTo [0,0,0]};
["CLEAR-door-fixture-closed-recognised",_doorReady] call _check;
_doorHouse setVariable ["bis_disabled_Door_1",1,true];
["Clearance: locked entry","The real clearance order must not unlock the front door. This phase checks the actual door phase and lock variable; it does not count an accepted order as entry.",getPosATL _doorHouse] call _phase;
private _doorAccepted=[_doorGroup,_doorHouse,createHashMapFromArray [["useLambs",false]]] call Waldo_fnc_CortexClearBuilding;
["CLEAR-door-order-accepted",_doorAccepted] call _check;
private _lockHeld=true;
private _lockedUntil=time+35;
waitUntil {
    sleep 1;
    if (_doorHouse animationSourcePhase _doorSource > 0.1 || {(_doorHouse getVariable ["bis_disabled_Door_1",0]) != 1}) then {_lockHeld=false};
    time >= _lockedUntil
};
["CLEAR-door-lock-preserved",_doorReady && {_doorAccepted} && {_lockHeld}] call _check;
// Changing the lock is the test stimulus; opening and entry must be performed by production.
_doorHouse setVariable ["bis_disabled_Door_1",0,true];
["Clearance: entry unlocked","The lock is now removed. Watch the same soldiers open the door and physically enter. The audit does not animate the door, teleport actors or reset their movement.",getPosATL _doorHouse] call _phase;
private _doorOpened=[{_doorHouse animationSourcePhase _doorSource >= 0.8},45] call _wait;
["CLEAR-door-unlocked-opens",_doorReady && {_doorOpened}] call _check;
private _doorPositions=_doorHouse buildingPos -1;
private _entered=[{_doorPositions findIf {
    private _position=_x;
    _doorMembers findIf {(getPosASL _x) vectorDistance (AGLToASL _position) <= 1.5} >= 0
} >= 0},45] call _wait;
["CLEAR-door-unlocked-physical-entry",_doorReady && {_doorOpened} && {_entered}] call _check;
[_doorGroup] call Waldo_fnc_CortexClearRelease;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach _doorMembers;
deleteGroup _doorGroup;
deleteVehicle _doorHouse;
