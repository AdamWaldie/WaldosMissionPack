/*
 * Author: WaldoTheWarfighter
 * Updates accepted reinforcement reservations with a finite coordinated assault destination.
 * Locality/authority: requester owner asks; server validates its existing leases; helper owners execute.
 * Each helper keeps the side of the support-to-enemy axis on which it rallied. A responder inside
 * the centre corridor receives a deterministic alternating side rather than permission to cross
 * the support line. Candidate approach points remain separated by 60 m, then
 * Waldo_fnc_CortexSelectAvenue rejects routes entering the requester's
 * 30 m firing corridor or changing sides. The shared bounded scorer distinguishes terrain/solid
 * ballistic screening from visual concealment. It runs once per dispatch, not per tick or soldier.
 * Accepted responders need not finish the optional rally first. Route selection starts at each
 * squad's live position when it has not rallied, so shared contact becomes a natural action instead
 * of scheduled assembly. Responders without a safe approach are released and resume autonomous
 * combat instead of keeping a ten-minute rally lease.
 * The requester receives ACTIVE with the extended lease after a successful dispatch, or
 * NO_SAFE_ROUTE when every bounded avenue is rejected. The latter permits one delayed rediscovery
 * attempt after positions change instead of consuming the whole engagement on a failed snapshot.
 * Repeat/JIP: one assault per request; the updated durable lease revalidates on HC migration.
 * Arguments: 0: requester <GROUP>, grpNull; 1: believed enemy ATL <ARRAY>, [].
 * 2: reply owner <NUMBER>, default -1; HC callers supply clientOwner.
 * Return Value: Nothing.
 * Current callers: CoordinatedAssault.
 * Example: [_group,_enemyPos,clientOwner] remoteExecCall ["Waldo_fnc_CortexSupportAssaultServer",2];
 */
