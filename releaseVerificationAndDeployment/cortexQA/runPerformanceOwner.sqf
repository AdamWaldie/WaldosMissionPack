/*
 * Author: WaldoTheWarfighter
 * Installs the owner-local sampler and workload activator used by the distributed Cortex
 * performance audit.
 * Locality/authority: compiled on the server and every connected headless client during audit
 * pre-init. Waldo_CortexQA_PerformanceSampleOwner samples only groups local to that machine.
 * Repeat/JIP: replacing a sample removes the earlier EachFrame handler and advances a generation;
 * a late completion cannot publish over a newer run. Results are published once for the server
 * audit runner. This disposable helper is never staged outside the generated QA mission.
 *
 * Arguments to Waldo_CortexQA_PerformanceSampleOwner:
 * 0: sample id <STRING>
 * 1: duration <NUMBER> (default 60 seconds)
 * Arguments to Waldo_CortexQA_PerformanceStartGroup:
 * 0: locally owned subject group <GROUP>; 1: hostile target <OBJECT> (default objNull);
 * 2: destination ATL <ARRAY>; 3: whether this is a live-contact group <BOOL> (default false).
 *
 * Return Value: Nothing. Publishes Waldo_CortexQA_PerformanceResult_<sample id>_<owner id>.
 * Waldo_CortexQA_PerformanceStartGroup installs group-wide first-shot evidence and starts the
 * owner-local MOVE/SAD workload only after ownership and measurement baselines are ready.
 * Current callers: runPerformanceContact.sqf through remoteExecCall.
 * Example: ["ON1",60] call Waldo_CortexQA_PerformanceSampleOwner;
 * Example: [_group,_target,[200,410,0],true] call Waldo_CortexQA_PerformanceStartGroup;
 */
Waldo_CortexQA_PerformanceSampleOwner = {
    params [["_sampleId","",[""]],["_duration",60,[0]]];
    if (_sampleId == "" || {_duration <= 0}) exitWith {};
    private _oldHandler=missionNamespace getVariable ["Waldo_CortexQA_PerformanceFrameHandler",-1];
    if (_oldHandler >= 0) then {removeMissionEventHandler ["EachFrame",_oldHandler]};
    private _generation=(missionNamespace getVariable ["Waldo_CortexQA_PerformanceGeneration",0])+1;
    missionNamespace setVariable ["Waldo_CortexQA_PerformanceGeneration",_generation];
    missionNamespace setVariable ["Waldo_CortexQA_PerformanceFrameSamples",[]];
    private _handler=addMissionEventHandler ["EachFrame",{
        private _samples=missionNamespace getVariable ["Waldo_CortexQA_PerformanceFrameSamples",[]];
        if (count _samples < 180000) then {_samples pushBack (diag_deltaTime*1000)};
    }];
    missionNamespace setVariable ["Waldo_CortexQA_PerformanceFrameHandler",_handler];
    [_sampleId,_duration,_generation,clientOwner] spawn {
        params ["_sampleId","_duration","_generation","_sampleOwner"];
        private _maxOverdue=0;
        private _until=diag_tickTime+_duration;
        while {diag_tickTime < _until && {(missionNamespace getVariable ["Waldo_CortexQA_PerformanceGeneration",-1]) == _generation}} do {
            {
                _maxOverdue=_maxOverdue max (time-(_x param [0,time]));
            } forEach (missionNamespace getVariable ["Waldo_AIPass_Jobs",[]]);
            sleep 1;
        };
        if ((missionNamespace getVariable ["Waldo_CortexQA_PerformanceGeneration",-1]) != _generation) exitWith {};
        private _handler=missionNamespace getVariable ["Waldo_CortexQA_PerformanceFrameHandler",-1];
        if (_handler >= 0) then {removeMissionEventHandler ["EachFrame",_handler]};
        missionNamespace setVariable ["Waldo_CortexQA_PerformanceFrameHandler",-1];
        private _samples=missionNamespace getVariable ["Waldo_CortexQA_PerformanceFrameSamples",[]];
        _samples sort true;
        private _count=count _samples;
        private _percentile={
            params ["_fraction"];
            if (_count == 0) exitWith {1e9};
            _samples select floor ((_count-1)*_fraction)
        };
        private _localGroups=allGroups select {local _x && {_x getVariable ["Waldo_CortexQA_PerformanceGroup",false]}};
        private _localUnits=0;
        {_localUnits=_localUnits+({alive _x} count units _x)} forEach _localGroups;
        private _result=[_sampleOwner,_count,[0.5] call _percentile,[0.95] call _percentile,
            [0.99] call _percentile,_maxOverdue,count _localGroups,_localUnits];
        missionNamespace setVariable [format ["Waldo_CortexQA_PerformanceResult_%1_%2",_sampleId,_sampleOwner],_result,true];
        missionNamespace setVariable ["Waldo_CortexQA_PerformanceFrameSamples",nil];
    };
};

Waldo_CortexQA_PerformanceStartGroup = {
    params [
        ["_group",grpNull,[grpNull]],
        ["_target",objNull,[objNull]],
        ["_destination",[0,0,0],[[]],3],
        ["_contact",false,[false]]
    ];
    if (isNull _group || {!local _group}) exitWith {};
    _group setVariable ["Waldo_CortexQA_PerformanceFired",false,true];
    {
        _x addEventHandler ["FiredMan",{
            params ["_unit"];
            private _group=group _unit;
            if !(_group getVariable ["Waldo_CortexQA_PerformanceFired",false]) then {
                _group setVariable ["Waldo_CortexQA_PerformanceFired",true,true];
            };
        }];
    } forEach units _group;
    if (_contact && {!isNull _target}) then {
        _group reveal [_target,4];
        _group setBehaviour "COMBAT";
        _group setCombatMode "RED";
    } else {
        _group setBehaviour "AWARE";
        _group setCombatMode "YELLOW";
    };
    private _waypoint=_group addWaypoint [_destination,0];
    _waypoint setWaypointType (["MOVE","SAD"] select _contact);
    _waypoint setWaypointSpeed "FULL";
    _group setCurrentWaypoint _waypoint;
    _group setVariable ["Waldo_CortexQA_PerformanceStarted",true,true];
};

