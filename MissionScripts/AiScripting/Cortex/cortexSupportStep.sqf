/*
 * Author: WaldoTheWarfighter
 * Maintains at most six reserved responders and examines at most eight candidates per request step.
 * Assigns each responder a distinct optional 45 m rally area, with at least 110 m between centres.
 * Six bounded candidate areas lie behind the requester. Occupied areas are excluded, then the
 * shared avenue selector chooses a dry, usable endpoint and rejects a cliff-like or unnecessarily
 * rough route from the responder; distance remains part of the selector score.
 * An acknowledged responder may transition directly into a coordinated approach without waiting
 * for physical rally arrival; the rally remains a fallback while no approach has been dispatched.
 * Every reservation and revalidation requires three combat-effective dismounts, preventing an
 * ordinary tank/APC crew or mounted passenger squad from receiving infantry bound roles.
 * Publishes only the request's at-most-six responder identities for owner-side tactical selection.
 * This separation is not terrain-aware approach routing. No shared-point fallback is used.
 * Locality/authority: server owns reservations; current group owners validate and execute orders.
 * Reinforcement and coordinated assault independently keep the shared discovery request alive, but
 * each reservation requires a mode shared by requester and responder. Mismatched settings therefore
 * cannot create an accepted lease with no executable rally or coordinated successor state.
 * When every candidate is exhausted without an accepted lease, publishes NO_RESPONDER once so the
 * requester owner can make its single bounded retry instead of remaining inert for the engagement.
 * Repeat/JIP: unique tokens, shared deadlines and owner acknowledgements retire stale assignments.
 * Arguments: 0: request job <HASHMAP>.
 * Return Value: Next delay in seconds, or -1 on cleanup.
 * Current callers: Server scheduler.
 * Example: [_job] call Waldo_fnc_CortexSupportStep;
 */
