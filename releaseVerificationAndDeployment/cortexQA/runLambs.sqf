/*
 * Author: WaldoTheWarfighter
 * Verifies Cortex standalone movement and, when the installed LAMBS suite is loaded, finite
 * movement ownership, busy-tactic refusal, baseline restoration and Zeus handover.
 *
 * Locality/authority: the dedicated server creates and owns the fixture group. Lease mutation and
 * movement orders execute on that group owner. Public lease and LAMBS variables make ownership
 * visible to clients/JIP observers and preserve it if a later test transfers the group.
 * Repeat/JIP: every run creates fresh actors, removes temporary waypoints, releases the Cortex
 * lease, clears published diagnostics and deletes the fixture. Re-running cannot inherit a lease.
 *
 * Arguments:
 * 0: check <CODE> - records id, Boolean result and optional detail
 * 1: phase <CODE> - publishes the visible stage and observation instructions
 * 2: wait <CODE> - waits for a predicate with a timeout
 *
 * Return Value: Nothing.
 * Current caller: cortexQAServer.sqf through -CortexFocus lambs and the additive feature audit.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQALambs.sqf";
 */
params ["_check","_phase","_wait"];

private _lambsLoaded=isClass (configFile >> "CfgPatches" >> "lambs_danger");
["LAMBS-environment-detected",true,["Cortex standalone arm","Installed LAMBS compatibility arm"] select _lambsLoaded] call _check;

private _group=createGroup [east,true];
_group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_group setVariable ["acex_headless_blacklist",true,true];
_group setGroupIdGlobal ["Cortex QA LAMBS handover"];
private _units=[];
for "_i" from 0 to 2 do {
    private _unit=_group createUnit ["O_Soldier_F",[2600+(_i*3),2400,0],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["LAMBS PAIR SOLDIER %1",_i+1],true];
    _units pushBack _unit;
};
missionNamespace setVariable ["Waldo_CortexQA_Actors",_units,true];

// In the loaded arm WMP mode deliberately gives Cortex the entire group. In the absent arm the
// same order proves the fallback has no hidden LAMBS dependency.
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],
    ["Waldo_AIPass_Contact_Enable",false],
    ["Waldo_AIPass_Regroup_Enable",false],
    ["Waldo_AIPass_LambsMode","WMP"]
]] call Waldo_fnc_CortexTuning;
[{missionNamespace getVariable ["Waldo_AIPass_Active",false]},20] call _wait;
private _fallbackDestination=[2600,2470,0];
{_x setVariable ["Waldo_CortexQA_Target",_fallbackDestination,true]} forEach _units;
["LAMBS: standalone Cortex movement","All three soldiers must physically move north and hold their separate defence positions. This is the Cortex fallback arm and cannot pass from an accepted order alone.",_fallbackDestination] call _phase;
private _starts=_units apply {getPosATL _x};
private _accepted=[_group,_fallbackDestination,0,14] call Waldo_fnc_CortexDefend;
private _arrived=[{
    (_units findIf {
        private _assignment=_x getVariable ["Waldo_AIPass_DefendPos",[]];
        !alive _x || {_assignment isEqualTo []} || {_x distance2D (_assignment select 0) > 5}
    }) < 0
},90] call _wait;
private _travelled=true;
{
    if (_x distance2D (_starts select _forEachIndex) < 35) then {_travelled=false};
} forEach _units;
["LAMBS-fallback-physical-arrival",_accepted && {_arrived} && {_travelled},str (_units apply {getPosATL _x})] call _check;
private _maxHoldDrift=0;
for "_sample" from 1 to 5 do {
    sleep 1;
    {
        private _assignment=_x getVariable ["Waldo_AIPass_DefendPos",[]];
        if (_assignment isNotEqualTo []) then {_maxHoldDrift=_maxHoldDrift max (_x distance2D (_assignment select 0))};
    } forEach _units;
};
["LAMBS-fallback-sustained-hold",_arrived && {_maxHoldDrift <= 7},str _maxHoldDrift] call _check;
[_group] call Waldo_fnc_CortexDefendRelease;

