/*
 * Author: WaldoTheWarfighter
 * Tests mid-order master disable, authored movement, restart, active investigation/search/retreat
 * migration and published handover reasons on the server and two headless owners.
 * Locality/authority: server fixture; WMP migration and production owner-local defence/release paths.
 * Ordinary waypoints are issued after returning the group to the server while Cortex is disabled.
 * Also checks that a refused HC-to-HC transfer preserves actual ownership and its registry record.
 * Repeat/JIP: fresh group and public destination markers; caller restores tuning; fixture cleaned here.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQALifecycle.sqf";
 */
params ["_recordCheck","_phase","_wait"];
private _owners=(missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0};
["LIFE-two-headless-clients",count _owners >= 2] call _recordCheck;
private _variants=[["",2]];
{_variants pushBack [format ["HC%1-",_forEachIndex+1],_x]} forEach (_owners select [0,2]);
{
_x params ["_prefix","_targetOwner"];
private _check={params ["_id","_passed",["_detail",""]]; [_prefix+_id,_passed,_detail] call _recordCheck};
[createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",false],["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_LambsMode","WMP"]]] call Waldo_fnc_CortexTuning;
private _group=createGroup [east,true];
_group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_group setVariable ["acex_headless_blacklist",true,true];
_group setCombatMode "BLUE";
private _units=[];
for "_i" from 0 to 1 do {
    private _unit=_group createUnit ["O_Soldier_F",[2100+_i*3,1700,0],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["LIFECYCLE SOLDIER %1",_i+1],true];
    _units pushBack _unit;
};
missionNamespace setVariable ["Waldo_CortexQA_Actors",_units,true];
_group setGroupIdGlobal ["QA LIFECYCLE "+(["SERVER",_prefix] select (_targetOwner != 2))];
private _migrate={
    params ["_owner"];
    _group setVariable ["Waldo_Headless_ExcludeGroup",false,true];
    {_x setVariable ["acex_headless_blacklist",false,true]} forEach _units;
    private _requested=[_group,_owner] call Waldo_fnc_HeadlessMigrateGroup;
    private _adopted=[{groupOwner _group == _owner && {_units findIf {owner _x != _owner} < 0}},30] call _wait;
    [_prefix+"LIFE-owner-"+str _owner,_requested && {_adopted},str groupOwner _group] call _recordCheck;
};
if (_targetOwner != 2) then {
    [_targetOwner] call _migrate;
    private _otherOwners=_owners select {_x != _targetOwner};
    if (_otherOwners isNotEqualTo []) then {
        _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        private _refused=!([_group,_otherOwners select 0] call Waldo_fnc_HeadlessMigrateGroup);
        sleep 2;
        private _registry=missionNamespace getVariable ["Waldo_Headless_ManagedGroups",[]];
        private _records=_registry select {(_x select 0) == _group};
        ["LIFE-refused-transfer-owner-retained",_refused && {groupOwner _group == _targetOwner}
            && {_units findIf {owner _x != _targetOwner} < 0},str [groupOwner _group,_units apply {owner _x}]] call _check;
        ["LIFE-refused-transfer-registry-retained",count _records == 1 && {(_records select 0 select 1) == _targetOwner},str _records] call _check;
        _group setVariable ["Waldo_Headless_ExcludeGroup",false,true];
    };
};
[{missionNamespace getVariable ["Waldo_AIPass_Active",false]},20] call _wait;
["Lifecycle: disable during movement","Both soldiers start a real defence move north. Cortex will be disabled after visible travel, before arrival. The following ordinary waypoint must take control.",[2100,1730,0]] call _phase;
private _start=_units apply {getPosATL _x};
private _accepted=[_group,[2100,1780,0],0,10] call Waldo_fnc_CortexDefend;
private _moving=[{
    private _allMoved=true;
    {if (!alive _x || {_x distance2D (_start select _forEachIndex) < 10}) then {_allMoved=false}} forEach _units;
    _allMoved
},30] call _wait;
["LIFE-defence-physical-start",_accepted && {_moving}] call _check;
[createHashMapFromArray [["Waldo_AIPass_Enable",false]]] call Waldo_fnc_CortexTuning;
["LIFE-master-stopped",[{!(missionNamespace getVariable ["Waldo_AIPass_Active",true])},20] call _wait] call _check;
private _stopRecorded=[{
    private _transition=_group getVariable ["Waldo_Cortex_PhaseTransition",[]];
    count _transition == 5 && {(_transition select 2) == "CALM"} && {(_transition select 3) == "CORTEX_STOPPED"}
},20] call _wait;
["LIFE-stop-transition-reason",_stopRecorded,str (_group getVariable ["Waldo_Cortex_PhaseTransition",[]])] call _check;
["LIFE-owner-cleared-assignment",[{
    (_group getVariable ["Waldo_AIPass_Defend",[]]) isEqualTo []
        && {_units findIf {(_x getVariable ["Waldo_AIPass_DefendPos",[]]) isNotEqualTo []} < 0}
},20] call _wait] call _check;
if (_targetOwner != 2) then {[2] call _migrate};
_group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
private _destination=[2040,1730,0];
{_x setVariable ["Waldo_CortexQA_Target",_destination,true]} forEach _units;
private _wp=_group addWaypoint [_destination,0]; _wp setWaypointType "MOVE"; _wp setWaypointCompletionRadius 3; _group setCurrentWaypoint _wp;
{_x doFollow leader _group} forEach _units;
["Lifecycle: ordinary waypoint owns movement","Cortex is off. Both soldiers must physically reach the west marker using a normal group waypoint. They must not remain frozen at, or return to, their former defence positions.",_destination] call _phase;
private _arrived=[{_units findIf {!alive _x || {_x distance2D _destination > 10}} < 0},90] call _wait;
["LIFE-disabled-authored-arrival",_arrived,str (_units apply {getPosATL _x})] call _check;
[createHashMapFromArray [["Waldo_AIPass_Enable",true]]] call Waldo_fnc_CortexTuning;
[{missionNamespace getVariable ["Waldo_AIPass_Active",false]},20] call _wait;
private _drift=0;
for "_i" from 1 to 15 do {sleep 1; {_drift=_drift max (_x distance2D _destination)} forEach _units};
["LIFE-no-old-order-resurrection",_arrived && {_drift <= 12},str _drift] call _check;
if (_targetOwner != 2) then {[_targetOwner] call _migrate};
private _newPosition=[2040,1800,0];
{_x setVariable ["Waldo_CortexQA_Target",_newPosition,true]} forEach _units;
["Lifecycle: new order after restart","A new defence order must move both soldiers north from the west marker. This verifies restart does not leave stale jobs, movement locks or ownership behind.",_newPosition] call _phase;
_accepted=[_group,_newPosition,0,10] call Waldo_fnc_CortexDefend;
_arrived=[{_units findIf {!alive _x || {_x distance2D _newPosition > 10}} < 0},90] call _wait;
["LIFE-restarted-new-physical-order",_accepted && {_arrived},str (_units apply {getPosATL _x})] call _check;
// Exercise the production takeover marker without a waypoint flag. This tests
// the owner cleanup path; actual curator event delivery remains a separate UI case.
[_group,false] call Waldo_fnc_CortexZeusMark;
["Lifecycle: Zeus interrupts defence","Zeus takeover now interrupts the held defence without a waypoint-change flag. The owner must release the holding order. After return to server, both soldiers must physically obey a replacement waypoint.",_newPosition] call _phase;
private _zeusReleased=[{
    (_group getVariable ["Waldo_AIPass_Defend",[]]) isEqualTo []
    && {_units findIf {(_x getVariable ["Waldo_AIPass_DefendPos",[]]) isNotEqualTo []} < 0}
},20] call _wait;
["LIFE-zeus-no-waypoint-releases-defence",_zeusReleased] call _check;
private _zeusRecorded=[{
    private _transition=_group getVariable ["Waldo_Cortex_PhaseTransition",[]];
    count _transition == 5 && {(_transition select 2) == "CALM"} && {(_transition select 3) == "ZEUS_TAKEOVER"}
},20] call _wait;
["LIFE-zeus-transition-reason",_zeusRecorded,str (_group getVariable ["Waldo_Cortex_PhaseTransition",[]])] call _check;
if (_targetOwner != 2) then {[2] call _migrate};
private _zeusDestination=[2130,1800,0];
private _zeusWP=_group addWaypoint [_zeusDestination,0];
_zeusWP setWaypointType "MOVE"; _zeusWP setWaypointCompletionRadius 3;
_group setCurrentWaypoint _zeusWP;
{_x setVariable ["Waldo_CortexQA_Target",_zeusDestination,true]} forEach _units;
private _zeusArrived=[{_units findIf {!alive _x || {_x distance2D _zeusDestination > 12}} < 0},90] call _wait;
["LIFE-zeus-replacement-physical-arrival",_zeusReleased && {_zeusArrived},str (_units apply {getPosATL _x})] call _check;
diag_log format ["WMP CORTEX QA ZEUS HANDOVER: owner=%1 currentWP=%2 waypoints=%3 adoption=%4 units=%5",
    groupOwner _group,currentWaypoint _group,(waypoints _group) apply {[_x select 1,waypointPosition _x,waypointDescription _x]},
    _group getVariable ["Waldo_Headless_LastAdoption",[]],
    _units apply {[netId _x,currentCommand _x,expectedDestination _x,_x checkAIFeature "PATH",behaviour _x]}];
// Keep the held-order case above; this additional case interrupts physical travel.
if (_targetOwner == 2) then {
    private _movingStart=_units apply {getPosATL _x};
    [[ ["order","DEFEND"],["group",_group],["position",[2130,1920,0]],["radius",10],["facing",0] ],2] call Waldo_fnc_CortexOrderDispatch;
    ["Lifecycle: Zeus interrupts moving soldiers","Both soldiers must first travel at least 10 m towards a fresh defence order. Zeus then replaces it while they are still moving; watch their trails turn towards the west marker.",[2130,1860,0]] call _phase;
    private _started=[{
        private _travelled=true;
        {if (!alive _x || {_x distance2D (_movingStart select _forEachIndex) < 10}) then {_travelled=false}} forEach _units;
        _travelled && {(_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo []}
    },30] call _wait;
    private _beforeArrival=_units findIf {_x distance2D [2130,1920,0] < 30} < 0;
    ["LIFE-zeus-midmove-stimulus",_started && {_beforeArrival}] call _check;
    [_group,true] call Waldo_fnc_CortexZeusMark;
    private _replacement=[2030,1850,0];
    private _replacementWP=_group addWaypoint [_replacement,0];
    _replacementWP setWaypointType "MOVE"; _replacementWP setWaypointCompletionRadius 3;
    _group setCurrentWaypoint _replacementWP;
    {_x setVariable ["Waldo_CortexQA_Target",_replacement,true]} forEach _units;
    private _replacementReached=[{_units findIf {!alive _x || {_x distance2D _replacement > 12}} < 0},90] call _wait;
    ["LIFE-zeus-midmove-replacement-arrival",_started && {_beforeArrival} && {_replacementReached},str (_units apply {getPosATL _x})] call _check;
    private _maxDrift=0;
    for "_sample" from 1 to 15 do {sleep 1; {_maxDrift=_maxDrift max (_x distance2D _replacement)} forEach _units};
    ["LIFE-zeus-midmove-no-resurrection",_replacementReached && {_maxDrift <= 15}
        && {(_group getVariable ["Waldo_AIPass_Defend",[]]) isEqualTo []},str _maxDrift] call _check;
};
[_group] call Waldo_fnc_CortexDefendRelease;
{deleteVehicle _x} forEach _units; deleteGroup _group;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];


// Separate casualty fixture retains the requested owner through death and arrival.
[createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],["Waldo_AIPass_Morale_Enable",false],["Waldo_AIPass_Regroup_Enable",false]]] call Waldo_fnc_CortexTuning;
_group=createGroup [east,true];
_group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_group setVariable ["acex_headless_blacklist",true,true];
_units=[];
for "_i" from 0 to 1 do {
    private _unit=_group createUnit ["O_Soldier_F",[2100+_i*3,2000,0],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",["CASUALTY LEADER","SUCCESSOR / MUST CONTINUE"] select _i,true];
    _unit disableAI "PATH";
    _units pushBack _unit;
};
private _oldLeader=_units select 0;
private _successor=_units select 1;
_group selectLeader _oldLeader;
_group setBehaviour "AWARE";
private _casualtyDestination=[2100,2110,0];
private _casualtyWP=_group addWaypoint [_casualtyDestination,0];
_casualtyWP setWaypointType "MOVE";
_casualtyWP setWaypointCompletionRadius 3;
_group setCurrentWaypoint _casualtyWP;
_successor setVariable ["Waldo_CortexQA_Target",_casualtyDestination,true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",_units,true];
if (_targetOwner != 2) then {[_targetOwner] call _migrate};
["Lifecycle: leader casualty on "+str _targetOwner,"The leader dies on the current server or HC owner. The survivor must become leader and physically continue to the destination without transferring back to the server.",[2100,2040,0]] call _phase;
private _beforeTravel=getPosATL _successor;
{[_x,"PATH"] remoteExecCall ["enableAI",owner _x]} forEach _units;
private _startedMoving=[{_successor distance2D _beforeTravel >= 8},25] call _wait;
["LIFE-casualty-moving-stimulus",_startedMoving && {_successor distance2D _casualtyDestination > 30} && {groupOwner _group == _targetOwner}] call _check;
private _casualtyStart=getPosATL _successor;
[_oldLeader,1] remoteExecCall ["setDamage",owner _oldLeader];
private _succession=[{!alive _oldLeader && {leader _group == _successor} && {alive _successor}},25] call _wait;
["LIFE-casualty-living-successor",_succession && {groupOwner _group == _targetOwner},str [groupOwner _group,netId leader _group]] call _check;
private _continued=[{alive _successor && {_successor distance2D _casualtyDestination < 8} && {_successor distance2D _casualtyStart >= 15}},75] call _wait;
["LIFE-casualty-physical-continuation",_succession && {_continued} && {groupOwner _group == _targetOwner},str [getPosATL _successor,groupOwner _group]] call _check;
{deleteVehicle _x} forEach _units;
deleteGroup _group;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];

} forEach _variants;