params ["_job"];
if (!isServer) exitWith {-1};
private _requester = _job get "requester";
private _leases = _job get "leases";
private _requests = missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap];
private _observedPhase = _requester getVariable ["Waldo_AIPass_PublicPhase","CALM"];
if (_observedPhase != "CALM") then {_job set ["sawContact",true]};
private _requesterReinforce = !isNull _requester && {[_requester,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
private _requesterCoordinated = !isNull _requester && {[_requester,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
private _requesterSupport = _requesterReinforce || {_requesterCoordinated};
private _valid = !isNull _requester && {alive leader _requester} && {serverTime < (_job get "expiry")}
    && {missionNamespace getVariable ["Waldo_AIPass_Enable",false]}
    && {[_requester,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
    && {_requesterSupport}
    && {[_requester] call Waldo_fnc_CortexIsEligible}
    && {!(_job getOrDefault ["sawContact",false]) || {_observedPhase != "CALM"}};
private _kept = [];
{
    _x params ["_helper","_token","_owner","_ackBy","_status"];
    private _lease = _helper getVariable ["Waldo_AIPass_SupportLease",[]];
    private _footFit = (units _helper) select {[_x] call Waldo_fnc_CortexCombatEffective && {vehicle _x == _x}};
    private _helperReinforce = !isNull _helper && {[_helper,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
    private _helperCoordinated = !isNull _helper && {[_helper,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
    private _sharedReinforce = _requesterReinforce && {_helperReinforce};
    private _sharedCoordinated = _requesterCoordinated && {_helperCoordinated};
    private _helperSupport = _sharedReinforce || {_sharedCoordinated};
    private _keep = _valid && {!isNull _helper} && {alive leader _helper} && {_status != "REJECTED"}
        && {count _footFit >= 3}
        && {[_helper] call Waldo_fnc_CortexIsEligible}
        && {[_helper,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
        && {_helperSupport}
        && {_lease isNotEqualTo [] && {(_lease select 0) == _token}};
    if (_keep && {groupOwner _helper != _owner}) then {
        _owner = groupOwner _helper; _ackBy = serverTime+15; _status = "PENDING";
        [_helper,_lease] remoteExecCall ["Waldo_fnc_CortexSupportLocal",_owner];
    };
    if (_keep && {_status == "PENDING"} && {serverTime >= _ackBy}) then {_keep = false};
    if (_keep) then {_kept pushBack [_helper,_token,_owner,_ackBy,_status]} else {
        if (_lease isNotEqualTo [] && {(_lease select 0) == _token}) then {_helper setVariable ["Waldo_AIPass_SupportLease",nil,true]; _helper setVariable ["Waldo_Cortex_SupportRole",nil,true]};
    };
} forEach _leases;
_job set ["leases",_kept];
if (!_valid) exitWith {
    _requester setVariable ["Waldo_Cortex_SupportResponders",nil,true];
    _requester setVariable ["Waldo_Cortex_SupportRequestState",nil,true];
    _requests deleteAt (_job get "key");
    -1
};
private _candidates = _job get "candidates";
private _cursor = _job get "cursor";
for "_i" from 1 to 8 do {
    if (_cursor >= count _candidates || {count _kept >= (_job get "maximum")}) exitWith {};
    private _helper = (_candidates select _cursor) select 2;
    _cursor = _cursor+1;
    private _helperReinforce = !isNull _helper && {[_helper,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
    private _helperCoordinated = !isNull _helper && {[_helper,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
    private _sharedReinforce = _requesterReinforce && {_helperReinforce};
    private _sharedCoordinated = _requesterCoordinated && {_helperCoordinated};
    private _helperSupport = _sharedReinforce || {_sharedCoordinated};
    if (!isNull _helper && {alive leader _helper} && {(_helper getVariable ["Waldo_AIPass_SupportLease",[]]) isEqualTo []}
        && {count ((units _helper) select {[_x] call Waldo_fnc_CortexCombatEffective && {vehicle _x == _x}}) >= 3}
        && {[_helper] call Waldo_fnc_CortexIsEligible} && {[_helper,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
        && {_helperSupport}) then {
        // The request rally is an area anchor, never a common squad destination.
        // Reserve the footprint in the lease so migration preserves the same area.
        private _rally = [];
        private _rallyCandidates=[];
        private _axis = _job get "rallyDirection";
        for "_slot" from 0 to 5 do {
            private _row = floor (_slot / 2);
            private _centre = (_job get "rally") getPos [110*_row,_axis+180];
            _centre = _centre getPos [55,_axis+([-90,90] select (_slot mod 2))];
            private _occupied = _kept findIf {
                private _other = (_x select 0) getVariable ["Waldo_AIPass_SupportLease",[]];
                count _other == 6 && {(_other select 3) distance2D _centre < 109}
            } >= 0;
            if (!_occupied && {!surfaceIsWater _centre} && {((surfaceNormal _centre) select 2) >= 0.55}) then {
                _rallyCandidates pushBack [_centre];
            };
        };
        if (_rallyCandidates isNotEqualTo []) then {
            private _selected=[getPosATL leader _helper,_rallyCandidates,
                _job getOrDefault ["enemy",getPosATL leader _requester]] call Waldo_fnc_CortexSelectAvenue;
            if (_selected isNotEqualTo []) then {_rally=+(_selected select 0)};
        };
        if (_rally isNotEqualTo []) then {
            private _token = format ["%1:%2",_job get "serial",_cursor];
            private _lease = [_token,_requester,_job get "expiry",_rally,_job get "at",[]];
            // A retired older operation must not abort this replacement reservation.
            _helper setVariable ["Waldo_Cortex_SupportAbort",nil,true];
            _helper setVariable ["Waldo_AIPass_SupportLease",_lease,true];
            _kept pushBack [_helper,_token,groupOwner _helper,serverTime+15,"PENDING"];
            [_helper,_lease] remoteExecCall ["Waldo_fnc_CortexSupportLocal",groupOwner _helper];
        };
    };
};
_job set ["cursor",_cursor];
_job set ["leases",_kept];
private _responders = _kept apply {[_x select 0,_x select 1]};
if (_responders isNotEqualTo (_requester getVariable ["Waldo_Cortex_SupportResponders",[]])) then {
    _requester setVariable ["Waldo_Cortex_SupportResponders",_responders,true];
};
if (_cursor >= count _candidates && {_kept isEqualTo []}) exitWith {
    _requester setVariable ["Waldo_Cortex_SupportResponders",nil,true];
    _requester setVariable ["Waldo_Cortex_SupportRequestState",[_job get "serial","NO_RESPONDER",serverTime],true];
    _requests deleteAt (_job get "key");
    -1
};
[_job,_kept] call Waldo_fnc_CortexSupportCoordinateStep;
2
