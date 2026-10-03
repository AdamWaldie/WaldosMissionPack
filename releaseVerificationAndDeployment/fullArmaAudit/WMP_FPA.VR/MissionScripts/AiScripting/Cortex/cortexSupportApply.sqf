/*
 * Author: WaldoTheWarfighter
 * Waits for the matching server reservation before issuing a support order on its current owner.
 * Locality/authority: queued only by authenticated SupportLocal; all execution gates are checked again.
 * Repeat/JIP: at most five seconds waiting for ordered state; stale tokens never issue movement.
 * A support update may replace its own lease, but never an active withdrawal, vehicle route,
 * artillery scoot or local tactical drill.
 * When coordinated assault is enabled, accepting a shared contact does not first issue a rally
 * waypoint: the squad keeps its current posture during the short acknowledgement exchange and the
 * server dispatches an avenue from its live position. Rally movement is retained for reinforcement
 * when coordinated assault is explicitly disabled. Assault hands a COORDINATED_ASSAULT lease to
 * server-assigned squad roles and owner-local successive fire-team bounds; it does not issue a
 * competing whole-squad waypoint. A nearby squad already in CONTACT or SECURITY may join the same
 * finite action when it has no other movement owner; requiring CALM here made mutually aware squads
 * fight beside one another without ever composing support-by-fire and manoeuvre roles.
 * During assault, each bound leases pursuit features only from its current moving fire team.
 * The covering fire team and other squads retain native target sharing and engagement.
 * Infantry support requires at least three combat-effective dismounts. Mounted passenger groups
 * and operating vehicle crews reject this lease instead of executing infantry movement in vehicles.
 * In LAMBS SPLIT mode, the finite support lease temporarily pauses LAMBS group manoeuvres for the
 * responder only. The base-of-fire group and every config-only LAMBS add-on remain active.
 * Reinforcement and coordinated assault independently authorize discovery, while acceptance requires
 * the requester and responder to share the mode which will consume the lease. A mismatched pair is
 * rejected instead of entering RESPONDING with no possible successor state.
 * Rally movement also uses 10 m completion; readiness requires physical squad arrival in GroupTick.
 * Ownership adoption reuses a matching public lease/status pair rather than inventing a second
 * support lifecycle. It reconstructs only semantic state and lets SupportMaintain consume the
 * current public role on the new owner.
 * Arguments: 0: job <HASHMAP> containing group, lease, waitUntil and optional adopt <BOOL>.
 * Return Value: Retry delay in seconds or -1 after acknowledgement.
 * Current callers: SupportLocal through the existing scheduler.
 * Example: [_job] call Waldo_fnc_CortexSupportApply;
 * Result: a valid reservation becomes one owner-local rally or coordinated-assault assignment.
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
private _state = [_group] call Waldo_fnc_CortexGroupState;
private _publicStatus=_group getVariable ["Waldo_AIPass_SupportStatus",[]];
private _adopting=_job getOrDefault ["adopt",false]
    && {count _publicStatus == 4}
    && {(_publicStatus select 0) == _token}
    && {_publicStatus select 2};
private _same = (_state getOrDefault ["supportToken",""]) == _token || {_adopting};
private _movementLease = _state getOrDefault ["movementLease",[]];
private _movementOwner = _movementLease param [0,""];
private _movementLeaseActive = count _movementLease == 2 && {time < (_movementLease select 1)};
private _supportOwnsMovement = _same && {_movementOwner in ["SUPPORT_RALLY","COORDINATED_ASSAULT"]};
private _fit = (units _group) select {[_x] call Waldo_fnc_CortexCombatEffective};
private _footFit = _fit select {vehicle _x == _x};
private _phase = _state getOrDefault ["phase","CALM"];
private _requesterReinforce = !isNull _requester && {[_requester,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
private _requesterCoordinated = !isNull _requester && {[_requester,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
private _responderReinforce = [_group,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_CortexFeatureEnabled;
private _responderCoordinated = [_group,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled;
private _sharedReinforce = _requesterReinforce && {_responderReinforce};
private _sharedCoordinated = _requesterCoordinated && {_responderCoordinated};
private _contactPeer = _phase in ["CONTACT","SECURITY"] && {_sharedCoordinated};
private _supportEnabled = _sharedReinforce || {_sharedCoordinated};
private _okay = missionNamespace getVariable ["Waldo_AIPass_Active",false] && {!([] call Waldo_fnc_CortexIsPaused)}
    && {serverTime < _expiry} && {!isNull _requester} && {side _requester == side _group}
    && {[leader _group] call Waldo_fnc_CortexCanTransmit}
    && {[_group] call Waldo_fnc_CortexIsEligible} && {[_group,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
    && {_supportEnabled}
    && {count _footFit >= 3} && {behaviour leader _group != "CARELESS"} && {!fleeing leader _group}
    && {_same || {getSuppression leader _group <= ([0.2,0.65] select _contactPeer)}}
    && {leader _group distance2D leader _requester <= (missionNamespace getVariable ["Waldo_AIPass_Reinforce_Radius",600])}
    && {(_group getVariable ["Waldo_AIPass_Garrison",[]]) isEqualTo []} && {(_group getVariable ["Waldo_AIPass_Defend",[]]) isEqualTo []}
    && {!(_group getVariable ["Waldo_AIPass_ClearBuilding",false])} && {!(_group getVariable ["Waldo_AIPass_RegroupQueued",false])}
    && {_same || {(_phase == "CALM" || {_contactPeer}) && {!(_state getOrDefault ["responding",false])}}}
    // A support order may update its own rally/assault, but it cannot erase an
    // infantry withdrawal, vehicle manoeuvre, artillery scoot or local tactical drill.
    && {!_movementLeaseActive || {_supportOwnsMovement}}
    && {_fit findIf {private _v = vehicle _x; _v isKindOf "Air" || {_v isKindOf "StaticWeapon"} || {getNumber (configOf _v >> "artilleryScanner") == 1}} < 0}
    && {!_needAT || {_footFit findIf {"AT" in ([_x] call Waldo_fnc_CortexCapabilities)} >= 0}};
private _attackAllowed = _attack isNotEqualTo [] && {_sharedCoordinated};
private _directCoordinationPending = _attack isEqualTo [] && {_sharedCoordinated};
if (_okay) then {
    _okay = [_group,"SUPPORT",true,_expiry] call Waldo_fnc_CortexLambsLease;
};
if (_okay && {_adopting || {!_same} || {_attackAllowed && {!(_state getOrDefault ["assaulting",false])}}}) then {
    if (_attackAllowed) then {
        [_group] call Waldo_fnc_CortexGroupMoveClear;
        _state set ["movementLease",["COORDINATED_ASSAULT",time+(_expiry-serverTime)]];
    } else {
        if (!_directCoordinationPending) then {
            [_group,_rally,10,"MOVE"] call Waldo_fnc_CortexGroupMove;
            _state set ["movementLease",["SUPPORT_RALLY",time+(_expiry-serverTime)]];
        };
    };
    _state set ["assaulting",_attackAllowed];
    _state set ["responding",true]; _state set ["respondingTo",_requester];
    _state set ["respondUntil",time+(_expiry-serverTime)]; _state set ["supportToken",_token];
    if (_adopting) then {
        private _arrivedServerTime=_publicStatus select 1;
        _state set ["arrivedAt",if (_arrivedServerTime < 0) then {-1} else {time-((serverTime-_arrivedServerTime) max 0)}];
        _state set ["supportBoundSequence",-1];
    };
};
[_group,_token,_okay,_lease,clientOwner] remoteExecCall ["Waldo_fnc_CortexSupportAck",2];
-1