if (_lambsLoaded) then {
    [createHashMapFromArray [["Waldo_AIPass_LambsMode","SPLIT"]]] call Waldo_fnc_CortexTuning;
    _group setVariable ["Waldo_AIPass_LambsDisabledByPass",false,true];
    _group setVariable ["Waldo_Cortex_LambsLease",nil,true];
    _group setVariable ["lambs_danger_disableGroupAI",false,true];

    _group setVariable ["lambs_danger_isExecutingTactic",true,true];
    private _refusedTactic=!([_group,"QA",true,serverTime+60] call Waldo_fnc_CortexLambsLease);
    ["LAMBS-active-tactic-keeps-ownership",_refusedTactic && {(_group getVariable ["Waldo_Cortex_LambsLease",[]]) isEqualTo []}
        && {!(_group getVariable ["lambs_danger_disableGroupAI",false])}] call _check;
    _group setVariable ["lambs_danger_isExecutingTactic",false,true];

    (_units select 1) setVariable ["lambs_danger_forceMove",true,true];
    private _refusedForce=!([_group,"QA",true,serverTime+60] call Waldo_fnc_CortexLambsLease);
    ["LAMBS-forced-unit-keeps-ownership",_refusedForce && {(_group getVariable ["Waldo_Cortex_LambsLease",[]]) isEqualTo []}] call _check;
    (_units select 1) setVariable ["lambs_danger_forceMove",false,true];

    _group setVariable ["lambs_main_currentTactic","taskPatrol",true];
    private _refusedTask=!([_group,"QA",true,serverTime+60] call Waldo_fnc_CortexLambsLease);
    ["LAMBS-waypoint-task-keeps-ownership",_refusedTask && {(_group getVariable ["Waldo_Cortex_LambsLease",[]]) isEqualTo []}] call _check;
    _group setVariable ["lambs_main_currentTactic",nil,true];

    private _leased=[_group,"QA",true,serverTime+120] call Waldo_fnc_CortexLambsLease;
    ["LAMBS-clean-group-lease",_leased && {(_group getVariable ["Waldo_Cortex_LambsLease",[]]) param [0,""] == "QA"}
        && {_group getVariable ["lambs_danger_disableGroupAI",false]}] call _check;
    private _released=[_group,"QA",false] call Waldo_fnc_CortexLambsLease;
    ["LAMBS-false-baseline-restored",_released && {(_group getVariable ["Waldo_Cortex_LambsLease",[]]) isEqualTo []}
        && {!(_group getVariable ["lambs_danger_disableGroupAI",true])}] call _check;

    _group setVariable ["lambs_danger_disableGroupAI",true,true];
    _leased=[_group,"QA",true,serverTime+120] call Waldo_fnc_CortexLambsLease;
    _released=[_group,"QA",false] call Waldo_fnc_CortexLambsLease;
    ["LAMBS-true-baseline-restored",_leased && {_released} && {_group getVariable ["lambs_danger_disableGroupAI",false]}] call _check;
    _group setVariable ["lambs_danger_disableGroupAI",false,true];

    // A lease is public durable intent. Move its live group to a real HC, renew/release on the new
    // owner, and return it to the server before the Zeus arm. This catches old-owner callbacks and
    // a release implementation which only works on the authority that first acquired the lease.
    private _hcOwners=((missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0}) select [0,1];
    ["LAMBS-loaded-headless-prerequisite",count _hcOwners == 1,str _hcOwners] call _check;
    if (count _hcOwners == 1) then {
        private _hcOwner=_hcOwners select 0;
        _leased=[_group,"QA",true,serverTime+120] call Waldo_fnc_CortexLambsLease;
        private _leaseBefore=_group getVariable ["Waldo_Cortex_LambsLease",[]];
        private _leaseBeforeExpiry=_leaseBefore param [2,-1];
        _group setVariable ["Waldo_Headless_ExcludeGroup",false,true];
        {_x setVariable ["acex_headless_blacklist",false,true]} forEach _units;
        private _migrationRequested=[_group,_hcOwner] call Waldo_fnc_HeadlessMigrateGroup;
        private _adopted=[{groupOwner _group == _hcOwner && {(_units findIf {owner _x != _hcOwner}) < 0}},30] call _wait;
        ["LAMBS-lease-survives-headless-adoption",_leased && {_migrationRequested} && {_adopted}
            && {(_group getVariable ["Waldo_Cortex_LambsLease",[]]) isEqualTo _leaseBefore}
            && {_group getVariable ["lambs_danger_disableGroupAI",false]},str [groupOwner _group,_group getVariable ["Waldo_Cortex_LambsLease",[]]]] call _check;

        [_group,"QA",true,serverTime+180] remoteExecCall ["Waldo_fnc_CortexLambsLease",_hcOwner];
        private _renewed=[{
            private _lease=_group getVariable ["Waldo_Cortex_LambsLease",[]];
            count _lease == 3 && {(_lease select 0) == "QA"} && {(_lease select 2) > _leaseBeforeExpiry}
        },15] call _wait;
        ["LAMBS-new-owner-renews-lease",_renewed,str (_group getVariable ["Waldo_Cortex_LambsLease",[]])] call _check;
        [_group,"QA",false] remoteExecCall ["Waldo_fnc_CortexLambsLease",_hcOwner];
        private _ownerReleased=[{(_group getVariable ["Waldo_Cortex_LambsLease",[]]) isEqualTo []
            && {!(_group getVariable ["lambs_danger_disableGroupAI",true])}},15] call _wait;
        ["LAMBS-new-owner-restores-baseline",_ownerReleased] call _check;

        private _returnRequested=[_group,2] call Waldo_fnc_HeadlessMigrateGroup;
        private _returned=[{groupOwner _group == 2 && {(_units findIf {owner _x != 2}) < 0}},30] call _wait;
        ["LAMBS-returned-to-server",_returnRequested && {_returned},str [groupOwner _group,_units apply {owner _x}]] call _check;
        _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        {_x setVariable ["acex_headless_blacklist",true,true]} forEach _units;
    };

    _leased=[_group,"QA",true,serverTime+120] call Waldo_fnc_CortexLambsLease;
    private _handoverStart=_units apply {getPosATL _x};
    private _cortexDestination=[2670,2470,0];
    [_group,_cortexDestination,5] call Waldo_fnc_CortexGroupMove;
    ["LAMBS: Zeus interrupts Cortex ownership","The squad must start the leased eastward move. Zeus then replaces it with a south-west ordinary waypoint; every soldier must follow and Cortex must not resurrect its old route.",_cortexDestination] call _phase;
    private _started=[{
        private _allStarted=true;
        {if (_x distance2D (_handoverStart select _forEachIndex) < 10) then {_allStarted=false}} forEach _units;
        _allStarted
    },35] call _wait;
    ["LAMBS-zeus-handover-stimulus",_leased && {_started}] call _check;
    [_group,true] call Waldo_fnc_CortexZeusMark;
    private _replacement=[2540,2425,0];
    private _wp=_group addWaypoint [_replacement,0];
    _wp setWaypointType "MOVE";
    _wp setWaypointCompletionRadius 4;
    _group setCurrentWaypoint _wp;
    {_x setVariable ["Waldo_CortexQA_Target",_replacement,true]; _x doFollow leader _group} forEach _units;
    private _replacementReached=[{(_units findIf {!alive _x || {_x distance2D _replacement > 12}}) < 0},90] call _wait;
    ["LAMBS-zeus-replacement-physical-arrival",_started && {_replacementReached},str (_units apply {getPosATL _x})] call _check;
    private _maxDrift=0;
    for "_sample" from 1 to 12 do {sleep 1; {_maxDrift=_maxDrift max (_x distance2D _replacement)} forEach _units};
    ["LAMBS-zeus-clean-release",_replacementReached && {_maxDrift <= 15}
        && {(_group getVariable ["Waldo_Cortex_LambsLease",[]]) isEqualTo []}
        && {!(_group getVariable ["lambs_danger_disableGroupAI",true])},str _maxDrift] call _check;
} else {
    ["LAMBS-absent-no-upstream-dependency",_accepted && {_arrived} && {_travelled}] call _check;
};

[_group] call Waldo_fnc_CortexReleaseGroup;
{deleteVehicle _x} forEach _units;
deleteGroup _group;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
