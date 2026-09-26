/*
 * Author: WaldoTheWarfighter
 * Runs one step of survivor regroup for a remnant group: find a nearby friendly squad, walk to it,
 * then join it.
 *
 * EVALUATE: the remnant must still be local and eligible, have no more than
 * Waldo_AIPass_Regroup_MaxRemnantSize living members, all on foot, and have peaked at
 * Waldo_AIPass_Regroup_MinimumPeakSize or more. The host is the nearest eligible same-side infantry
 * group owned by the same machine within Waldo_AIPass_Regroup_SearchRadius. It must be larger than
 * a remnant and must stay within Waldo_AIPass_Regroup_MaxGroupSize after the merge. With no host,
 * the step retries every 20 seconds until Waldo_AIPass_Regroup_TimeoutSeconds, then leaves the
 * remnant on its own orders.
 * MOVE: survivors walk to the host leader. Each joins silently once within
 * Waldo_AIPass_Regroup_JoinDistance. A move order is re-issued only when the host leader has moved
 * more than 25 m. If survivors make no progress for Waldo_AIPass_Regroup_StuckSeconds, or the
 * timeout passes, they join where they stand and the engine formation brings them in. If the host
 * becomes invalid, the step returns to EVALUATE.
 * Hosts on other machines are never used, so a merge never moves a unit's locality.
 * Unconscious ACE casualties stay where they are.
 * Locality and authority: runs on the group owner's scheduler. doMove and joinSilent are issued for
 * local units only. Nothing is broadcast by WMP.
 *
 * Repeat/JIP: current feature gates and eligibility are rechecked; owner jobs are retired on migration.
 * Arguments:
 * 0: state <HASHMAP> - job state: group, phase and progress fields
 *
 * Return Value:
 * Number - seconds until the next step, or -1 when finished
 *
 * Example:
 * [_state] call Waldo_fnc_AIPassRegroupStep;
 * Result: the survivors move one stage closer to joining a nearby friendly squad.
 *
 * Current caller: Waldo_fnc_AIPassSchedulerTick through a job queued by Waldo_fnc_AIPassRegroupOnKill.
 */

params [["_state", createHashMap, [createHashMap]]];
private _group = _state getOrDefault ["group", grpNull];
private _finish = {
    if (!isNull _group) then {
        _group setVariable ["Waldo_AIPass_RegroupQueued", nil];
        _group setVariable ["Waldo_AIPass_RegroupHost", nil];
    };
    -1
};
if (isNull _group || {!local _group}) exitWith {call _finish};
if !([_group,"Waldo_AIPass_Regroup_Enable",true] call Waldo_fnc_AIPassFeatureEnabled) exitWith {call _finish};

