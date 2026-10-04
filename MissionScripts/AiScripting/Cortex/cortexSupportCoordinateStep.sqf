/*
 * Author: WaldoTheWarfighter
 * Coordinates reserved assault squads through short bounds while other squads provide cover.
 * Locality/authority: server publishes tokened roles; each group owner executes its fire teams.
 * Repeat/JIP: roles are durable snapshots; only changed roles are broadcast. Existing support
 * lease expiry, exclusion and Zeus cancellation remain authoritative. At most six groups are read.
 * A partial bound is useful progress and hands movement to the next squad. Stalls are counted per
 * squad; one unreliable element can recover or retire without cancelling the other manoeuvre and
 * base-of-fire roles. Retirement publishes the exact reservation token for owner-side release; an
 * older abort cannot cancel a replacement task. A squad which can no longer form two viable fire
 * teams is retired immediately instead of keeping the whole action alive until lease expiry. The server watchdog follows the
 * configured owner-side bound timeout and retries after eight seconds. Bound length scales with
 * remaining distance to avoid slow fixed-step movement. Each new bound chooses once among the direct
 * line and two shallow alternatives through the shared terrain/fire-lane selector, so a valid overall
 * approach does not place the next bound in water, on a cliff-like slope or across supporting fire.
 * Up to two squads on separated approaches
 * may bound concurrently; each still alternates its own moving and covering fire teams. This removes
 * the former four-deep serial queue without turning the whole force into one unsupported rush.
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
    if (_accepted == "ACCEPTED" && {count _lease == 6} && {(_lease select 0) == _token}
        && {serverTime < (_lease select 2)} && {(_lease select 5) isNotEqualTo []}
        && {[_group,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
        _teams pushBack [_group,_token,_lease select 5];
    };
} forEach _leases;
if (_teams isEqualTo []) exitWith {};
private _completed=_job getOrDefault ["boundCompleted",[]];
private _retired=_job getOrDefault ["boundRetired",[]];
private _failuresByToken=_job getOrDefault ["boundFailuresByToken",createHashMap];
private _activeRaw=_job getOrDefault ["boundActive",[]];
// Accept the pre-concurrency single record during a live mission update, then publish the new list.
private _active=if (_activeRaw isEqualTo []) then {[]} else {
    if ((_activeRaw select 0) isEqualType grpNull) then {[_activeRaw]} else {+_activeRaw}
};
private _stillActive=[];
{
    _x params ["_group","_sequence","_deadline","_final","_token"];
    private _result=_group getVariable ["Waldo_Cortex_SupportBoundResult",[]];
    private _finished=count _result == 3 && {(_result select 0) == _token} && {(_result select 1) == _sequence};
    if (_teams findIf {(_x select 0) == _group} < 0 || {_finished} || {serverTime >= _deadline}) then {
        private _outcome=if (_finished) then {_result select 2} else {"TIMEOUT"};
        private _progressed=_outcome in ["COMPLETE","PARTIAL"];
        // A failed mover yields its turn; it cannot freeze or cancel the other squads.
        if (!_progressed) then {
            _group setVariable ["Waldo_Cortex_SupportRetryAfter",serverTime+8];
            private _failures=(_failuresByToken getOrDefault [_token,0])+1;
            _failuresByToken set [_token,_failures];
            _job set ["boundFailuresByToken",_failuresByToken];
            if (_failures >= 2) then {
                _retired pushBackUnique _token;
                _job set ["boundRetired",_retired];
                _group setVariable ["Waldo_Cortex_SupportAbort",
                    [_token,serverTime,"BOUND_FAILURES",_failures],true];
            };
        };
        if (_progressed && {_final}) then {_completed pushBackUnique _token; _job set ["boundCompleted",_completed]};
    } else {
        _stillActive pushBack _x;
    };
} forEach _active;
_active=_stillActive;
_job set ["boundActive",_active];
private _sequence=_job getOrDefault ["boundSequence",0];
// Casualties can make a formerly valid responder unable to field a moving and covering pair.
// Retire it here so it cannot be reconsidered every two seconds until the lease ends.
{
    _x params ["_group","_token"];
    private _fit=(units _group) select {[_x] call Waldo_fnc_CortexCombatEffective && {vehicle _x == _x}};
    if (count _fit < 4 && {!(_token in _completed)} && {!(_token in _retired)}) then {
        _retired pushBackUnique _token;
        _group setVariable ["Waldo_Cortex_SupportAbort",
            [_token,serverTime,"INSUFFICIENT_STRENGTH",count _fit],true];
    };
} forEach _teams;
_job set ["boundRetired",_retired];

private _cursor=_job getOrDefault ["boundCursor",0];
private _maxConcurrent=(count _teams) min 2;
for "_slot" from count _active to (_maxConcurrent-1) do {
    private _next=grpNull;
    private _point=[];
    private _nextIndex=-1;
    for "_offset" from 0 to ((count _teams)-1) do {
        private _index=(_cursor+_offset) mod count _teams;
        (_teams select _index) params ["_group","_token","_goal"];
        private _fit=(units _group) select {[_x] call Waldo_fnc_CortexCombatEffective && {vehicle _x == _x}};
        if (count _fit >= 4 && {serverTime >= (_group getVariable ["Waldo_Cortex_SupportRetryAfter",0])}
            && {!(_token in _completed)} && {!(_token in _retired)}
            && {_active findIf {(_x select 4) == _token} < 0}
            // Concurrent movers need genuinely different approach lanes. A second squad on the
            // same endpoint remains COVER until the first has yielded its turn.
            && {_active findIf {
                private _activeGroup=_x select 0;
                private _activeTeam=_teams findIf {(_x select 0) == _activeGroup};
                _activeTeam >= 0 && {((_teams select _activeTeam) select 2) distance2D _goal < 60}
            } < 0}) exitWith {
            private _centre=[0,0,0];
            {_centre=_centre vectorAdd getPosATL _x} forEach _fit;
            _centre=_centre vectorMultiply (1/count _fit);
            private _remaining=_centre distance2D _goal;
            private _boundLength=(_remaining*0.35) max 45 min 70;
            private _distance=_boundLength min _remaining;
            private _bearing=_centre getDir _goal;
            private _candidateRoutes=[];
            {
                _candidateRoutes pushBack [_centre getPos [_distance,_bearing+_x]];
            } forEach [0,-18,18];
            private _requester=_job getOrDefault ["requester",grpNull];
            private _supportOrigins=if (isNull _requester) then {[]} else {[getPosATL leader _requester]};
            private _selected=[_centre,_candidateRoutes,_job get "assaultEnemy",_supportOrigins]
                call Waldo_fnc_CortexSelectAvenue;
            if (_selected isNotEqualTo []) then {
                _point=+(_selected select ((count _selected)-1));
                _next=_group;
                _nextIndex=_index;
                _sequence=_sequence+1;
                _job set ["boundSequence",_sequence];
                private _boundTimeout=missionNamespace getVariable ["Waldo_AIPass_Flank_BoundTimeout",25];
                private _watchdog=(((_boundTimeout max 10)*4)+15) min 180;
                _active pushBack [_group,_sequence,serverTime+_watchdog,_point distance2D _goal < 2,_token,+_point];
            };
        };
    };
    if (!isNull _next) then {_cursor=(_nextIndex+1) mod count _teams};
};
_job set ["boundCursor",_cursor];
_job set ["boundActive",_active];
{
    _x params ["_group","_token","_goal"];
    private _old=_group getVariable ["Waldo_Cortex_SupportRole",[]];
    private _activeIndex=_active findIf {(_x select 0) == _group && {(_x select 4) == _token}};
    private _moving=_activeIndex >= 0;
    private _role=if (_moving) then {
        private _record=_active select _activeIndex;
        private _activePoint=_record param [5,[]];
        if (_activePoint isEqualTo [] && {count _old == 5}
            && {(_old select 0) == _token} && {(_old select 1) == (_record select 1)}) then {
            +_old
        } else {
            [_token,_record select 1,"MOVE",+_activePoint,+(_job get "assaultEnemy")]
        }
    } else {
        [_token,_sequence,"COVER",[],+(_job get "assaultEnemy")]
    };
    if (_old isNotEqualTo _role) then {
        _group setVariable ["Waldo_Cortex_SupportRole",_role,true];
    };
} forEach _teams;

if (_teams findIf {!((_x select 1) in _completed) && {!((_x select 1) in _retired)}} < 0) then {
    _job set ["expiry",(_job get "expiry") min (serverTime+10)]
};
