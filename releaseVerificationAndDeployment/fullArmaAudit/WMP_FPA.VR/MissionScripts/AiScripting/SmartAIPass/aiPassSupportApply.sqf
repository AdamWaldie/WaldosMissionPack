/*
 * Author: WaldoTheWarfighter
 * Waits for the matching server reservation before issuing a reinforcement order on its current owner.
 * Locality/authority: queued only by authenticated SupportLocal; all execution gates are checked again.
 * Repeat/JIP: at most five seconds waiting for ordered state; stale tokens never issue movement.
 * Arguments: 0: job <HASHMAP> containing group, lease and waitUntil.
 * Return Value: Retry delay in seconds or -1 after acknowledgement.
 * Current callers: SupportLocal through the existing scheduler.
 * Example: [_job] call Waldo_fnc_AIPassSupportApply;
 */
params ["_job"];
private _group = _job get "group";
private _lease = _job get "lease";
if (!local _group) exitWith {-1};
private _current = _group getVariable ["Waldo_AIPass_SupportLease",[]];
if (_current isNotEqualTo _lease) exitWith {
    if (serverTime < (_job get "waitUntil")) then {0.25} else {
        // A superseded delivery must not reject a newer order with the same reservation token.
        -1
    }
};
_lease params ["_token","_requester","_expiry","_rally","_needAT","_attack"];
private _state = [_group] call Waldo_fnc_AIPassGroupState;
private _same = (_state getOrDefault ["supportToken",""]) == _token;
private _fit = (units _group) select {[_x] call Waldo_fnc_AIPassCombatEffective};
private _okay = missionNamespace getVariable ["Waldo_AIPass_Active",false] && {!([] call Waldo_fnc_AIPassIsPaused)}
    && {serverTime < _expiry} && {!isNull _requester} && {side _requester == side _group}
    && {[_group] call Waldo_fnc_AIPassIsEligible} && {[_group,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_AIPassFeatureEnabled}
    && {[_group,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_AIPassFeatureEnabled}
    && {count _fit >= 3} && {behaviour leader _group != "CARELESS"} && {!fleeing leader _group}
    && {_same || {getSuppression leader _group <= 0.2}}
    && {leader _group distance2D leader _requester <= (missionNamespace getVariable ["Waldo_AIPass_Reinforce_Radius",600])}
    && {(_group getVariable ["Waldo_AIPass_Garrison",[]]) isEqualTo []} && {(_group getVariable ["Waldo_AIPass_Defend",[]]) isEqualTo []}
    && {!(_group getVariable ["Waldo_AIPass_ClearBuilding",false])} && {!(_group getVariable ["Waldo_AIPass_RegroupQueued",false])}
    && {_same || {(_state getOrDefault ["phase","CALM"]) == "CALM" && {!(_state getOrDefault ["responding",false])}}}
    && {_fit findIf {private _v = vehicle _x; _v isKindOf "Air" || {_v isKindOf "StaticWeapon"} || {getNumber (configOf _v >> "artilleryScanner") == 1}} < 0}
    && {!_needAT || {_fit findIf {"AT" in ([_x] call Waldo_fnc_AIPassCapabilities)} >= 0}};
private _attackAllowed = _attack isNotEqualTo [] && {[_group,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_AIPassFeatureEnabled};
if (_okay && {!_same || {_attackAllowed && {!(_state getOrDefault ["assaulting",false])}}}) then {
    [_group,[_rally,_attack] select _attackAllowed,[40,20] select _attackAllowed,["MOVE","SAD"] select _attackAllowed] call Waldo_fnc_AIPassGroupMove;
    _state set ["assaulting",_attackAllowed];
    _state set ["responding",true]; _state set ["respondingTo",_requester];
    _state set ["respondUntil",time+(_expiry-serverTime)]; _state set ["supportToken",_token];
};
[_group,_token,_okay,_lease] remoteExecCall ["Waldo_fnc_AIPassSupportAck",2];
-1
