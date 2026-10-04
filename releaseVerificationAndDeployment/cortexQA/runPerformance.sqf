/*
 * Author: WaldoTheWarfighter
 * Measures a matched 50-group, 300-soldier patrol workload with Cortex OFF/ON/ON/OFF.
 * Locality/authority: scheduled dedicated-server fixture; all actors stay server-owned.
 * Repeat/JIP: fresh actors per arm; removes its frame handler and actors after each sample.
 * Caller restores tuning. No JIP runner. This pilot does not establish HC/contact/matrix acceptance.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAPerformance.sqf";
 */
params ["_check","_phase","_wait"];
private _results=[];
{
    private _enabled=_x;
    private _arm=_forEachIndex;
    [createHashMapFromArray [["Waldo_AIPass_Enable",_enabled]]] call Waldo_fnc_CortexTuning;
    private _ready=[{(missionNamespace getVariable ["Waldo_AIPass_Active",false]) == _enabled},20] call _wait;
    private _groups=[]; private _actors=[];
    for "_i" from 0 to 49 do {
        private _g=createGroup [east,true];
        _g setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        _g setVariable ["acex_headless_blacklist",true,true];
        private _origin=[800+(_i mod 10)*35,800+floor (_i/10)*35,0];
        for "_j" from 0 to 5 do {
            private _u=_g createUnit ["O_Soldier_F",_origin vectorAdd [(_j mod 3)*2,floor (_j/3)*2,0],[],0,"NONE"];
            _u setVariable ["acex_headless_blacklist",true,true];
            _actors pushBack _u;
        };
        _g setBehaviour "AWARE"; _g setCombatMode "BLUE";
        private _wp=_g addWaypoint [_origin vectorAdd [0,2000,0],0];
        _wp setWaypointType "MOVE"; _wp setWaypointSpeed "NORMAL";
        _g setCurrentWaypoint _wp;
        _groups pushBack _g;
        sleep 0.01;
    };
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors select [0,18],true];
    [format ["Performance: arm %1 / Cortex %2",_arm+1,["OFF","ON"] select _enabled],"50 six-soldier squads patrol on the server. Only 18 soldiers have overlays to limit UI cost. After warm-up, record 60 seconds of frame times and physical movement. This matched flat baseline isolates scheduler cost; separate terrain and mixed-force audits establish behaviour.",[950,1000,0]] call _phase;
    sleep 20;
    private _managedMinimum=50;
    private _eligibleAll=true;
    private _origins=_groups apply {getPosATL leader _x};
    missionNamespace setVariable ["Waldo_CortexQA_FrameSamples",[]];
    private _handler=addMissionEventHandler ["EachFrame",{
        private _samples=missionNamespace getVariable ["Waldo_CortexQA_FrameSamples",[]];
        if (count _samples < 120000) then {_samples pushBack (diag_deltaTime*1000)};
    }];
    private _overdue=0;
    private _until=diag_tickTime+60;
    while {diag_tickTime < _until} do {
        sleep 1;
        // Identical observation cost in both arms; master-off eligibility is not an acceptance gate.
        _managedMinimum=_managedMinimum min ({_x getVariable ["Waldo_AIPass_Managed",false]} count _groups);
        private _eligibleCount={[_x] call Waldo_fnc_CortexIsEligible} count _groups;
        if (_eligibleCount != 50) then {_eligibleAll=false};
        {_overdue=_overdue max (time-(_x select 0))} forEach (missionNamespace getVariable ["Waldo_AIPass_Jobs",[]]);
    };
    removeMissionEventHandler ["EachFrame",_handler];
    private _samples=missionNamespace getVariable ["Waldo_CortexQA_FrameSamples",[]];
    _samples sort true;
    private _count=count _samples;
    private _median=if (_count > 0) then {_samples select floor ((_count-1)*0.5)} else {1e9};
    private _p95=if (_count > 0) then {_samples select floor ((_count-1)*0.95)} else {1e9};
    private _moved=true;
    {if (leader _x distance2D (_origins select _forEachIndex) < 20) then {_moved=false}} forEach _groups;
    private _valid=_ready && {_count >= 100} && {_count < 120000} && {count _groups == 50} && {count _actors == 300}
        && {_actors findIf {!alive _x || {owner _x != 2}} < 0} && {_moved} && {!_enabled || {_managedMinimum == 50 && {_eligibleAll}}};
    [format ["PERF-50-patrol-arm-%1-valid",_arm],_valid,format ["frames=%1 medianMs=%2 p95Ms=%3 maxOverdueSeconds=%4 allGroupsMoved=%5 minimumManaged=%6 allEligible=%7",_count,_median,_p95,_overdue,_moved,_managedMinimum,_eligibleAll]] call _check;
    [format ["PERF-50-patrol-arm-%1-no-starvation",_arm],_overdue <= 10,str _overdue] call _check;
    _results pushBack [_median,_p95,_valid,_overdue];
    {deleteVehicle _x} forEach _actors; {deleteGroup _x} forEach _groups;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    missionNamespace setVariable ["Waldo_CortexQA_FrameSamples",nil];
    sleep 10;
} forEach [false,true,true,false];
private _baseMedian=((_results select 0 select 0)+(_results select 3 select 0))/2;
private _baseP95=((_results select 0 select 1)+(_results select 3 select 1))/2;
private _comparable=_results findIf {!(_x select 2)} < 0 && {_baseMedian > 0} && {_baseP95 > 0}
    && {abs ((_results select 0 select 0)-(_results select 3 select 0))/_baseMedian <= 0.05};
["PERF-50-patrol-comparable-baselines",_comparable,str _results] call _check;
{
    private _row=_results select _x;
    [format ["PERF-50-patrol-on-%1-median-budget",_x],_comparable && {(_row select 0) <= _baseMedian*1.05},str [_row select 0,_baseMedian]] call _check;
    [format ["PERF-50-patrol-on-%1-p95-budget",_x],_comparable && {(_row select 1) <= _baseP95*1.10},str [_row select 1,_baseP95]] call _check;
} forEach [1,2];