private _movers = (units _group) select {
    alive _x && {local _x} && {!(_x getVariable ["ACE_isUnconscious", false])} && {lifeState _x != "INCAPACITATED"}
};
if (_movers isEqualTo []) exitWith {call _finish};
if ((units _group) findIf {alive _x && {
    _x getVariable ["ACE_isUnconscious", false] || {lifeState _x == "INCAPACITATED"}
    || {toUpperANSI (currentCommand _x) in ["HEAL", "REPAIR", "REFUEL", "REARM", "GET IN", "GET OUT", "ACTION", "SCRIPTED", "SUPPORT"]}
}} >= 0 || {_group getVariable ["Waldo_AIPass_ClearBuilding", false]}
    || {(_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []}
    || {(_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []}) exitWith {call _finish};

private _timeout = missionNamespace getVariable ["Waldo_AIPass_Regroup_TimeoutSeconds", 120];
private _joinDistance = missionNamespace getVariable ["Waldo_AIPass_Regroup_JoinDistance", 30];
private _phase = _state getOrDefault ["phase", "EVALUATE"];

if (_phase == "EVALUATE") exitWith {
    if (_state getOrDefault ["firstEvaluation", -1] < 0) then {_state set ["firstEvaluation", time]};
    private _alive = (units _group) select {alive _x};
    if (count _alive > (missionNamespace getVariable ["Waldo_AIPass_Regroup_MaxRemnantSize", 2])) exitWith {call _finish};
    if ((_group getVariable ["Waldo_AIPass_PeakSize", 0]) < (missionNamespace getVariable ["Waldo_AIPass_Regroup_MinimumPeakSize", 3])) exitWith {call _finish};
    if (_alive findIf {vehicle _x != _x} >= 0) exitWith {call _finish};
    if !([_group] call Waldo_fnc_AIPassIsEligible) exitWith {call _finish};

    private _origin = getPosATL (_movers select 0);
    private _side = side _group;
    private _radius = missionNamespace getVariable ["Waldo_AIPass_Regroup_SearchRadius", 400];
    private _maxSize = missionNamespace getVariable ["Waldo_AIPass_Regroup_MaxGroupSize", 12];
    private _minimumHost = (missionNamespace getVariable ["Waldo_AIPass_Regroup_MaxRemnantSize", 2]) + 1;
    private _host = grpNull;
    private _hostDistance = _radius;
    {
        private _candidate = _x;
        private _leader = leader _candidate;
        if (_candidate != _group && {side _candidate == _side} && {local _candidate}
            && {alive _leader} && {vehicle _leader == _leader}) then {
            private _hostAlive = {alive _x} count units _candidate;
            private _distance = _leader distance2D _origin;
            if (_distance < _hostDistance && {_hostAlive >= _minimumHost}
                && {_hostAlive + count _movers <= _maxSize}
                && {!(_candidate getVariable ["Waldo_AIPass_RegroupQueued", false])}
                && {[_candidate] call Waldo_fnc_AIPassIsEligible}) then {
                _host = _candidate;
                _hostDistance = _distance;
            };
        };
    } forEach allGroups;

    if (isNull _host) exitWith {
        if (time - (_state get "firstEvaluation") >= _timeout) then {call _finish} else {20}
    };
    private _target = getPosATL leader _host;
    {_x doMove _target} forEach _movers;
    _group setVariable ["Waldo_AIPass_RegroupHost", _host];
    _state set ["phase", "MOVE"];
    _state set ["host", _host];
    _state set ["target", _target];
    _state set ["moveStarted", time];
    _state set ["bestDistance", 100000];
    _state set ["lastProgress", time];
    3
};

// MOVE
// Zeus has priority over the merge: stop walking and follow the remnant's own leader again.
if !([_group] call Waldo_fnc_AIPassIsEligible) exitWith {
    {_x doFollow (leader _group)} forEach _movers;
    call _finish
};
private _host = _state getOrDefault ["host", grpNull];
private _hostLeader = leader _host;
if (isNull _host || {!local _host} || {!alive _hostLeader} || {!([_host] call Waldo_fnc_AIPassIsEligible)}) exitWith {
    _state set ["phase", "EVALUATE"];
    _group setVariable ["Waldo_AIPass_RegroupHost", nil];
    0
};

private _capacity = ((missionNamespace getVariable ["Waldo_AIPass_Regroup_MaxGroupSize", 12]) - ({alive _x} count units _host)) max 0;
if (_capacity == 0) exitWith {
    _state set ["phase", "EVALUATE"];
    _group setVariable ["Waldo_AIPass_RegroupHost", nil];
    3
};
private _joined = _movers select {_x distance2D _hostLeader <= _joinDistance};
if (count _joined > _capacity) then {_joined resize _capacity};
if (_joined isNotEqualTo []) then {
    _joined joinSilent _host;
    missionNamespace setVariable ["Waldo_AIPass_RegroupJoined", (missionNamespace getVariable ["Waldo_AIPass_RegroupJoined", 0]) + count _joined];
};
private _remaining = _movers - _joined;
if (_remaining isEqualTo []) exitWith {
    _group deleteGroupWhenEmpty true;
    missionNamespace setVariable ["Waldo_AIPass_RegroupsCompleted", (missionNamespace getVariable ["Waldo_AIPass_RegroupsCompleted", 0]) + 1];
    call _finish
};

private _farthest = 0;
{_farthest = _farthest max (_x distance2D _hostLeader)} forEach _remaining;
if (_farthest < (_state get "bestDistance") - 5) then {
    _state set ["bestDistance", _farthest];
    _state set ["lastProgress", time];
};
if (time - (_state get "lastProgress") >= (missionNamespace getVariable ["Waldo_AIPass_Regroup_StuckSeconds", 20])
    || {time - (_state get "moveStarted") >= _timeout}) exitWith {
    private _available = ((missionNamespace getVariable ["Waldo_AIPass_Regroup_MaxGroupSize", 12]) - ({alive _x} count units _host)) max 0;
    private _joinNow = _remaining select [0, _available];
    _joinNow joinSilent _host;
    missionNamespace setVariable ["Waldo_AIPass_RegroupJoined", (missionNamespace getVariable ["Waldo_AIPass_RegroupJoined", 0]) + count _joinNow];
    if (count _joinNow < count _remaining) exitWith {_state set ["phase", "EVALUATE"]; 3};
    missionNamespace setVariable ["Waldo_AIPass_RegroupsCompleted", (missionNamespace getVariable ["Waldo_AIPass_RegroupsCompleted", 0]) + 1];
    _group deleteGroupWhenEmpty true;
    call _finish
};

private _target = getPosATL _hostLeader;
if (_target distance2D (_state get "target") > 25) then {
    {_x doMove _target} forEach _remaining;
    _state set ["target", _target];
};
3
