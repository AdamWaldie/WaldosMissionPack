/*
 * Author: WaldoTheWarfighter
 * Runs disposable Cortex acceptance cases through real public functions and records RPT results.
 * Locality/authority: dedicated server only; only staged by the audit launcher's explicit CortexAudit switch.
 * Repeat/JIP: one run per machine; fresh fixtures are cleaned up, no production JIP replay.
 * Arguments: None. Waldo_CortexQA_Focus selects the staged batch; airskills runs aircraft and
 * AI-profile/vehicle-crew mechanics together, while supportflows runs coordinated manoeuvre plus
 * combined-arms composition in one process without unrelated feature suites. terrain runs a
 * measured-relief prerequisite and physical infantry, vehicle and defence traversal batch.
 * Return: Nothing (scheduled script).
 * Current callers: staged audit continuation. Example: [] execVM "cortexQAServer.sqf";
 */
if (!isServer || {missionNamespace getVariable ["Waldo_CortexQA_ServerRunning",false]}) exitWith {};
missionNamespace setVariable ["Waldo_CortexQA_ServerRunning",true];
waitUntil {sleep 0.5; !isNil "Waldo_fnc_CortexTuning" && {missionNamespace getVariable ["Waldo_FeatureConfigsReady",false] || {time > 30}}};
private _failures = [];
private _focus = missionNamespace getVariable ["Waldo_CortexQA_Focus","all"];
missionNamespace setVariable ["Waldo_CortexQA_Results",[],true];
private _phase = {params ["_title","_expected","_position"]; missionNamespace setVariable ["Waldo_CortexQA_Phase",[_title,_expected,_position,serverTime],true]; sleep 8};
private _readyUntil = diag_tickTime + 120;
waitUntil {sleep 0.5; missionNamespace getVariable ["Waldo_CortexQA_GuideReady",false] || {diag_tickTime > _readyUntil}};
private _check = {params ["_id","_ok",["_detail",""]]; diag_log format ["WMP CORTEX QA|%1|%2|%3",_id,["FAIL","PASS"] select _ok,_detail]; if (!_ok) then {_failures pushBack _id}; private _results = missionNamespace getVariable ["Waldo_CortexQA_Results",[]]; _results pushBack [_id,["FAIL","PASS"] select _ok]; missionNamespace setVariable ["Waldo_CortexQA_Results",_results,true]};
private _wait = {params ["_condition",["_seconds",15]]; private _until = diag_tickTime + _seconds; waitUntil {sleep 0.2; call _condition || {diag_tickTime >= _until}}; call _condition};
private _saved = createHashMapFromArray (([] call Waldo_fnc_CortexTuningSpec) apply {[_x select 0,missionNamespace getVariable [_x select 0,_x select 5]]});
if (_focus == "terrain") then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQATerrain.sqf"};
private _group = grpNull;
private _house = objNull;
if (_focus in ["all","features","infantry"]) then {
_group = createGroup [east,true];
private _u1 = _group createUnit ["O_Soldier_F",[6000,6000,0],[],0,"NONE"];
private _u2 = _group createUnit ["O_Soldier_F",[6003,6000,0],[],0,"NONE"];
_group setGroupIdGlobal ["Cortex QA Infantry"];
missionNamespace setVariable ["Waldo_CortexQA_Infantry",_group,true];
_house = missionNamespace getVariable ["qa_cortex_path_house",objNull];
if (isNull _house) then {_house = createVehicle ["Land_i_House_Small_03_V1_F",[6025,6000,0],[],0,"NONE"]};
_house enableSimulationGlobal true;
diag_log format ["WMP CORTEX QA BUILDING NEIGHBOURS: %1",(nearestObjects [_house,["House","Building"],20,true]) apply {[typeOf _x,netId _x,getPosATL _x,simulationEnabled _x]}];
diag_log format ["WMP CORTEX QA BUILDING: class=%1 simulation=%2 pos=%3 positions=%4",typeOf _house,simulationEnabled _house,getPosATL _house,_house buildingPos -1];
private _baselineGroup = createGroup [east,true];
_baselineGroup setVariable ["Waldo_AIPass_Exclude",true,true];
_baselineGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_baselineGroup setVariable ["acex_headless_blacklist",true,true];
_baselineGroup setGroupIdGlobal ["QA engine-only comparison"];
private _baseline = _baselineGroup createUnit ["O_Soldier_F",[(getPosATL _house select 0),(getPosATL _house select 1)-35,0],[],0,"NONE"];
_baseline setVariable ["acex_headless_blacklist",true,true];
private _baselineTarget = (_house buildingPos -1) param [2,[]];
if (_baselineTarget isNotEqualTo []) then {doStop _baseline; _baseline doMove _baselineTarget};
["Infantry orders","The two soldiers defend, occupy the house, then release those orders. An empty garrison request must preserve defence.",[6010,6000,0]] call _phase;
[createHashMapFromArray [["Waldo_AIPass_Enable",false]]] call Waldo_fnc_CortexTuning;
sleep 2;
["ORD-01-disabled-explanation",([_group,"DEFEND"] call Waldo_fnc_CortexOrderReason) find "disabled" >= 0] call _check;
[createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIPass_LambsMode","WMP"],["Waldo_AIPass_Contact_Enable",false],["Waldo_AIPass_Regroup_Enable",false]]] call Waldo_fnc_CortexTuning;
[{missionNamespace getVariable ["Waldo_AIPass_Active",false]},20] call _wait;
private _order = {params ["_action",["_position",[6000,6010,0]],["_building",objNull]]; [[["order",_action],["group",_group],["position",_position],["building",_building],["radius",40],["facing",90]],2] call Waldo_fnc_CortexOrderDispatch; sleep 2};
["DEFEND"] call _order;
["ORD-02-defend-accepted",(_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo []] call _check;
private _atAssigned = {
    params ["_key",["_distance",3]];
    private _members = units _group;
    if (diag_tickTime >= (missionNamespace getVariable ["Waldo_CortexQA_NextInfantryDiagnostic",0])) then {
        missionNamespace setVariable ["Waldo_CortexQA_NextInfantryDiagnostic",diag_tickTime+10];
        diag_log format ["WMP CORTEX QA INFANTRY: key=%1 owner=%2 units=%3",_key,groupOwner _group,_members apply {[_x,getPosATL _x,_x getVariable [_key,[]],currentCommand _x,expectedDestination _x,speed _x,_x checkAIFeature "PATH",alive _x]}];
    };
    count _members == 2 && {_members findIf {private _assignment = _x getVariable [_key,[]]; !alive _x || {_assignment isEqualTo []} || {_x distance (_assignment select 0) > _distance}} < 0}
};
["Defence movement","Both soldiers must walk to their assigned defensive positions and stay there. An accepted order alone does not pass this stage.",[6000,6020,0]] call _phase;
["ORD-02b-defence-arrival",[{["Waldo_AIPass_DefendPos",3.5] call _atAssigned},95] call _wait] call _check;
sleep 5;
["ORD-02c-defence-hold",["Waldo_AIPass_DefendPos",3.5] call _atAssigned] call _check;
["GARRISON",[8000,8000,0]] call _order;
["ORD-03-empty-garrison-preserves-defend",(_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo [] && {(_group getVariable ["Waldo_AIPass_Garrison",[]]) isEqualTo []}] call _check;
["GARRISON",getPosATL _house] call _order;
private _housePositions=_house buildingPos -1;
private _atHouse={
    _housePositions isNotEqualTo [] && {units _group findIf {
        private _unit=_x;
        !alive _unit || {_housePositions findIf {_unit distance _x <= 2.5} < 0}
    } < 0}
};
private _buildingBackend=_group getVariable ["Waldo_Cortex_BuildingBackend",[]];
private _lambsBuilding=isClass (configFile >> "CfgPatches" >> "lambs_wp");
private _garrisonAccepted=if (_lambsBuilding) then {
    (_buildingBackend param [0,""]) == "LAMBS" && {(_buildingBackend param [1,""]) == "GARRISON"}
} else {
    (_group getVariable ["Waldo_AIPass_Garrison",[]]) isNotEqualTo []
        && {units _group findIf {(_x getVariable ["Waldo_AIPass_GarrisonPos",[]]) isNotEqualTo []} >= 0}
};
["ORD-04-garrison-accepted",_garrisonAccepted,str _buildingBackend] call _check;
["Garrison movement",["LAMBS is absent, so the public Zeus order must use the native Cortex fallback.","Installed LAMBS Waypoints must own the public Zeus order."] select _lambsBuilding
    + " Both soldiers must physically enter and hold real building positions; backend selection or an assignment alone does not pass.",getPosATL _house] call _phase;
["ORD-04b-garrison-arrival",[{call _atHouse},95] call _wait,str (units _group apply {[getPosATL _x,currentCommand _x,expectedDestination _x]})] call _check;
sleep 5;
["ORD-04c-garrison-hold",call _atHouse,str (units _group apply {getPosATL _x})] call _check;
["FIXTURE-engine-building-path",_baselineTarget isNotEqualTo [] && {_baseline distance _baselineTarget <= 2.5},format ["engine-only unit pos=%1 target=%2 command=%3 expected=%4",getPosATL _baseline,_baselineTarget,currentCommand _baseline,expectedDestination _baseline]] call _check;
// Diagnostic comparison: retain the closed-door result; opening doors is not a production fix.
private _doorCount = getNumber (configOf _house >> "numberOfDoors");
diag_log format ["WMP CORTEX QA DOORS: count=%1 owner=%2 baselineOwner=%3 states=%4",_doorCount,owner _house,groupOwner _baselineGroup,(animationNames _house) select {toLower _x find "door" >= 0} apply {[_x,_house animationPhase _x]}];
["Garrison open-door comparison","The original garrison result remains recorded. Doors are now opened for this separate diagnostic: watch whether both soldiers enter and reach their markers.",getPosATL _house] call _phase;
for "_door" from 1 to _doorCount do {
    [_house,_door,1] call BIS_fnc_door;
    sleep 1;
};
sleep 2;
diag_log format ["WMP CORTEX QA DOORS OPEN: states=%1",(animationNames _house) select {toLower _x find "door" >= 0} apply {[_x,_house animationPhase _x]}];
["GARRISON",getPosATL _house] call _order;
if (local _baseline && {_baselineTarget isNotEqualTo []}) then {doStop _baseline; _baseline doMove _baselineTarget};
["DIAG-open-door-garrison",[{call _atHouse},95] call _wait,str (units _group apply {[getPosATL _x,currentCommand _x,expectedDestination _x]})] call _check;
["DIAG-open-door-engine",local _baseline && {_baselineTarget isNotEqualTo []} && {_baseline distance _baselineTarget <= 2.5},format ["owner=%1 pos=%2 target=%3 command=%4",groupOwner _baselineGroup,getPosATL _baseline,_baselineTarget,currentCommand _baseline]] call _check;
["EXCLUDE"] call _order;
["ORD-05-hand-back",_group getVariable ["Waldo_AIPass_Exclude",false]
    && {(_group getVariable ["Waldo_AIPass_Garrison",[]]) isEqualTo []}
    && {(_group getVariable ["Waldo_AIPass_Defend",[]]) isEqualTo []}
    && {(_group getVariable ["Waldo_Cortex_BuildingBackend",[]]) isEqualTo []}] call _check;
["RETURN"] call _order;
["ORD-06-return",!(_group getVariable ["Waldo_AIPass_Exclude",false])] call _check;
[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQABuildings.sqf";
[{count (missionNamespace getVariable ["Waldo_Headless_Clients",[]]) >= 2},90] call _wait;
["Headless ownership","The infantry changes owner to each headless client, accepts defence, then returns to the server. See the owner checks below.",[6010,6000,0]] call _phase;
private _owners = (missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0};
["HC-01-two-registered",count _owners >= 2] call _check;
{
    private _owner = _x;
    [_group,_owner] call Waldo_fnc_HeadlessMigrateGroup;
    private _moved = [{groupOwner _group == _owner && {(_group getVariable ["Waldo_Headless_LastAdoption",[]]) param [1,-1] == _owner}},20] call _wait;
    [format ["HC-02-adopt-%1",_owner],_moved] call _check;
    ["DEFEND",[6000,6040+(_forEachIndex*30),0]] call _order;
    [format ["HC-03-order-%1",_owner],(_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo [] && {count (missionNamespace getVariable ["Waldo_AIPass_OrderPending",createHashMap]) == 0}] call _check;
    [format ["HC-03b-defence-movement-%1",_owner],[{["Waldo_AIPass_DefendPos",3.5] call _atAssigned},95] call _wait] call _check;
    ["RELEASE"] call _order;
} forEach (_owners select [0,2]);
[_group,2] call Waldo_fnc_HeadlessMigrateGroup;
["HC-04-return-server",[{local _group},20] call _wait] call _check;
deleteVehicle _baseline; deleteGroup _baselineGroup;
{deleteVehicle _x} forEach [_u1,_u2];
deleteGroup _group;
missionNamespace setVariable ["Waldo_CortexQA_Infantry",grpNull,true];
};
private _convoy = grpNull;
private _cargoGroup = grpNull;
private _secondCargoGroup = grpNull;
private _vehicles = [];
if (_focus in ["all","features","convoy"]) then {
// Actual mixed vehicles and cargo: no static substitutes or artificial solved state.
_convoy = createGroup [east,true];
_cargoGroup = createGroup [east,true];
_vehicles = [];
{private _v = createVehicle [_x,[6200,6000-_forEachIndex*35,0],[],0,"NONE"]; createVehicleCrew _v; {[_x] joinSilent _convoy} forEach crew _v; _vehicles pushBack _v} forEach ["O_MRAP_02_hmg_F","O_APC_Tracked_02_cannon_F","O_Truck_03_transport_F"];
missionNamespace setVariable ["Waldo_CortexQA_ConvoyVehicles",+_vehicles,true];
private _lengths = _vehicles apply {private _box=boundingBoxReal _x; abs (((_box select 1) select 1)-((_box select 0) select 1))};
{
    if (_forEachIndex > 0) then {
        private _bodyGap=((_lengths select _forEachIndex)+(_lengths select (_forEachIndex-1)))*0.5+5;
        private _target=30 max _bodyGap;
        private _tolerance=(_target*0.2) max 3;
        _x setVariable ["Waldo_CortexQA_GapBand",[(_target-_tolerance) max _bodyGap,_target+_tolerance],true];
    };
} forEach _vehicles;
private _operatingCrew = [];
{private _vehicle = _x; {if ((_x select 1) != "cargo" && {!(_x select 4)}) then {_operatingCrew pushBack [_x select 0,_vehicle]}} forEach fullCrew [_vehicle,"",false]} forEach _vehicles;
private _passenger = _cargoGroup createUnit ["O_Soldier_F",[6200,5930,0],[],0,"NONE"];
_passenger assignAsCargo (_vehicles select 2);
[_passenger] orderGetIn true;
_passenger moveInCargo (_vehicles select 2);
_secondCargoGroup = createGroup [east,true];
private _passengers = [_passenger];
{
    private _cargoSquad = _x;
    private _count = [2,1] select (_cargoSquad == _cargoGroup);
    for "_i" from 1 to _count do {
        private _unit = _cargoSquad createUnit ["O_Soldier_F",[6200,5930,0],[],0,"NONE"];
        _unit assignAsCargo (_vehicles select 2);
        [_unit] orderGetIn true;
        _unit moveInCargo (_vehicles select 2);
        _passengers pushBack _unit;
    };
} forEach [_cargoGroup,_secondCargoGroup];
{
_x addEventHandler ["GetOutMan", {
    params ["_unit","_role","_vehicle"];
    private _convoy = _vehicle getVariable ["Waldo_Convoy_Group",grpNull];
    private _registry = missionNamespace getVariable ["Waldo_Convoy_Registry",[]];
    private _index = _registry findIf {(_x select 0) == _convoy};
    private _phase = if (_index < 0) then {"UNREGISTERED"} else {((_registry select _index) select 1) select 5};
    diag_log format ["WMP CORTEX QA PASSENGER EXIT: phase=%1 role=%2 command=%3 vehicle=%4",_phase,_role,currentCommand _unit,typeOf _vehicle];
    if (_phase == "TRAVEL") then {_unit setVariable ["Waldo_CortexQA_EarlyExit",true]};
}];
} forEach _passengers;
["CNV-00b-two-cargo-squads",count _passengers == 4 && {_passengers findIf {vehicle _x != (_vehicles select 2)} < 0}] call _check;


["CNV-00-cargo-starts-mounted",vehicle _passenger == (_vehicles select 2)] call _check;
["Mixed convoy travelling","All three vehicles must move. The truck passenger and every operating crew member must remain aboard.",[6200,6000,0]] call _phase;
private _corner = _convoy addWaypoint [[6200,6400,0],0]; _corner setWaypointType "MOVE";
private _wp = _convoy addWaypoint [[6400,6400,0],0]; _wp setWaypointType "MOVE"; _convoy setCurrentWaypoint _corner;
private _starts = _vehicles apply {getPosATL _x};
["CNV-01-start",[_convoy,25,30,true] call Waldo_fnc_SimpleAiConvoy] call _check;
["CNV-02-movement",[{private _moved = 0; {if (_x distance2D (_starts select _forEachIndex) > 10) then {_moved = _moved + 1}} forEach _vehicles; _moved == count _vehicles},60] call _wait] call _check;
private _column = [{
    private _aligned = true;
    for "_i" from 1 to (count _vehicles - 1) do {
        private _front = _vehicles select (_i-1);
        private _follower = _vehicles select _i;
        private _relative = _front worldToModel (getPosATL _follower);
        if (abs (_relative select 0) > 8 || {(_relative select 1) > -8} || {_follower distance2D _front > 90}) then {_aligned = false};
    };
    _aligned
},45] call _wait;
["CNV-02c-predecessor-column",_column] call _check;
["Convoy steady travel","On this straight leg each vehicle must average at least 7.5 km/h over 20 seconds with a 25 km/h requested limit. Watch actual speed, spacing band and cyan trails; moving a few metres alone is insufficient.",getPosATL (_vehicles select 1)] call _phase;
private _travel = _vehicles apply {0};
private _lastPositions = _vehicles apply {getPosATL _x};
private _sampleStart = time;
for "_sample" from 1 to 20 do {
    sleep 1;
    {
        private _position = getPosATL _x;
        _travel set [_forEachIndex,(_travel select _forEachIndex)+(_position distance2D (_lastPositions select _forEachIndex))];
        _lastPositions set [_forEachIndex,_position];
    } forEach _vehicles;
};
private _elapsed = (time-_sampleStart) max 1;
private _averages = _travel apply {_x/_elapsed*3.6};
["CNV-02e-steady-speed",_averages findIf {_x < 7.5} < 0,format ["actual average km/h=%1 requested=25 duration=%2",_averages,_elapsed]] call _check;

["Convoy corner","Each vehicle should trace its predecessor around the right-angle corner, remaining in single file. Passengers stay aboard.",[6200,6400,0]] call _phase;
["CNV-02d-corner",[{_vehicles findIf {((getPosATL _x) select 0) < 6240 || {abs (((getPosATL _x) select 1)-6400) > 15}} < 0},150] call _wait] call _check;
["CNV-02b-travel-cargo-mounted",_passengers findIf {!alive _x || {vehicle _x != (_vehicles select 2)}} < 0] call _check;
["Convoy manual halt","This test deliberately stops the convoy. The passenger should get out and move clear of the vehicles; drivers and weapon crew must remain aboard.",getPosATL (_vehicles select 0)] call _phase;
[_convoy,0] call Waldo_fnc_SimpleAiConvoy;
["CNV-03-cargo-unload",[{_passengers findIf {!alive _x || {vehicle _x != _x}} < 0},30] call _wait] call _check;
private _manualExits = _passengers apply {getPosATL _x};
["CNV-03b-clear-vehicles",[{
    private _clear = true;
    {private _unit=_x; if (!alive _unit || {_unit distance2D (_manualExits select _forEachIndex) < 4} || {_vehicles findIf {_unit distance2D _x < 6} >= 0}) then {_clear=false}} forEach _passengers;
    _clear
},30] call _wait] call _check;
["CNV-04-crew-retained",_operatingCrew findIf {!alive (_x select 0) || {vehicle (_x select 0) != (_x select 1)}} < 0] call _check;
["Convoy destination","The convoy resumes to a nearby final waypoint, settles, then unloads cargo without a manual halt. Operating crew must remain aboard.",getPosATL (_vehicles select 0)] call _phase;
// Reproduce script/Zeus seating without a boarding assignment. START must adopt the occupied seat.
{unassignVehicle _x; _x moveInCargo (_vehicles select 2)} forEach _passengers;
["CNV-06-arrival-cargo-mounted",_passengers findIf {vehicle _x != (_vehicles select 2)} < 0] call _check;
_wp setWaypointPosition [(_vehicles select 0) getPos [70,0],0];
_wp setWaypointCompletionRadius 15;
["CNV-07-resume",[_convoy,25,30,true] call Waldo_fnc_SimpleAiConvoy] call _check;
private _convoyOwners = (missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0};
if (_convoyOwners isNotEqualTo []) then {
    private _convoyOwner = _convoyOwners select 0;
    if (count _convoyOwners >= 2) then {
        private _cargoOwner = _convoyOwners select 1;
        [_secondCargoGroup,_cargoOwner] call Waldo_fnc_HeadlessMigrateGroup;
        ["CNV-07d-separate-cargo-owner",[{groupOwner _secondCargoGroup == _cargoOwner},20] call _wait] call _check;
    };
    [_convoy,_convoyOwner] call Waldo_fnc_HeadlessMigrateGroup;
    ["CNV-07c-headless-transfer",[{groupOwner _convoy == _convoyOwner && {_vehicles findIf {owner _x != _convoyOwner || {owner driver _x != _convoyOwner}} < 0}},25] call _wait] call _check;
} else {["CNV-07c-headless-transfer",false,"No connected headless owner"] call _check};
private _nextArrivalLog = 0;
private _prematureUnload = false;
private _arrived = [{
    if (diag_tickTime >= _nextArrivalLog) then {
        _nextArrivalLog = diag_tickTime + 15;
        diag_log format ["WMP CORTEX QA ARRIVAL: waypoint=%1/%2 destination=%3 held=%4 paused=%5 passengerVehicle=%6 vehicles=%7",currentWaypoint _convoy,count waypoints _convoy,waypointPosition _wp,[_convoy] call Waldo_fnc_CortexZeusHeld,[] call Waldo_fnc_CortexIsPaused,typeOf vehicle _passenger,_vehicles apply {[typeOf _x,getPosATL _x,speed _x,local _x,isNull driver _x,expectedDestination driver _x,getForcedSpeed _x,currentCommand driver _x,driver _x == leader _convoy]}];
    };
    private _registry = missionNamespace getVariable ["Waldo_Convoy_Registry",[]];
    private _index = _registry findIf {(_x select 0) == _convoy};
    if (_index >= 0 && {(((_registry select _index) select 1) select 5) == "TRAVEL"} && {_passengers findIf {vehicle _x != (_vehicles select 2)} >= 0}) then {_prematureUnload = true};
    _index >= 0 && {(((_registry select _index) select 1) select 8) == "ARRIVED"}
},120] call _wait;
["CNV-07b-no-premature-unload",!_prematureUnload && {_passengers findIf {_x getVariable ["Waldo_CortexQA_EarlyExit",false]} < 0}] call _check;
["CNV-08-destination-halt",_arrived] call _check;
["CNV-09-destination-unload",_arrived && {[{_passengers findIf {!alive _x || {vehicle _x != _x}} < 0},30] call _wait}] call _check;
private _arrivalExits = _passengers apply {getPosATL _x};
["CNV-09b-clear-vehicles",_arrived && {[{
    private _clear = true;
    {private _unit=_x; if (!alive _unit || {_unit distance2D (_arrivalExits select _forEachIndex) < 4} || {_vehicles findIf {_unit distance2D _x < 6} >= 0}) then {_clear=false}} forEach _passengers;
    _clear
},30] call _wait}] call _check;
["CNV-10-destination-crew",_operatingCrew findIf {!alive (_x select 0) || {vehicle (_x select 0) != (_x select 1)}} < 0] call _check;
[_convoy,0,30,true,true] call Waldo_fnc_SimpleAiConvoy;
["CNV-05-release",!(_convoy getVariable ["Waldo_Convoy_Active",false])] call _check;
[_convoy,2] call Waldo_fnc_HeadlessMigrateGroup;
[{local _convoy},20] call _wait;
// Real enemy fire and a disabled rear vehicle exercise contact drills without writing controller state.
call {
    private _contactGroup = createGroup [east,true];
    private _contactCargo = createGroup [east,true];
    private _attackers = createGroup [west,true];
    _attackers setVariable ["Waldo_AIPass_Exclude",true,true];
    _attackers setCombatMode "BLUE";
    private _contactVehicles = [];
    {private _v = createVehicle [_x,[6400,7000-_forEachIndex*40,0],[],0,"NONE"]; createVehicleCrew _v; {[_x] joinSilent _contactGroup; _x allowDamage false} forEach crew _v; _contactVehicles pushBack _v} forEach ["O_MRAP_02_hmg_F","O_Truck_03_transport_F"];
    private _contactCrew = [];
    {private _v = _x; {_contactCrew pushBack [_x,_v]} forEach crew _v} forEach _contactVehicles;
    private _escort = _contactVehicles select 0;
    private _truck = _contactVehicles select 1;
    private _rider = _contactCargo createUnit ["O_Soldier_F",[6400,6960,0],[],0,"NONE"];
    _rider allowDamage false;
    _rider assignAsCargo _truck; [_rider] orderGetIn true; _rider moveInCargo _truck;
    private _attackUnits = [];
    for "_i" from 0 to 1 do {
        private _attacker = _attackers createUnit ["B_soldier_AR_F",[6460,7000+_i*12,0],[],0,"NONE"];
        _attacker allowDamage false; _attacker setSkill 1; _attacker disableAI "PATH";
        _attacker addEventHandler ["Fired",{params ["_unit"]; _unit setVariable ["Waldo_CortexQA_Shots",(_unit getVariable ["Waldo_CortexQA_Shots",0])+1]}];
        _attackUnits pushBack _attacker;
    };
    _escort addEventHandler ["Fired",{params ["_vehicle"]; _vehicle setVariable ["Waldo_CortexQA_Shots",(_vehicle getVariable ["Waldo_CortexQA_Shots",0])+1]}];
    private _contactWP = _contactGroup addWaypoint [[6400,7800,0],0]; _contactWP setWaypointType "MOVE";
    ["Convoy moving contact","Enemy riflemen fire at the convoy. Vehicles should keep moving, the escort should return fire and the passenger should stay aboard.",[6400,7000,0]] call _phase;
    [_contactGroup,25,30,true] call Waldo_fnc_SimpleAiConvoy;
    private _contactStart = getPosATL _escort;
    _attackers setCombatMode "RED";
    {private _target = _contactVehicles select _forEachIndex; _x doTarget _target; _x doFire _target} forEach _attackUnits;
    ["AMB-01-real-enemy-fire",[{_attackUnits findIf {(_x getVariable ["Waldo_CortexQA_Shots",0]) > 2} >= 0},30] call _wait] call _check;
    ["AMB-02-push-through",[{_escort distance2D _contactStart > 15 && {vehicle _rider == _truck}},30] call _wait] call _check;
    ["AMB-03-mounted-response",[{(_escort getVariable ["Waldo_CortexQA_Shots",0]) > 0},30] call _wait] call _check;
    ["Convoy pinned contact","The rear truck loses fuel while under fire. After the pinned interval the convoy should halt, unload its passenger and move them clear. Weapon crew remain aboard.",getPosATL _truck] call _phase;
    _truck setFuel 0;
    private _pinnedShots = _attackUnits apply {_x getVariable ["Waldo_CortexQA_Shots",0]};
    private _nextPinnedLog = 0;
    private _pinnedHalt = [{
        if (time >= _nextPinnedLog) then {
            _nextPinnedLog=time+5;
            private _state=_contactGroup getVariable ["Waldo_Convoy_LocalState",createHashMap];
            diag_log format ["WMP CORTEX QA PINNED: contact=%1 reports=%2 progress=%3 shots=%4 speeds=%5",_state getOrDefault ["contact",false],_contactVehicles apply {[driver _x] call Waldo_fnc_ConvoyThreat},_state getOrDefault ["contactProgress",[]],_attackUnits apply {_x getVariable ["Waldo_CortexQA_Shots",0]},_contactVehicles apply {speed _x}];
        };
        private _r = missionNamespace getVariable ["Waldo_Convoy_Registry",[]]; private _i = _r findIf {(_x select 0) == _contactGroup}; _i >= 0 && {(((_r select _i) select 1) select 8) == "AMBUSH"}},60] call _wait;
    ["AMB-04a-pinned-live-fire",(_attackUnits select 1) getVariable ["Waldo_CortexQA_Shots",0] > (_pinnedShots select 1),"Rear attacker must continue firing during the pinned interval"] call _check;
    ["AMB-04-pinned-halt",_pinnedHalt] call _check;
    ["AMB-05-cargo-unload",_pinnedHalt && {[{vehicle _rider == _rider},30] call _wait}] call _check;
    private _contactExit = getPosATL _rider;
    ["AMB-06-dismount-movement",_pinnedHalt && {[{_rider distance2D _contactExit >= 4 && {_contactVehicles findIf {_rider distance2D _x < 6} < 0}},30] call _wait}] call _check;
    ["AMB-07-operating-crew",_contactCrew findIf {!alive (_x select 0) || {vehicle (_x select 0) != (_x select 1)}} < 0] call _check;
    [_contactGroup,0,30,true,true] call Waldo_fnc_SimpleAiConvoy;
    {deleteVehicle _x} forEach (units _contactGroup + units _contactCargo + _attackUnits);
    {deleteVehicle _x} forEach _contactVehicles;
    {deleteGroup _x} forEach [_contactGroup,_contactCargo,_attackers];
};
[_convoy,0,30,true,true] call Waldo_fnc_SimpleAiConvoy;
{deleteVehicle _x} forEach (_passengers+(_operatingCrew apply {_x select 0}));
{deleteVehicle _x} forEach _vehicles;
{deleteGroup _x} forEach [_convoy,_cargoGroup,_secondCargoGroup];
missionNamespace setVariable ["Waldo_CortexQA_ConvoyVehicles",[],true];
};
if (_focus in ["all","features","convoy","convoymatrix","convoycolumn","convoytracked","convoydiagnostic","convoyfollow"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAConvoyMatrix.sqf"};
private _gun = objNull;
if (_focus in ["all","features","artillery"]) then {
private _spotterGroup=createGroup [east,true];
_spotterGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_spotterGroup setVariable ["acex_headless_blacklist",true,true];
// This is the server-owned firing baseline. Its local Fired counters cannot
// establish HC firing; keep ownership explicit and test migration separately.
private _retainServerGun={
    params ["_vehicle"];
    private _crewGroup=group gunner _vehicle;
    _crewGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _crewGroup setVariable ["acex_headless_blacklist",true,true];
    {_x setVariable ["acex_headless_blacklist",true,true]} forEach crew _vehicle;
};
private _spotter=_spotterGroup createUnit ["O_Soldier_F",[7100,6000,0],[],0,"NONE"];
_spotter allowDamage false;
[createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIPass_LambsMode","WMP"]]] call Waldo_fnc_CortexTuning;
_gun = createVehicle ["O_Mortar_01_F",[6500,6000,0],[],0,"NONE"]; createVehicleCrew _gun;
[_gun] call _retainServerGun;
_gun setVariable ["Waldo_CortexQA_Shots",0];
_gun addEventHandler ["Fired",{params ["_gun"]; _gun setVariable ["Waldo_CortexQA_Shots",(_gun getVariable ["Waldo_CortexQA_Shots",0])+1]}];
[createHashMapFromArray [["Waldo_AIPass_Artillery_Enable",true],["Waldo_AIPass_Artillery_Bursts",1],["Waldo_AIPass_Artillery_Rounds",2]]] call Waldo_fnc_CortexTuning;
sleep 2;
["Finite artillery burst","Watch the mortar: exactly two rounds, then no further rounds during the observation period. This case does not test counter-battery.",[6500,6000,0]] call _phase;
["ART-01-assign-spotter",[_spotter,true] call Waldo_fnc_CortexSetSpotter] call _check;
missionNamespace setVariable ["Waldo_CortexQA_HEWarnings",[]];
private _redHandler=addMissionEventHandler ["ProjectileCreated",{
    params ["_projectile"];
    if (typeOf _projectile == "SmokeShellRed") then {
        private _events=missionNamespace getVariable ["Waldo_CortexQA_HEWarnings",[]];
        _events pushBack [time,_projectile];
        missionNamespace setVariable ["Waldo_CortexQA_HEWarnings",_events];
    };
}];
_gun setVariable ["Waldo_CortexQA_FirstShot",-1];
private _firstShotHandler=_gun addEventHandler ["Fired",{
    params ["_gun"];
    if ((_gun getVariable ["Waldo_CortexQA_FirstShot",-1]) < 0) then {_gun setVariable ["Waldo_CortexQA_FirstShot",time]};
}];
private _queued = [_gun,[7200,6000,0],20,"HE",2,false,"SUPPORT",_spotter] call Waldo_fnc_CortexArtilleryFire;
private _warned=[{count (missionNamespace getVariable ["Waldo_CortexQA_HEWarnings",[]]) >= 4},15] call _wait;
private _redEvents=+(missionNamespace getVariable ["Waldo_CortexQA_HEWarnings",[]]);
["ART-HE-warning-before-shot",_queued && {_warned} && {(_gun getVariable ["Waldo_CortexQA_FirstShot",-1]) < 0}] call _check;
["ART-HE-warning-ring",count _redEvents == 4 && {_redEvents findIf {isNull (_x select 1) || {abs (((_x select 1) distance2D [7200,6000,0])-25) > 3}} < 0},str (_redEvents apply {getPosATL (_x select 1)})] call _check;
["ART-02-queue",_queued] call _check;
["ART-03-real-rounds",[{(_gun getVariable ["Waldo_CortexQA_Shots",0]) >= 2},100] call _wait] call _check;
sleep 12;
["ART-04-finite-burst",(_gun getVariable ["Waldo_CortexQA_Shots",0]) == 2] call _check;
["ART-HE-warning-once",count (missionNamespace getVariable ["Waldo_CortexQA_HEWarnings",[]]) == 4 && {(_gun getVariable ["Waldo_CortexQA_Shots",0]) == 2}] call _check;
["ART-HE-warning-delay",count _redEvents == 4 && {(_gun getVariable ["Waldo_CortexQA_FirstShot",-1])-(_redEvents select 3 select 0) >= 10}] call _check;
removeMissionEventHandler ["ProjectileCreated",_redHandler];
_gun removeEventHandler ["Fired",_firstShotHandler];
missionNamespace setVariable ["Waldo_CortexQA_HEWarnings",nil];
// Remove the support observer before counter-battery: it can otherwise occupy the
// counter-battery ranging ring and correctly trigger friendly-fire rejection.
[_spotter,false] call Waldo_fnc_CortexSetSpotter;
deleteVehicle _spotter;
deleteGroup _spotterGroup;
// Real enemy artillery events exercise acquisition with and without a radar.
[_gun,"SUPPORT"] call Waldo_fnc_CortexSetArtilleryRole;
[createHashMapFromArray [["Waldo_AIPass_CounterBattery_Enable",true],["Waldo_AIPass_CounterBattery_Delay",8],["Waldo_AIPass_CounterBattery_RadarDelay",2],["Waldo_AIPass_CounterBattery_Rounds",2],["Waldo_AIPass_CounterBattery_ShootAndScoot",false]]] call Waldo_fnc_CortexTuning;
{
    private _withRadar = _x;
    private _case = ["CB-NORMAL","CB-RADAR"] select _withRadar;
    private _counterGun = createVehicle ["O_Mortar_01_F",[6500,6100,0],[],0,"NONE"]; createVehicleCrew _counterGun;
    private _emitter = createVehicle ["B_Mortar_01_F",[7400,6100,0],[],0,"NONE"]; createVehicleCrew _emitter;
    [_counterGun] call _retainServerGun;
    [_emitter] call _retainServerGun;
    [_counterGun,"COUNTER"] call Waldo_fnc_CortexSetArtilleryRole;
    [_emitter,"SUPPORT"] call Waldo_fnc_CortexSetArtilleryRole;
    private _radar = objNull;
    if (_withRadar) then {
        _radar = createVehicle ["Land_SatellitePhone_F",[6500,6150,0],[],0,"NONE"];
        [format ["%1-register",_case],[_radar,east] call Waldo_fnc_CortexRegisterRadar] call _check;
    };
    _counterGun setVariable ["Waldo_CortexQA_Shots",0];
    _counterGun addEventHandler ["Fired",{params ["_gun"]; _gun setVariable ["Waldo_CortexQA_Shots",(_gun getVariable ["Waldo_CortexQA_Shots",0])+1]}];
    [format ["%1-discovery",_case],[{_counterGun in (missionNamespace getVariable ["Waldo_AIPass_AllArtillery",[]])},30] call _wait] call _check;
    [_case,"The enemy mortar fires once. The Cortex battery should answer with two rounds; radar shortens acquisition from eight seconds to two.",[6500,6100,0]] call _phase;
    private _magazine = [_emitter,false] call Waldo_fnc_CortexArtilleryAmmo;
    _emitter doArtilleryFire [[8100,6100,0],_magazine,1];
    [format ["%1-real-emission",_case],[{(_emitter getVariable ["Waldo_AIPass_LastEmission",[]]) isNotEqualTo []},35] call _wait] call _check;
    private _emission = _emitter getVariable ["Waldo_AIPass_LastEmission",[]];
    private _pending = _emitter getVariable ["Waldo_AIPass_CounterPending_EAST",-1];
    private _expectedDelay = [8,2] select _withRadar;
    [format ["%1-acquisition-delay",_case],count _emission >= 2 && {abs (_pending-(_emission select 0)-_expectedDelay-1) < 0.5}] call _check;
    private _responded=[{(_counterGun getVariable ["Waldo_CortexQA_Shots",0]) >= 2},70] call _wait;
    private _responseMission=(missionNamespace getVariable ["Waldo_AIPass_FireMissions",createHashMap]) getOrDefault [netId _counterGun,createHashMap];
    [format ["%1-response",_case],_responded,format ["shots=%1 owner=%2 gunnerOwner=%3 mission=%4",_counterGun getVariable ["Waldo_CortexQA_Shots",0],owner _counterGun,owner gunner _counterGun,_responseMission]] call _check;
    sleep 12;
    [format ["%1-finite",_case],(_counterGun getVariable ["Waldo_CortexQA_Shots",0]) == 2] call _check;
    [format ["%1-server-owner-retained",_case],local _counterGun && {local gunner _counterGun} && {local _emitter} && {local gunner _emitter},str [owner _counterGun,owner gunner _counterGun,owner _emitter,owner gunner _emitter]] call _check;
    if (!isNull _radar) then {[_radar,east,false] call Waldo_fnc_CortexRegisterRadar; deleteVehicle _radar};
    {private _crew = crew _x; private _crewGroup = group gunner _x; {deleteVehicle _x} forEach _crew; deleteVehicle _x; deleteGroup _crewGroup} forEach [_counterGun,_emitter];
} forEach [false,true];
private _gunGroup=group gunner _gun;
{deleteVehicle _x} forEach crew _gun;
deleteVehicle _gun;
deleteGroup _gunGroup;
};
if (_focus in ["all","features","convoyseats","extensions"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQASeats.sqf"};
if (_focus in ["all","features","avoidance"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAAvoidance.sqf"};
if (_focus in ["all","features","deceleration"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQADeceleration.sqf"};
if (_focus in ["all","features","aircraft","airskills"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAAircraft.sqf"};
if (_focus in ["all","features","lifecycle","stateflows"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQALifecycle.sqf"};
if (_focus in ["all","features","lambs"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQALambs.sqf"};
if (_focus in ["all","features","performance"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAPerformance.sqf"};
if (_focus == "performancecontact") then {
    [_check,_phase,_wait,false] call compile preprocessFileLineNumbers "cortexQAPerformanceContact.sqf";
    ["PERF-CONTACT-run-completed",missionNamespace getVariable ["Waldo_CortexQA_PerformanceContactCompleted",false]] call _check;
};
if (_focus == "performancemixed") then {
    [_check,_phase,_wait,true] call compile preprocessFileLineNumbers "cortexQAPerformanceContact.sqf";
    ["PERF-MIXED-run-completed",missionNamespace getVariable ["Waldo_CortexQA_PerformanceContactCompleted",false]] call _check;
};
if (_focus in ["all","features","profiles"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAProfiles.sqf"};
if (_focus in ["all","features","lighting"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQALighting.sqf"};
if (_focus in ["all","features","scheduler"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAScheduler.sqf"};
if (_focus in ["all","features","artillerysmoke"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAArtillerySmoke.sqf"};
if (_focus in ["all","features","crossing"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACrossing.sqf"};
if (_focus in ["all","features","contact"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAContact.sqf"};
if (_focus == "buildings") then {
    [createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIPass_LambsMode","WMP"],["Waldo_AIPass_Contact_Enable",false],["Waldo_AIPass_Regroup_Enable",false]]] call Waldo_fnc_CortexTuning;
    [{missionNamespace getVariable ["Waldo_AIPass_Active",false]},20] call _wait;
    [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQABuildings.sqf";
};
if (_focus in ["all","features","cover"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACover.sqf"};
if (_focus in ["all","features","landing"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQALanding.sqf"};
if (_focus in ["all","features","gates","extensions"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAGates.sqf"};
if (_focus in ["all","features","gunnery","extensions"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAGunnery.sqf"};
if (_focus in ["all","features","combat"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACombat.sqf"};
if (_focus in ["all","features","mechanics","airskills"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAMechanics.sqf"};
if (_focus in ["all","features","mechanics","reactions"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAReactions.sqf"};
if (_focus in ["all","features","mechanics","support"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQASupport.sqf"};
if (_focus in ["all","features","combinedarms","supportflows"]) then {
    // Keep the narrow communications diagnostic, then exercise the same production layers in a
    // full multi-squad operation. The second case is additive and cannot inherit fixture actors.
    [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACombinedArms.sqf";
    [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACombinedOperation.sqf";
};
if (_focus in ["all","features","mechanics","airborne"]) then {
    [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAAirborne.sqf";
    private _airborneBaseCheck=_check;
    private _airborneBasePhase=_phase;
    private _fallbackCheck={params ["_id","_passed",["_detail",""]]; ["FALLBACK-"+_id,_passed,_detail] call _airborneBaseCheck};
    private _fallbackPhase={params ["_title","_instructions","_position"]; ["Invalid chute fallback: "+_title,"Configured B_Parachute is a backpack. Cortex must select a real parachute vehicle. "+_instructions,_position] call _airborneBasePhase};
    [_fallbackCheck,_fallbackPhase,_wait,"B_Parachute"] call compile preprocessFileLineNumbers "cortexQAAirborne.sqf";
};
if (_focus in ["all","features","mechanics","vehicles","stateflows"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAVehicles.sqf"};
if (_focus in ["all","features","mechanics","vehicles","naval"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQANaval.sqf"};
if (_focus in ["all","features","mechanics","fire"]) then {[_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAFire.sqf"};
// Long multi-squad comparisons run last so they cannot delay unrelated feature coverage.
if (_focus == "coordinatedbounds") then {[_check,_phase,_wait,[],true] call compile preprocessFileLineNumbers "cortexQACoordinated.sqf"};
// Additive geometry comparison; do not replace the original long-screen audit.
if (_focus in ["all","features","coordinatedclean"]) then {
    private _recordCleanCheck=_check;
    private _cleanCheck={params ["_id","_passed",["_detail",""]]; ["CLEAN-"+_id,_passed,_detail] call _recordCleanCheck};
    [_cleanCheck,_phase,_wait,[],true,true] call compile preprocessFileLineNumbers "cortexQACoordinated.sqf";
};
if (_focus in ["all","features","coordinated","supportflows"]) then {
    [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAMultiManoeuvre.sqf";
    private _coordinated=compile preprocessFileLineNumbers "cortexQACoordinated.sqf";
    [_check,_phase,_wait] call _coordinated;
    private _recordContactCheck=_check;
    private _contactCheck={params ["_id","_passed",["_detail",""]]; ["CONTACT-"+_id,_passed,_detail] call _recordContactCheck};
    [_contactCheck,_phase,_wait,[],true] call _coordinated;
    private _responderOwners=((missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0}) select [0,2];
    ["COORD-two-headless-owners",count _responderOwners == 2] call _check;
    if (count _responderOwners == 2) then {
        private _recordCoordinatedCheck=_check;
        private _hcCheck={params ["_id","_passed",["_detail",""]]; ["HC-"+_id,_passed,_detail] call _recordCoordinatedCheck};
        [_hcCheck,_phase,_wait,_responderOwners] call _coordinated;
    };
};
// Exercise the public read-only diagnostics path twice; UI report rows are not behaviour passes.
private _diagnostics=[] call Waldo_fnc_AIGetDiagnostics;
private _diagnosticRows=_diagnostics getOrDefault ["checks",[]];
private _gateSpec=([] call Waldo_fnc_CortexTuningSpec) select {(_x select 3) == "CHECKBOX"};
["DIAG-all-feature-gates",_gateSpec findIf {private _id="cortex-setting-"+(_x select 0); _diagnosticRows findIf {(_x select 1) == _id} < 0} < 0] call _check;
["DIAG-owner-scope-explicit",_diagnosticRows findIf {(_x select 1) == "cortex-snapshot-scope"} >= 0] call _check;
private _diagnosticGateSaved=createHashMapFromArray [["Waldo_AIPass_Vehicles_Enable",missionNamespace getVariable ["Waldo_AIPass_Vehicles_Enable",true]],["Waldo_AIPass_VehicleDismount_Enable",missionNamespace getVariable ["Waldo_AIPass_VehicleDismount_Enable",true]]];
[createHashMapFromArray [["Waldo_AIPass_Vehicles_Enable",false],["Waldo_AIPass_VehicleDismount_Enable",true]]] call Waldo_fnc_CortexTuning;
private _blockedDiagnostic=[] call Waldo_fnc_AIGetDiagnostics;
["DIAG-feature-parent-blocker",(_blockedDiagnostic get "checks") findIf {(_x select 1) == "cortex-setting-Waldo_AIPass_VehicleDismount_Enable" && {(_x select 2) == "UNCONFIGURED"}} >= 0] call _check;
[_diagnosticGateSaved] call Waldo_fnc_CortexTuning;
private _diagnosticsAgain=[] call Waldo_fnc_AIGetDiagnostics;
["DIAG-repeat-schema",(_diagnosticsAgain getOrDefault ["schema",-1]) == (_diagnostics getOrDefault ["schema",-2]) && {(_diagnosticsAgain getOrDefault ["feature",""]) == "ai"}] call _check;
[_saved] call Waldo_fnc_CortexTuning;
["Server checks finished","Fixtures are being removed. Client UI checks follow; these are functional checks, not a mouse or layout assessment.",[]] call _phase;
{deleteVehicle _x} forEach (units _group + units _cargoGroup + units _secondCargoGroup + units _convoy + crew _gun);
{deleteVehicle _x} forEach (_vehicles + [_gun,_house]);
{deleteGroup _x} forEach [_group,_cargoGroup,_secondCargoGroup,_convoy];
missionNamespace setVariable ["Waldo_CortexQA_ServerDone",true,true];
missionNamespace setVariable ["Waldo_CortexQA_ServerFailures",_failures,true];
diag_log format ["WMP CORTEX QA SERVER COMPLETE: %1 finding(s) %2",count _failures,_failures];