// A state handoff needs stronger evidence than ordinary waypoint migration. Start a real
// investigation from the same validated area-report payload used by the production report path,
// transfer it while moving, and require the new owner to continue the same bounded episode.
if (_owners isNotEqualTo []) then {
    [createHashMapFromArray [
        ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
        ["Waldo_AIPass_ContactReports_Enable",true],["Waldo_AIPass_Investigate_Enable",true],
        ["Waldo_AIPass_PostContact_Enable",true],["Waldo_AIPass_Morale_Enable",false],
        ["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_LambsMode","WMP"]
    ]] call Waldo_fnc_CortexTuning;
    private _stateGroup=createGroup [east,true];
    _stateGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _stateGroup setVariable ["acex_headless_blacklist",true,true];
    _stateGroup setCombatMode "BLUE";
    private _stateUnits=[];
    for "_i" from 0 to 2 do {
        private _unit=_stateGroup createUnit ["O_Soldier_F",[2320+_i*3,1700,0],[],0,"NONE"];
        _unit setVariable ["acex_headless_blacklist",true,true];
        _unit setVariable ["Waldo_CortexQA_Label",format ["STATE HANDOFF %1",_i+1],true];
        _stateUnits pushBack _unit;
    };
    _stateGroup setGroupIdGlobal ["QA STATE HANDOFF"];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",+_stateUnits,true];
    private _reportTarget=[2440,1700,0];
    {_x setVariable ["Waldo_CortexQA_Target",_reportTarget,true]} forEach _stateUnits;
    ["Lifecycle: investigation crosses ownership","A validated contact report starts a physical investigation. While the squad is moving, ownership transfers to a headless client. The same deadline and phase must continue without an artificial calm state.",_reportTarget] call _phase;
    _stateGroup setVariable ["Waldo_AIPass_AreaReport",[+_reportTarget,serverTime,serverTime+30,"REPORT"],true];
    private _investigating=[{
        (_stateGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "INVESTIGATE"
            && {count (_stateGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]) == 6}
    },30] call _wait;
    ["LIFE-state-investigation-start",_investigating,str [_stateGroup getVariable ["Waldo_AIPass_PublicPhase",""],_stateGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]]] call _recordCheck;
    private _intentBefore=+(_stateGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]);
    private _deadlineBefore=_intentBefore param [3,-1];
    private _handoffStart=getPosATL leader _stateGroup;
    private _stateOwner=_owners select 0;
    _stateGroup setVariable ["Waldo_Headless_ExcludeGroup",false,true];
    {_x setVariable ["acex_headless_blacklist",false,true]} forEach _stateUnits;
    private _migrationRequested=[_stateGroup,_stateOwner] call Waldo_fnc_HeadlessMigrateGroup;
    private _stateAdopted=[{
        groupOwner _stateGroup == _stateOwner
            && {_stateUnits findIf {owner _x != _stateOwner} < 0}
            && {(_stateGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "INVESTIGATE"}
            && {private _entry=_stateGroup getVariable ["Waldo_Cortex_PhaseTransition",[]]; count _entry == 5 && {(_entry select 3) == "OWNERSHIP_RESUME"} && {(_entry select 4) == _stateOwner}}
    },35] call _wait;
    ["LIFE-state-owner-resume",_migrationRequested && {_stateAdopted},str [groupOwner _stateGroup,_stateGroup getVariable ["Waldo_Cortex_PhaseTransition",[]]]] call _recordCheck;
    private _intentAfter=+(_stateGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]);
    ["LIFE-state-deadline-preserved",_stateAdopted && {count _intentAfter == 6} && {abs ((_intentAfter select 3)-_deadlineBefore) < 0.25},str [_deadlineBefore,_intentAfter]] call _recordCheck;
    private _continued=[{leader _stateGroup distance2D _handoffStart >= 10},35] call _wait;
    ["LIFE-state-physical-continuation",_stateAdopted && {_continued},str [_handoffStart,getPosATL leader _stateGroup]] call _recordCheck;

    // Curator replacement is the terminal authority boundary for the resumed episode.
    ["Lifecycle: Zeus replaces resumed investigation","After visible post-handoff movement, Zeus replaces the investigation. The squad must reach the replacement marker and the old INVESTIGATE intent must stay retired.",[2320,1780,0]] call _phase;
    [_stateGroup,true] call Waldo_fnc_CortexZeusMark;
    private _replacement=[2320,1780,0];
    private _replacementWP=_stateGroup addWaypoint [_replacement,0];
    _replacementWP setWaypointType "MOVE";
    _replacementWP setWaypointCompletionRadius 4;
    _stateGroup setCurrentWaypoint _replacementWP;
    {_x setVariable ["Waldo_CortexQA_Target",_replacement,true]} forEach _stateUnits;
    private _replacementArrived=[{_stateUnits findIf {!alive _x || {_x distance2D _replacement > 12}} < 0},90] call _wait;
    ["LIFE-state-zeus-replacement-arrival",_replacementArrived,str (_stateUnits apply {getPosATL _x})] call _recordCheck;
    private _stayedReleased=true;
    for "_sample" from 1 to 12 do {
        sleep 1;
        if ((_stateGroup getVariable ["Waldo_AIPass_PublicPhase","CALM"]) == "INVESTIGATE"
            || {(_stateGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]) isNotEqualTo []}) then {_stayedReleased=false};
    };
    ["LIFE-state-zeus-no-resurrection",_replacementArrived && {_stayedReleased},str [_stateGroup getVariable ["Waldo_AIPass_PublicPhase",""],_stateGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]]] call _recordCheck;
    {deleteVehicle _x} forEach _stateUnits;
    deleteGroup _stateGroup;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
};

