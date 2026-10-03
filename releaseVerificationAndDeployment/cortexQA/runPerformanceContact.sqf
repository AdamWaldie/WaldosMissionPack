/*
 * Author: WaldoTheWarfighter
 * Measures matched Cortex OFF/ON/ON/OFF workloads across server and two WMP headless owners.
 * The infantry arm uses 50 six-soldier groups and real hostile contacts. The mixed arm uses 30
 * infantry squads, ten ground vehicles, six helicopters and four jets.
 * Locality/authority: scheduled dedicated-server fixture. Groups are deliberately migrated through
 * Waldo_fnc_HeadlessMigrateGroup; frame samples and queue health are collected on each real owner.
 * Repeat/JIP: fresh invulnerable actors per arm; published sampler results use unique ids and all
 * actors/groups are removed between arms. Late samplers are generation-guarded by their owner.
 *
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks; mixed <BOOL>
 * (default false) selects the representative combined-force arm.
 * Return Value: Nothing. Current caller: cortexQAServer.sqf for performancecontact and
 * performancemixed focuses.
 * Example: [_check,_phase,_wait,false] call compile preprocessFileLineNumbers "cortexQAPerformanceContact.sqf";
 */
params ["_check","_phase","_wait",["_mixed",false,[false]]];
private _prefix=["PERF-CONTACT","PERF-MIXED"] select _mixed;
missionNamespace setVariable ["Waldo_CortexQA_PerformanceContactCompleted",false];
private _hcOwners=((missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0}) select [0,2];
[format ["%1-two-headless-prerequisite",_prefix],count _hcOwners == 2,str _hcOwners] call _check;
if (count _hcOwners != 2) exitWith {};
private _owners=[2]+_hcOwners;
private _clientOwners=(allPlayers select {!(_x isKindOf "HeadlessClient_F")}) apply {owner _x};
private _sampleOwners=(_owners+_clientOwners) arrayIntersect (_owners+_clientOwners);
private _results=[];
private _ownersResponsive=true;
{
    private _enabled=_x;
    private _arm=_forEachIndex;
    if (!_ownersResponsive) exitWith {
        [format ["%1-arm-%2-owner-prerequisite",_prefix,_arm],false,"previous owner heartbeat stopped"] call _check;
    };
    private _liveHcOwners=(allPlayers select {_x isKindOf "HeadlessClient_F"}) apply {owner _x};
    if (_hcOwners findIf {!(_x in _liveHcOwners)} >= 0) exitWith {
        [format ["%1-arm-%2-owner-prerequisite",_prefix,_arm],false,str _liveHcOwners] call _check;
    };
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
    for "_row" from 0 to 4 do {
        for "_column" from 0 to 9 do {
            private _index=(_row*10)+_column;
            private _origin=[200+(_column*170),200+(_row*170),0];
            private _contact=if (_mixed) then {_index < 30 && {(_index mod 3) == 0}} else {(_index mod 4) == 0};
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
            private _group=grpNull;
            if (!_mixed || {_index < 30}) then {
                _group=createGroup [east,true];
                for "_member" from 0 to 5 do {
                    private _unit=_group createUnit ["O_Soldier_F",_origin vectorAdd [(_member mod 3)*2,floor (_member/3)*2,0],[],0,"NONE"];
                    _unit allowDamage false;
                    if (!_contact) then {_unit disableAI "TARGET"; _unit disableAI "AUTOTARGET"};
                    _actors pushBack _unit;
                };
            } else {
                private _class=if (_index < 40) then {"O_MRAP_02_F"} else {if (_index < 46) then {"O_Heli_Light_02_unarmed_F"} else {"O_Plane_CAS_02_dynamicLoadout_F"}};
                private _placement=if (_index >= 40) then {"FLY"} else {"NONE"};
                private _spawnOrigin=+_origin;
                if (_index >= 40 && {_index < 46}) then {_spawnOrigin set [2,90]};
                if (_index >= 46) then {_spawnOrigin set [2,250]};
                private _vehicle=createVehicle [_class,_spawnOrigin,[],0,_placement];
                _vehicle allowDamage false;
                _vehicle setDir 0;
                _vehicle engineOn true;
                if (_index >= 40 && {_index < 46}) then {_vehicle flyInHeight 90};
                if (_index >= 46) then {
                    _vehicle flyInHeight 250;
                    _vehicle setVelocityModelSpace [0,140,0];
                };
                createVehicleCrew _vehicle;
                _group=group effectiveCommander _vehicle;
                {
                    _x allowDamage false;
                    _x disableAI "TARGET";
                    _x disableAI "AUTOTARGET";
                    _actors pushBack _x;
                } forEach crew _vehicle;
                _actors pushBack _vehicle;
            };
            _group setVariable ["Waldo_CortexQA_PerformanceGroup",true,true];
            _group setVariable ["Waldo_AIPass_Exclude",!_enabled,true];
            _groups pushBack _group;
            _groupTargets pushBack _target;
            _destinations pushBack (_origin vectorAdd [0,if (_mixed && {_index >= 40}) then {1000} else {210},0]);
            if (_contact) then {_contactGroups pushBack _group};
            // WMP deliberately refuses to migrate an active helicopter in flight. Keep every air
            // group on the server in both native and Cortex arms so the benchmark measures the
            // production locality policy instead of treating that protection as a fixture failure.
            private _desiredOwner=if (_mixed && {_index >= 40}) then {2} else {_owners select (_index mod count _owners)};
            if (_desiredOwner == 2) then {
                _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
            } else {
                [_group,_desiredOwner] call Waldo_fnc_HeadlessMigrateGroup;
            };
            // Arma creates every group on the server before ownership transfer. A short pacing
            // interval avoids presenting the engine allocator with 66 near-simultaneous six-unit
            // migrations while still keeping fixture assembly outside the measured window.
            sleep 0.05;
        };
    };
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors select [0,18],true];
    // The engine can transiently refuse the tail of a burst of setGroupOwner requests even while
    // both HCs remain healthy. Retry only groups which have not reached their declared owner; the
    // measured window still begins after ownership settles, and a persistent refusal remains a
    // hard failed prerequisite rather than silently changing the workload.
    for "_retry" from 0 to 4 do {
        private _pending=[];
        {
            private _index=_forEachIndex;
            private _desiredOwner=if (_mixed && {_index >= 40}) then {2} else {_owners select (_index mod count _owners)};
            if (groupOwner _x != _desiredOwner) then {_pending pushBack [_x,_desiredOwner]};
        } forEach _groups;
        if (_pending isEqualTo []) exitWith {};
        sleep 2;
        {
            _x params ["_pendingGroup","_pendingOwner"];
            [_pendingGroup,_pendingOwner] call Waldo_fnc_HeadlessMigrateGroup;
            sleep 0.1;
        } forEach _pending;
    };
    [format ["Performance %1: arm %2 / Cortex %3",["infantry","mixed force"] select _mixed,_arm+1,["OFF","ON"] select _enabled],
        (["Fifty six-soldier squads move across the server and two headless owners. Thirteen squads receive controlled contacts.","Fifty groups combine 30 infantry squads, ten ground vehicles, six helicopters and four jets; ten infantry squads receive controlled contacts."] select _mixed)+" Physical movement, real fire, queue health and server, HC and client frame times are measured.",[1800,1800,0]] call _phase;
    private _ownershipReady=[{
        _groups findIf {
            private _index=_groups find _x;
            private _desiredOwner=if (_mixed && {_index >= 40}) then {2} else {_owners select (_index mod count _owners)};
            groupOwner _x != _desiredOwner
        } < 0
    },90] call _wait;
    private _ownerCounts=_owners apply {private _owner=_x; {groupOwner _x == _owner} count _groups};
    private _balanced=if (_mixed) then {
        // Ten flight groups remain server-local; the forty land groups remain round-robin.
        _ownerCounts isEqualTo [24,13,13]
    } else {
        (_ownerCounts select 0) >= 16 && {(_ownerCounts select 1) >= 16} && {(_ownerCounts select 2) >= 16}
    };
    [format ["%1-arm-%2-balanced-ownership",_prefix,_arm],_ownershipReady && {_balanced},str _ownerCounts] call _check;
    private _ownerUnitBaselines=_owners apply {private _owner=_x; private _total=0; {{if (alive _x) then {_total=_total+1}} forEach units _x} forEach (_groups select {groupOwner _x == _owner}); _total};
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
        [_x,_groupTargets select _index,_destinations select _index,_x in _contactGroups]
            remoteExecCall ["Waldo_CortexQA_PerformanceStartGroup",groupOwner _x];
        // Stagger path requests across frames. Sending 33 six-unit groups to one HC in a single
        // burst can leave the process connected while its simulation thread stops advancing.
        sleep 0.05;
    } forEach _groups;
    private _startReady=[{
        _groups findIf {!(_x getVariable ["Waldo_CortexQA_PerformanceStarted",false])} < 0
    },20] call _wait;
    [format ["%1-arm-%2-owner-start",_prefix,_arm],_startReady,""] call _check;
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
            if (_responding >= ([10,8] select _mixed)) then {_responseLatency=diag_tickTime-_responseStart};
        };
        sleep 1;
    };
    private _sampleReady=[{
        _sampleOwners findIf {(missionNamespace getVariable [format ["Waldo_CortexQA_PerformanceResult_%1_%2",_sampleId,_x],[]]) isEqualTo []} < 0
    },20] call _wait;
    private _ownerResults=_owners apply {missionNamespace getVariable [format ["Waldo_CortexQA_PerformanceResult_%1_%2",_sampleId,_x],[]]};
    private _sampleResults=_sampleOwners apply {missionNamespace getVariable [format ["Waldo_CortexQA_PerformanceResult_%1_%2",_sampleId,_x],[]]};
    private _ownerHeartbeats=_owners apply {missionNamespace getVariable [format ["Waldo_CortexQA_PerformanceHeartbeat_%1_%2",_sampleId,_x],-1]};
    _ownersResponsive=_ownerHeartbeats findIf {_x < 0 || {serverTime-_x > 5}} < 0;
    [format ["%1-arm-%2-owner-responsive",_prefix,_arm],_ownersResponsive,str _ownerHeartbeats] call _check;
    private _survivingHcOwners=(allPlayers select {_x isKindOf "HeadlessClient_F"}) apply {owner _x};
    private _ownersStillLive=_hcOwners findIf {!(_x in _survivingHcOwners)} < 0;
    [format ["%1-arm-%2-owner-survival",_prefix,_arm],_ownersStillLive,str _survivingHcOwners] call _check;
    private _moved={
        private _index=_groups find _x;
        (_starts select _index) findIf {(_x select 0) distance2D (_x select 1) >= 20} >= 0
    } count _groups;
    private _fired={_x getVariable ["Waldo_CortexQA_PerformanceFired",false]} count _contactGroups;
    private _ownerLoadsValid=true;
    {_ownerLoadsValid=_ownerLoadsValid && {count _x == 8} && {(_x select 1) >= 100} && {(_x select 6) >= (_ownerCounts select _forEachIndex)} && {(_x select 7) >= (_ownerUnitBaselines select _forEachIndex)}} forEach _ownerResults;
    private _valid=_ready && {_ownershipReady} && {_startReady} && {_sampleReady} && {_ownersStillLive} && {_ownersResponsive} && {_ownerLoadsValid}
        && {_moved >= 45} && {_fired >= ([8,6] select _mixed)} && {_responseLatency >= 0};
    [format ["%1-arm-%2-physical-workload",_prefix,_arm],_valid,
        format ["movedGroups=%1 firedContactGroups=%2 responseSeconds=%3 samples=%4",_moved,_fired,_responseLatency,_sampleResults]] call _check;
    [format ["%1-arm-%2-no-starvation",_prefix,_arm],_sampleReady && {_ownerResults findIf {(_x select 5) > 10} < 0},str _ownerResults] call _check;
    _results pushBack [_sampleResults,_valid,_responseLatency];
    private _ownedGroups=_groups apply {[_x,groupOwner _x]};
    {deleteVehicle _x} forEach (_actors+_targets);
    {
        _x params ["_ownedGroup","_ownedBy"];
        [_ownedGroup] remoteExecCall ["Waldo_CortexQA_PerformanceDeleteGroup",_ownedBy];
    } forEach _ownedGroups;
    {deleteGroup _x} forEach _targetGroups;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    sleep 10;
} forEach [false,true,true,false];
private _allValid=count _results == 4 && {_results findIf {!(_x select 1)} < 0};
[format ["%1-comparable-arms",_prefix],_allValid,str _results] call _check;
if (_allValid) then {
    {
        private _ownerIndex=_forEachIndex;
        private _baseMedian=((_results select 0 select 0 select _ownerIndex select 2)+(_results select 3 select 0 select _ownerIndex select 2))/2;
        private _baseP95=((_results select 0 select 0 select _ownerIndex select 3)+(_results select 3 select 0 select _ownerIndex select 3))/2;
        {
            private _row=_results select _x select 0 select _ownerIndex;
            [format ["%1-owner-%2-on-%3-median-budget",_prefix,_sampleOwners select _ownerIndex,_x],(_row select 2) <= _baseMedian*1.05,str [_row select 2,_baseMedian]] call _check;
            [format ["%1-owner-%2-on-%3-p95-budget",_prefix,_sampleOwners select _ownerIndex,_x],(_row select 3) <= _baseP95*1.10,str [_row select 3,_baseP95,_row select 4]] call _check;
        } forEach [1,2];
    } forEach _sampleOwners;
};
missionNamespace setVariable ["Waldo_CortexQA_PerformanceContactCompleted",true];
