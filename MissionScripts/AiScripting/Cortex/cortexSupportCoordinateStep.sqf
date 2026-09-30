/*
 * Author: WaldoTheWarfighter
 * Alternates reserved assault squads through short bounds; other squads provide cover.
 * Locality/authority: server publishes tokened roles; each group owner executes its fire teams.
 * Repeat/JIP: roles are durable snapshots; only changed roles are broadcast. Existing support
 * lease expiry, exclusion and Zeus cancellation remain authoritative. At most six groups are read.
 * A partial bound is useful progress and hands movement to the next squad. Stalls are counted per
 * squad; one unreliable element can recover or retire without cancelling the other manoeuvre and
 * base-of-fire roles. Bound length scales with remaining distance to avoid slow fixed-step movement.
 * Arguments: 0: request <HASHMAP>; 1: accepted leases <ARRAY>, required.
 * Return: Nothing. Current caller: CortexSupportStep.
 * Example: [_job,_kept] call Waldo_fnc_CortexSupportCoordinateStep;
 */
params ["_job","_leases"];
if (!isServer || {!(_job getOrDefault ["assaultIssued",false])}) exitWith {};
private _teams=[];
{
    _x params ["_group","_token","","","_accepted"];
    private _lease=_group getVariable ["Waldo_AIPass_SupportLease",[]];
    if (_accepted == "ACCEPTED" && {count _lease == 6} && {(_lease select 5) isNotEqualTo []}
        && {[_group,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
        _teams pushBack [_group,_token,_lease select 5];
    };
} forEach _leases;
if (_teams isEqualTo []) exitWith {};
private _completed=_job getOrDefault ["boundCompleted",[]];
private _retired=_job getOrDefault ["boundRetired",[]];
private _failuresByToken=_job getOrDefault ["boundFailuresByToken",createHashMap];
private _active=_job getOrDefault ["boundActive",[]];
if (_active isNotEqualTo []) then {
    _active params ["_group","_sequence","_deadline","_final","_token"];
    private _result=_group getVariable ["Waldo_Cortex_SupportBoundResult",[]];
    private _finished=count _result == 3 && {(_result select 0) == _token} && {(_result select 1) == _sequence};
    if (_teams findIf {(_x select 0) == _group} < 0 || {_finished} || {serverTime >= _deadline}) then {
        private _outcome=if (_finished) then {_result select 2} else {"TIMEOUT"};
        private _progressed=_outcome in ["COMPLETE","PARTIAL"];
        // A failed mover yields its turn; it cannot freeze or cancel the other squads.
        if (!_progressed) then {
            _group setVariable ["Waldo_Cortex_SupportRetryAfter",serverTime+15];
            private _failures=(_failuresByToken getOrDefault [_token,0])+1;
            _failuresByToken set [_token,_failures];
            _job set ["boundFailuresByToken",_failuresByToken];
            if (_failures >= 2) then {
                _retired pushBackUnique _token;
                _job set ["boundRetired",_retired];
                _group setVariable ["Waldo_Cortex_SupportAbort",
                    [serverTime,"BOUND_FAILURES",_failures],true];
            };
        };
        if (_progressed && {_final}) then {_completed pushBackUnique _token; _job set ["boundCompleted",_completed]};
        _job set ["boundActive",[]];
        _active=[];
    };
};
private _next=grpNull;
private _point=[];
private _sequence=_job getOrDefault ["boundSequence",0];
if (_active isEqualTo []) then {
    private _cursor=_job getOrDefault ["boundCursor",0];
    for "_offset" from 0 to ((count _teams)-1) do {
        private _index=(_cursor+_offset) mod count _teams;
        (_teams select _index) params ["_group","_token","_goal"];
        private _fit=(units _group) select {[_x] call Waldo_fnc_CortexCombatEffective && {vehicle _x == _x}};
        if (count _fit >= 4 && {serverTime >= (_group getVariable ["Waldo_Cortex_SupportRetryAfter",0])}
            && {!(_token in _completed)} && {!(_token in _retired)}) exitWith {
            private _centre=[0,0,0];
            {_centre=_centre vectorAdd getPosATL _x} forEach _fit;
            _centre=_centre vectorMultiply (1/count _fit);
            private _remaining=_centre distance2D _goal;
            private _boundLength=(_remaining*0.35) max 45 min 70;
            _point=_centre getPos [_boundLength min _remaining,_centre getDir _goal];
            if (!surfaceIsWater _point) then {
                _next=_group;
                _sequence=_sequence+1;
                _job set ["boundSequence",_sequence];
                _job set ["boundCursor",(_index+1) mod count _teams];
                _active=[_group,_sequence,serverTime+180,_point distance2D _goal < 2,_token];
                _job set ["boundActive",_active];
            };
        };
    };
};
{
    _x params ["_group","_token","_goal"];
    private _old=_group getVariable ["Waldo_Cortex_SupportRole",[]];
    private _moving=_active isNotEqualTo [] && {(_active select 0) == _group};
    private _role=if (_moving && {_next != _group} && {count _old == 5}) then {+_old} else {
        [_token,_sequence,["COVER","MOVE"] select _moving,if (_moving) then {+_point} else {[]},+(_job get "assaultEnemy")]
    };
    if (_old isNotEqualTo _role) then {
        _group setVariable ["Waldo_Cortex_SupportRole",_role,true];
    };
} forEach _teams;

if (_teams findIf {!((_x select 1) in _completed) && {!((_x select 1) in _retired)}} < 0) then {
    _job set ["expiry",(_job get "expiry") min (serverTime+10)]
};
