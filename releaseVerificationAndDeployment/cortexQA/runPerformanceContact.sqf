/*
 * Author: WaldoTheWarfighter
 * Measures matched Cortex OFF/ON/ON/OFF sustained-contact workloads across server and two WMP
 * headless owners using 100 six-soldier manoeuvre groups and real hostile contacts.
 * Locality/authority: scheduled dedicated-server fixture. Groups are deliberately migrated through
 * Waldo_fnc_HeadlessMigrateGroup; frame samples and queue health are collected on each real owner.
 * Repeat/JIP: fresh invulnerable actors per arm; published sampler results use unique ids and all
 * actors/groups are removed between arms. Late samplers are generation-guarded by their owner.
 *
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks.
 * Return Value: Nothing. Current caller: cortexQAServer.sqf for performancecontact focus.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAPerformanceContact.sqf";
 */
params ["_check","_phase","_wait"];
missionNamespace setVariable ["Waldo_CortexQA_PerformanceContactCompleted",false];
private _hcOwners=((missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0}) select [0,2];
["PERF-CONTACT-two-headless-prerequisite",count _hcOwners == 2,str _hcOwners] call _check;
if (count _hcOwners != 2) exitWith {};
private _owners=[2]+_hcOwners;
private _clientOwners=(allPlayers select {!(_x isKindOf "HeadlessClient_F")}) apply {owner _x};
private _sampleOwners=(_owners+_clientOwners) arrayIntersect (_owners+_clientOwners);
private _results=[];
{
    private _enabled=_x;
    private _arm=_forEachIndex;
    private _sampleId=format ["CONTACT_%1_%2",_arm,floor serverTime];
    [createHashMapFromArray [["Waldo_AIPass_Enable",_enabled],["Waldo_AIPass_Contact_Enable",true],
        ["Waldo_AIPass_Regroup_Enable",true],["Waldo_AIPass_LambsMode","SPLIT"]]] call Waldo_fnc_CortexTuning;
    private _ready=[{(missionNamespace getVariable ["Waldo_AIPass_Active",false]) == _enabled},30] call _wait;
    private _groups=[];
    private _actors=[];
    private _targets=[];
    private _groupTargets=[];
    private _destinations=[];
    private _contactGroups=[];
    private _targetGroups=[];
    private _targetGroup=createGroup [west,true];
    _targetGroup setVariable ["Waldo_AIPass_Exclude",true,true];
    _targetGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _targetGroup setVariable ["acex_headless_blacklist",true,true];
    _targetGroup setBehaviour "CARELESS";
    _targetGroup setCombatMode "BLUE";
    _targetGroups pushBack _targetGroup;
    for "_row" from 0 to 9 do {
        for "_column" from 0 to 9 do {
            private _index=(_row*10)+_column;
            private _origin=[200+(_column*170),200+(_row*170),0];
            private _contact=(_index mod 4) == 0;
            private _target=objNull;
            if (_contact) then {
                _target=_targetGroup createUnit ["B_Soldier_F",_origin vectorAdd [0,150,0],[],0,"NONE"];
                _target allowDamage false;
                _target setCaptive true;
                _target disableAI "MOVE";
                _target disableAI "TARGET";
                _target disableAI "AUTOTARGET";
                _target setUnitPos "MIDDLE";
                _targets pushBack _target;
            };
            private _group=createGroup [east,true];
            _group setVariable ["Waldo_CortexQA_PerformanceGroup",true,true];
            _group setVariable ["Waldo_AIPass_Exclude",!_enabled,true];
            for "_member" from 0 to 5 do {
                private _unit=_group createUnit ["O_Soldier_F",_origin vectorAdd [(_member mod 3)*2,floor (_member/3)*2,0],[],0,"NONE"];
                _unit allowDamage false;
                if (!_contact) then {_unit disableAI "TARGET"; _unit disableAI "AUTOTARGET"};
                _actors pushBack _unit;
            };
            _groups pushBack _group;
            _groupTargets pushBack _target;
            _destinations pushBack (_origin vectorAdd [0,210,0]);
            if (_contact) then {_contactGroups pushBack _group};
            private _desiredOwner=_owners select (_index mod count _owners);
            if (_desiredOwner == 2) then {
                _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
            } else {
                [_group,_desiredOwner] call Waldo_fnc_HeadlessMigrateGroup;
            };
            sleep 0.01;
        };
    };
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors select [0,18],true];
    [format ["Performance contact: arm %1 / Cortex %2",_arm+1,["OFF","ON"] select _enabled],
        "One hundred six-soldier squads move across the server and two headless owners. A controlled cohort of 25 squads engages real invulnerable contacts while 75 execute matched ordinary movement. Only 18 soldiers are labelled. Physical movement, ammunition use, queue health and server, HC and client frame times are measured.",[1800,1800,0]] call _phase;
    private _ownershipReady=[{
        _groups findIf {private _index=_groups find _x; groupOwner _x != (_owners select (_index mod count _owners))} < 0
    },90] call _wait;
    private _ownerCounts=_owners apply {private _owner=_x; {groupOwner _x == _owner} count _groups};
    private _balanced=(_ownerCounts select 0) >= 33 && {(_ownerCounts select 1) >= 33} && {(_ownerCounts select 2) >= 33};
    [format ["PERF-CONTACT-arm-%1-balanced-ownership",_arm],_ownershipReady && {_balanced},str _ownerCounts] call _check;
    sleep 20;
    private _starts=_groups apply {(units _x) apply {[_x,getPosATL _x]}};
    {
        missionNamespace setVariable [format ["Waldo_CortexQA_PerformanceResult_%1_%2",_sampleId,_x],nil,true];
        [_sampleId,60] remoteExecCall ["Waldo_CortexQA_PerformanceSampleOwner",_x];
    } forEach _sampleOwners;
    private _responseStart=diag_tickTime;
    {if (!isNull _x) then {_x setCaptive false}} forEach _targets;
    {
        private _index=_forEachIndex;
        [_x,_groupTargets select _index,_destinations select _index,(_index mod 4) == 0]
            remoteExecCall ["Waldo_CortexQA_PerformanceStartGroup",groupOwner _x];
    } forEach _groups;
    private _startReady=[{
        _groups findIf {!(_x getVariable ["Waldo_CortexQA_PerformanceStarted",false])} < 0
    },20] call _wait;
    [format ["PERF-CONTACT-arm-%1-owner-start",_arm],_startReady,""] call _check;
    private _responseLatency=-1;
    private _until=_responseStart+60;
    while {diag_tickTime < _until} do {
        if (_responseLatency < 0) then {
            private _responding={
                private _index=_groups find _x;
                private _physicallyMoved=(_starts select _index) findIf {
                    (_x select 0) distance2D (_x select 1) >= 10
                } >= 0;
                _physicallyMoved || {_x getVariable ["Waldo_CortexQA_PerformanceFired",false]}
            } count _contactGroups;
            if (_responding >= 20) then {_responseLatency=diag_tickTime-_responseStart};
        };
        sleep 1;
    };
    private _sampleReady=[{
        _sampleOwners findIf {(missionNamespace getVariable [format ["Waldo_CortexQA_PerformanceResult_%1_%2",_sampleId,_x],[]]) isEqualTo []} < 0
    },20] call _wait;
    private _ownerResults=_owners apply {missionNamespace getVariable [format ["Waldo_CortexQA_PerformanceResult_%1_%2",_sampleId,_x],[]]};
    private _sampleResults=_sampleOwners apply {missionNamespace getVariable [format ["Waldo_CortexQA_PerformanceResult_%1_%2",_sampleId,_x],[]]};
    private _moved={
        private _index=_groups find _x;
        (_starts select _index) findIf {(_x select 0) distance2D (_x select 1) >= 20} >= 0
    } count _groups;
    private _fired={_x getVariable ["Waldo_CortexQA_PerformanceFired",false]} count _contactGroups;
    private _valid=_ready && {_ownershipReady} && {_startReady} && {_sampleReady} && {_ownerResults findIf {count _x != 8 || {(_x select 1) < 100} || {(_x select 6) < 33} || {(_x select 7) < 198}} < 0}
        && {_moved >= 90} && {_fired >= 15} && {_responseLatency >= 0};
    [format ["PERF-CONTACT-arm-%1-physical-workload",_arm],_valid,
        format ["movedGroups=%1 firedContactGroups=%2 responseSeconds=%3 samples=%4",_moved,_fired,_responseLatency,_sampleResults]] call _check;
    [format ["PERF-CONTACT-arm-%1-no-starvation",_arm],_sampleReady && {_ownerResults findIf {(_x select 5) > 10} < 0},str _ownerResults] call _check;
    _results pushBack [_sampleResults,_valid,_responseLatency];
    {deleteVehicle _x} forEach (_actors+_targets);
    {deleteGroup _x} forEach (_groups+_targetGroups);
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    sleep 10;
} forEach [false,true,true,false];
private _allValid=_results findIf {!(_x select 1)} < 0;
["PERF-CONTACT-comparable-arms",_allValid,str _results] call _check;
if (_allValid) then {
    {
        private _ownerIndex=_forEachIndex;
        private _baseMedian=((_results select 0 select 0 select _ownerIndex select 2)+(_results select 3 select 0 select _ownerIndex select 2))/2;
        private _baseP95=((_results select 0 select 0 select _ownerIndex select 3)+(_results select 3 select 0 select _ownerIndex select 3))/2;
        {
            private _row=_results select _x select 0 select _ownerIndex;
            [format ["PERF-CONTACT-owner-%1-on-%2-median-budget",_sampleOwners select _ownerIndex,_x],(_row select 2) <= _baseMedian*1.05,str [_row select 2,_baseMedian]] call _check;
            [format ["PERF-CONTACT-owner-%1-on-%2-p95-budget",_sampleOwners select _ownerIndex,_x],(_row select 3) <= _baseP95*1.10,str [_row select 3,_baseP95,_row select 4]] call _check;
        } forEach [1,2];
    } forEach _sampleOwners;
};
missionNamespace setVariable ["Waldo_CortexQA_PerformanceContactCompleted",true];
