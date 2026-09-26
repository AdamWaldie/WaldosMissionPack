/*
 * Author: WaldoTheWarfighter
 * Updates accepted reinforcement reservations with a finite coordinated assault destination.
 * Locality/authority: requester owner asks; server validates its existing leases; helper owners execute.
 * Repeat/JIP: one assault per request; the updated durable lease revalidates on HC migration.
 * Arguments: 0: requester <GROUP>, grpNull; 1: believed enemy ATL <ARRAY>, [].
 * Return Value: Nothing.
 * Current callers: CoordinatedAssault.
 * Example: [_group,_enemyPos] remoteExecCall ["Waldo_fnc_AIPassSupportAssaultServer",2];
 */
params [["_requester",grpNull,[grpNull]],["_enemy",[],[[]]]];
if (!isServer || {isNull _requester} || {remoteExecutedOwner != groupOwner _requester}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Enable",false])} || {[] call Waldo_fnc_AIPassIsPaused}
    || {!([_requester] call Waldo_fnc_AIPassIsEligible)}
    || {!([_requester,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_AIPassFeatureEnabled)}
    || {count _enemy != 3} || {_enemy findIf {!(_x isEqualType 0)} >= 0} || {leader _requester distance2D _enemy > 400}) exitWith {};
private _job = (missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap]) getOrDefault [netId _requester,createHashMap];
if (count _job == 0 || {_job getOrDefault ["assaultIssued",false]} || {serverTime >= (_job get "expiry")}) exitWith {};
_job set ["assaultIssued",true];
private _sent = 0;
{
    _x params ["_helper","_token","","","_accepted"];
    private _lease = _helper getVariable ["Waldo_AIPass_SupportLease",[]];
    private _status = _helper getVariable ["Waldo_AIPass_SupportStatus",[]];
    if (_accepted == "ACCEPTED" && {count _lease == 6} && {(_lease select 0) == _token}
        && {count _status == 4} && {(_status select 0) == _token} && {(_status select 1) >= 0} && {_status select 2}
        && {[_helper] call Waldo_fnc_AIPassIsEligible} && {[_helper,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_AIPassFeatureEnabled}) then {
        private _attack = _enemy getPos [25,(_enemy getDir leader _requester)+([90,-90] select (_sent mod 2 == 1))];
        if (!surfaceIsWater _attack) then {
            _lease = +_lease; _lease set [5,_attack];
            _helper setVariable ["Waldo_AIPass_SupportLease",_lease,true];
            [_helper,_lease] remoteExecCall ["Waldo_fnc_AIPassSupportLocal",groupOwner _helper];
            _sent = _sent+1;
        };
    };
} forEach (_job get "leases");