params [["_requester",grpNull,[grpNull]],["_enemy",[],[[]]],["_replyOwner",-1,[0]]];
if (!isServer || {isNull _requester} || {([_replyOwner,groupOwner _requester] call Waldo_fnc_HeadlessResolveSender) < 0}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Enable",false])} || {[] call Waldo_fnc_CortexIsPaused}
    || {!([_requester] call Waldo_fnc_CortexIsEligible)}
    || {!([_requester,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
    || {count _enemy != 3} || {_enemy findIf {!(_x isEqualType 0)} >= 0} || {leader _requester distance2D _enemy > 400}) exitWith {};
private _requests = missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap];
private _job = _requests getOrDefault [netId _requester,createHashMap];
if (count _job == 0 || {_job getOrDefault ["assaultIssued",false]} || {serverTime >= (_job get "expiry")}) exitWith {};
private _sent = 0;
_job set ["assaultEnemy",+_enemy];
// Allow finite fire-team bounds rather than a single sprint before lease expiry.
_job set ["expiry",serverTime+600];
private _supportOrigin=getPosATL leader _requester;
private _laneX=(_enemy select 0)-(_supportOrigin select 0);
private _laneY=(_enemy select 1)-(_supportOrigin select 1);
private _laneLength=sqrt (_laneX*_laneX+_laneY*_laneY);
private _approaches=[];
private _dispatched=[];
{
    _x params ["_helper","_token","","","_accepted"];
    private _lease = _helper getVariable ["Waldo_AIPass_SupportLease",[]];
    private _status = _helper getVariable ["Waldo_AIPass_SupportStatus",[]];
    if (_accepted == "ACCEPTED" && {count _lease == 6} && {(_lease select 0) == _token}
        && {count _status == 4} && {(_status select 0) == _token} && {_status select 2}
        && {[leader _helper] call Waldo_fnc_CortexCanTransmit}
        && {count ((units _helper) select {[_x] call Waldo_fnc_CortexCombatEffective && {vehicle _x == _x}}) >= 3}
        && {[_helper] call Waldo_fnc_CortexIsEligible} && {[_helper,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
        // A coordinated route always begins at the squad's physical live position. The lease's
        // optional rally coordinate is reservation metadata and must never become a synthetic start.
        private _routeOrigin=getPosATL leader _helper;
        private _originX=(_routeOrigin select 0)-(_supportOrigin select 0);
        private _originY=(_routeOrigin select 1)-(_supportOrigin select 1);
        private _originSide=if (_laneLength > 0) then {(_laneX*_originY-_laneY*_originX)/_laneLength} else {0};
        // Near-axis origins previously accepted either flank. That made the shortest route cross
        // the base-of-fire lane in otherwise symmetric terrain. Preserve every meaningful side;
        // when geometry is effectively centred, distribute responders deterministically.
        private _desiredSide=if (abs _originSide >= 5) then {
            [1,-1] select (_originSide < 0)
        } else {
            [1,-1] select ((count _dispatched) mod 2 == 1)
        };
        private _candidateRoutes=[];
        {
            _x params ["_radius","_offset"];
            private _candidate=_enemy getPos [_radius,(_enemy getDir leader _requester)+_offset];
            private _candidateX=(_candidate select 0)-(_supportOrigin select 0);
            private _candidateY=(_candidate select 1)-(_supportOrigin select 1);
            private _candidateSide=if (_laneLength > 0) then {(_laneX*_candidateY-_laneY*_candidateX)/_laneLength} else {0};
            private _sameSide=_candidateSide*_desiredSide > 0;
            private _separated=_approaches findIf {_x distance2D _candidate < 60} < 0;
            if (_sameSide && {!surfaceIsWater _candidate} && {_separated}) then {
                _candidateRoutes pushBack [_candidate];
            };
        } forEach [[45,90],[85,90],[65,135],[45,-90],[85,-90],[65,-135]];
        private _selected=[_routeOrigin,_candidateRoutes,_enemy,[_supportOrigin]] call Waldo_fnc_CortexSelectAvenue;
        private _attack=if (_selected isEqualTo []) then {[]} else {+(_selected select ((count _selected)-1))};
        if (_attack isNotEqualTo []) then {
            _approaches pushBack +_attack;
            _lease = +_lease; _lease set [2,_job get "expiry"]; _lease set [5,_attack];
            _helper setVariable ["Waldo_AIPass_SupportLease",_lease,true];
            [_helper,_lease] remoteExecCall ["Waldo_fnc_CortexSupportLocal",groupOwner _helper];
            _dispatched pushBack _x;
            _sent = _sent+1;
        };
    };
} forEach (_job get "leases");

// Once at least one responder is moving, release every late or route-rejected reservation. Its
// owner observes the missing lease and restores normal autonomous behaviour on the next group tick.
if (_sent > 0) then {
    {
        _x params ["_helper","_token"];
        if (_dispatched findIf {(_x select 0) == _helper && {(_x select 1) == _token}} < 0) then {
            private _lease=_helper getVariable ["Waldo_AIPass_SupportLease",[]];
            if (count _lease == 6 && {(_lease select 0) == _token}) then {
                _helper setVariable ["Waldo_AIPass_SupportLease",nil,true];
                _helper setVariable ["Waldo_Cortex_SupportRole",nil,true];
            };
        };
    } forEach (_job get "leases");
    _job set ["leases",_dispatched];
    _requester setVariable ["Waldo_Cortex_SupportResponders",_dispatched apply {[_x select 0,_x select 1]},true];
    _requester setVariable ["Waldo_Cortex_SupportRequestState",[_job get "serial","ACTIVE",_job get "expiry"],true];
    _job set ["assaultIssued",true];
    [_job,_dispatched] call Waldo_fnc_CortexSupportCoordinateStep;
} else {
    // Route geometry is evaluated from live positions. If no accepted responder has a safe avenue,
    // do not leave those squads in an invisible rally/planning state until the five-minute request
    // expires. Retire the request now so every group can immediately resume its own contact drill.
    {
        _x params ["_helper","_token"];
        private _lease=_helper getVariable ["Waldo_AIPass_SupportLease",[]];
        if (count _lease == 6 && {(_lease select 0) == _token}) then {
            _helper setVariable ["Waldo_AIPass_SupportLease",nil,true];
            _helper setVariable ["Waldo_Cortex_SupportRole",nil,true];
        };
    } forEach (_job get "leases");
    _job set ["leases",[]];
    _job set ["expiry",serverTime];
    _requester setVariable ["Waldo_Cortex_SupportResponders",nil,true];
    _requester setVariable ["Waldo_Cortex_SupportRequestState",[_job get "serial","NO_SAFE_ROUTE",serverTime],true];
    _requests deleteAt (_job get "key");
};