// Exercise the other two durable combat intents through their production entry paths. SEARCH is
// reached from natural contact loss; RETREAT uses the common withdrawal controller after supplying
// the enemy position that the morale evaluator normally records.
if (_owners isNotEqualTo []) then {
    private _stateOwner=_owners select 0;
    [createHashMapFromArray [
        ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
        ["Waldo_AIPass_PostContact_Enable",true],["Waldo_AIPass_PostContact_LostSeconds",3],
        ["Waldo_AIPass_PostContact_SecuritySeconds",2],["Waldo_AIPass_PostContact_SearchSeconds",60],
        ["Waldo_AIPass_Morale_Enable",false],["Waldo_AIPass_Flank_Enable",false],
        ["Waldo_AIPass_Advance_Enable",false],["Waldo_AIPass_CoordinatedAssault_Enable",false],
        ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_LambsMode","WMP"]
    ]] call Waldo_fnc_CortexTuning;
    private _searchGroup=createGroup [east,true];
    private _searchEnemyGroup=createGroup [west,true];
    {
        _x setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        _x setVariable ["acex_headless_blacklist",true,true];
        _x setCombatMode "BLUE";
    } forEach [_searchGroup,_searchEnemyGroup];
    _searchEnemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
    private _searchUnits=[];
    for "_i" from 0 to 3 do {
        private _unit=_searchGroup createUnit ["O_Soldier_F",[2600+_i*3,1700,0],[],0,"NONE"];
        _unit setDir 0;
        _unit allowDamage false;
        _unit setVariable ["acex_headless_blacklist",true,true];
        _unit setVariable ["Waldo_CortexQA_Label",format ["SEARCH HANDOFF %1",_i+1],true];
        _searchUnits pushBack _unit;
    };
    private _searchEnemy=_searchEnemyGroup createUnit ["B_Soldier_F",[2600,1840,0],[],0,"NONE"];
    _searchEnemy setDir 180;
    _searchEnemy allowDamage false;
    _searchEnemy disableAI "PATH";
    _searchEnemy setVariable ["acex_headless_blacklist",true,true];
    _searchEnemy setVariable ["Waldo_CortexQA_Label","SEARCH CONTACT",true];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_searchUnits+[_searchEnemy],true];
    ["Lifecycle: search crosses ownership","The squad must naturally detect the visible opponent. After contact is removed, its two-soldier search starts on the server and continues on a headless client with the original deadline.",getPosATL _searchEnemy] call _phase;
    private _searchContact=[{(_searchGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "CONTACT"},35] call _wait;
    ["LIFE-search-natural-contact",_searchContact,str (_searchUnits apply {_x knowsAbout _searchEnemy})] call _recordCheck;
    private _searchTarget=getPosATL _searchEnemy;
    deleteVehicle _searchEnemy;
    private _searchStarted=[{
        (_searchGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "SEARCH"
            && {private _intent=_searchGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]; count _intent == 6 && {(_intent select 5) isNotEqualTo []}}
    },45] call _wait;
    ["LIFE-search-production-start",_searchContact && {_searchStarted},str [_searchGroup getVariable ["Waldo_AIPass_PublicPhase",""],_searchGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]]] call _recordCheck;
    private _searchIntentBefore=+(_searchGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]);
    private _searchDeadline=_searchIntentBefore param [3,-1];
    private _searchTeam=+(_searchIntentBefore param [5,[]]);
    private _searchStarts=_searchTeam apply {getPosATL _x};
    _searchGroup setVariable ["Waldo_Headless_ExcludeGroup",false,true];
    {_x setVariable ["acex_headless_blacklist",false,true]} forEach _searchUnits;
    private _searchMigration=[_searchGroup,_stateOwner] call Waldo_fnc_HeadlessMigrateGroup;
    private _searchAdopted=[{
        groupOwner _searchGroup == _stateOwner
            && {(_searchGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "SEARCH"}
            && {private _entry=_searchGroup getVariable ["Waldo_Cortex_PhaseTransition",[]]; count _entry == 5 && {(_entry select 3) == "OWNERSHIP_RESUME"} && {(_entry select 4) == _stateOwner}}
    },35] call _wait;
    ["LIFE-search-owner-resume",_searchMigration && {_searchAdopted},str [groupOwner _searchGroup,_searchGroup getVariable ["Waldo_Cortex_PhaseTransition",[]]]] call _recordCheck;
    private _searchIntentAfter=+(_searchGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]);
    ["LIFE-search-deadline-preserved",_searchAdopted && {count _searchIntentAfter == 6}
        && {abs ((_searchIntentAfter select 3)-_searchDeadline) < 0.25},str [_searchDeadline,_searchIntentAfter]] call _recordCheck;
    private _searchTravel=[{
        _searchTeam findIf {private _index=_searchTeam find _x; !alive _x || {_x distance2D (_searchStarts select _index) < 8}} < 0
    },40] call _wait;
    ["LIFE-search-physical-continuation",_searchAdopted && {_searchTravel},str [_searchTarget,_searchTeam apply {getPosATL _x}]] call _recordCheck;
    [_searchGroup,true] call Waldo_fnc_CortexZeusMark;
    private _searchReleased=[{
        (_searchGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "CALM"
            && {(_searchGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]) isEqualTo []}
    },20] call _wait;
    ["LIFE-search-zeus-release",_searchReleased,str [_searchGroup getVariable ["Waldo_AIPass_PublicPhase",""],_searchGroup getVariable ["Waldo_Cortex_TransitionIntent",[]]]] call _recordCheck;
    {deleteVehicle _x} forEach _searchUnits;
    deleteGroup _searchGroup;
    deleteGroup _searchEnemyGroup;

    [createHashMapFromArray [
        ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
        ["Waldo_AIPass_Morale_Enable",true],["Waldo_AIPass_Surrender_Enable",false],
        ["Waldo_AIPass_Morale_RetreatDistance",100],["Waldo_AIPass_Artillery_Enable",false],
        ["Waldo_AIPass_LambsMode","WMP"]
    ]] call Waldo_fnc_CortexTuning;
    private _retreatGroup=createGroup [east,true];
    _retreatGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _retreatGroup setVariable ["acex_headless_blacklist",true,true];
    _retreatGroup setCombatMode "YELLOW";
    private _retreatUnits=[];
    for "_i" from 0 to 2 do {
        private _unit=_retreatGroup createUnit ["O_Soldier_F",[2860+_i*3,1700,0],[],0,"NONE"];
        _unit allowDamage false;
        _unit addMagazine "SmokeShell";
        _unit setVariable ["acex_headless_blacklist",true,true];
        _unit setVariable ["Waldo_CortexQA_Label",format ["RETREAT HANDOFF %1",_i+1],true];
        _unit addEventHandler ["FiredMan",{
            params ["_unit","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile"];
            if (getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in ["shotSmoke","shotSmokeX"] && {!isNull _projectile}) then {
                private _records=_unit getVariable ["Waldo_CortexQA_SmokeThrows",[]];
                _records pushBack [_ammo,serverTime,getPosATL _projectile];
                _unit setVariable ["Waldo_CortexQA_SmokeThrows",_records,true];
            };
        }];
        _retreatUnits pushBack _unit;
    };
    missionNamespace setVariable ["Waldo_CortexQA_Actors",+_retreatUnits,true];
    private _retreatState=[_retreatGroup] call Waldo_fnc_CortexGroupState;
    _retreatState set ["enemyPos",[2860,1800,0]];
    private _retreatOrigin=getPosATL leader _retreatGroup;
    ["Lifecycle: withdrawal crosses ownership","The common withdrawal controller starts on the server, throws its one smoke screen and moves away from the threat. Ownership then transfers without replaying smoke or extending the episode.",_retreatOrigin getPos [100,180]] call _phase;
    private _retreatAccepted=[_retreatGroup,_retreatState] call Waldo_fnc_CortexRetreat;
    private _retreatStarted=[{
        (_retreatGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "RETREAT"
            && {count (_retreatGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]) == 7}
            && {leader _retreatGroup distance2D _retreatOrigin >= 8}
    },35] call _wait;
    ["LIFE-retreat-production-start",_retreatAccepted && {_retreatStarted},str [_retreatGroup getVariable ["Waldo_AIPass_PublicPhase",""],_retreatGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]]] call _recordCheck;
    private _smokeObserved=[{_retreatUnits findIf {(_x getVariable ["Waldo_CortexQA_SmokeThrows",[]]) isNotEqualTo []} >= 0},10] call _wait;
    ["LIFE-retreat-initial-smoke",_smokeObserved,str (_retreatUnits apply {_x getVariable ["Waldo_CortexQA_SmokeThrows",[]]})] call _recordCheck;
    private _smokeCountBefore=0;
    {_smokeCountBefore=_smokeCountBefore+count (_x getVariable ["Waldo_CortexQA_SmokeThrows",[]])} forEach _retreatUnits;
    private _withdrawalBefore=+(_retreatGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]);
    private _retreatStartedAt=_withdrawalBefore param [4,-1];
    private _retreatHandoffStart=getPosATL leader _retreatGroup;
    _retreatGroup setVariable ["Waldo_Headless_ExcludeGroup",false,true];
    {_x setVariable ["acex_headless_blacklist",false,true]} forEach _retreatUnits;
    private _retreatMigration=[_retreatGroup,_stateOwner] call Waldo_fnc_HeadlessMigrateGroup;
    private _retreatAdopted=[{
        groupOwner _retreatGroup == _stateOwner
            && {(_retreatGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "RETREAT"}
            && {private _entry=_retreatGroup getVariable ["Waldo_Cortex_PhaseTransition",[]]; count _entry == 5 && {(_entry select 3) == "OWNERSHIP_RESUME"} && {(_entry select 4) == _stateOwner}}
    },35] call _wait;
    ["LIFE-retreat-owner-resume",_retreatMigration && {_retreatAdopted},str [groupOwner _retreatGroup,_retreatGroup getVariable ["Waldo_Cortex_PhaseTransition",[]]]] call _recordCheck;
    private _withdrawalAfter=+(_retreatGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]);
    ["LIFE-retreat-start-preserved",_retreatAdopted && {count _withdrawalAfter == 7}
        && {abs ((_withdrawalAfter select 4)-_retreatStartedAt) < 0.25},str [_retreatStartedAt,_withdrawalAfter]] call _recordCheck;
    private _retreatContinued=[{leader _retreatGroup distance2D _retreatHandoffStart >= 10},35] call _wait;
    ["LIFE-retreat-physical-continuation",_retreatAdopted && {_retreatContinued},str [_retreatHandoffStart,getPosATL leader _retreatGroup]] call _recordCheck;
    sleep 6;
    private _smokeCountAfter=0;
    {_smokeCountAfter=_smokeCountAfter+count (_x getVariable ["Waldo_CortexQA_SmokeThrows",[]])} forEach _retreatUnits;
    ["LIFE-retreat-no-smoke-replay",_smokeObserved && {_smokeCountAfter == _smokeCountBefore},str [_smokeCountBefore,_smokeCountAfter]] call _recordCheck;
    [_retreatGroup,true] call Waldo_fnc_CortexZeusMark;
    private _retreatReleased=[{
        (_retreatGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "CALM"
            && {(_retreatGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]) isEqualTo []}
    },20] call _wait;
    private _retreatStayedReleased=_retreatReleased;
    for "_sample" from 1 to 12 do {
        sleep 1;
        if ((_retreatGroup getVariable ["Waldo_AIPass_PublicPhase","CALM"]) == "RETREAT"
            || {(_retreatGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]) isNotEqualTo []}) then {_retreatStayedReleased=false};
    };
    ["LIFE-retreat-zeus-no-resurrection",_retreatStayedReleased,str [_retreatGroup getVariable ["Waldo_AIPass_PublicPhase",""],_retreatGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]]] call _recordCheck;
    {deleteVehicle _x} forEach _retreatUnits;
    deleteGroup _retreatGroup;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
};
