/*
 * Author: WaldoTheWarfighter
 * Updates accepted reinforcement reservations with a finite coordinated assault destination.
 * Locality/authority: requester owner asks; server validates its existing leases; helper owners execute.
 * Each helper keeps the side of the support-to-enemy axis on which it rallied. Candidate approach
 * points are rejected when the route enters the requester's firing corridor, and accepted approach
 * points remain separated. This avoids arbitrary left/right alternation sending one squad across
 * supporting fire. Repeat/JIP: one assault per request; the updated durable lease revalidates on HC migration.
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
private _job = (missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap]) getOrDefault [netId _requester,createHashMap];
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
private _crossesSupportLane={
    params ["_from","_to"];
    private _unsafe=false;
    private _routeLength=_from distance2D _to;
    private _samples=(ceil (_routeLength/10)) max 1;
    for "_sampleIndex" from 1 to _samples do {
        private _fraction=_sampleIndex/_samples;
        private _point=[
            (_from select 0)+((_to select 0)-(_from select 0))*_fraction,
            (_from select 1)+((_to select 1)-(_from select 1))*_fraction,
            0
        ];
        private _pointX=(_point select 0)-(_supportOrigin select 0);
        private _pointY=(_point select 1)-(_supportOrigin select 1);
        private _along=if (_laneLength > 0) then {(_pointX*_laneX+_pointY*_laneY)/_laneLength} else {0};
        private _lateral=if (_laneLength > 0) then {abs (_pointX*_laneY-_pointY*_laneX)/_laneLength} else {0};
        if (_along > 30 && {_along < _laneLength-25} && {_lateral < 22}) exitWith {_unsafe=true};
    };
    _unsafe
};
{
    _x params ["_helper","_token","","","_accepted"];
    private _lease = _helper getVariable ["Waldo_AIPass_SupportLease",[]];
    private _status = _helper getVariable ["Waldo_AIPass_SupportStatus",[]];
    if (_accepted == "ACCEPTED" && {count _lease == 6} && {(_lease select 0) == _token}
        && {count _status == 4} && {(_status select 0) == _token} && {(_status select 1) >= 0} && {_status select 2}
        && {[_helper] call Waldo_fnc_CortexIsEligible} && {[_helper,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
        private _rally=+(_lease select 3);
        private _attack=[];
        private _bestScore=1e9;
        {
            _x params ["_radius","_offset"];
            private _candidate=_enemy getPos [_radius,(_enemy getDir leader _requester)+_offset];
            private _separated=_approaches findIf {_x distance2D _candidate < 35} < 0;
            if (!surfaceIsWater _candidate && {_separated} && {!([_rally,_candidate] call _crossesSupportLane)}) then {
                private _score=_rally distance2D _candidate;
                if (_score < _bestScore) then {_attack=_candidate; _bestScore=_score};
            };
        } forEach [[45,90],[85,90],[65,135],[45,-90],[85,-90],[65,-135]];
        if (_attack isNotEqualTo []) then {
            _approaches pushBack +_attack;
            _lease = +_lease; _lease set [2,_job get "expiry"]; _lease set [5,_attack];
            _helper setVariable ["Waldo_AIPass_SupportLease",_lease,true];
            [_helper,_lease] remoteExecCall ["Waldo_fnc_CortexSupportLocal",groupOwner _helper];
            _sent = _sent+1;
        };
    };
} forEach (_job get "leases");

// A rejected/empty dispatch remains retryable; no movement was reserved.
if (_sent > 0) then {_job set ["assaultIssued",true]; [_job,_job get "leases"] call Waldo_fnc_CortexSupportCoordinateStep};
