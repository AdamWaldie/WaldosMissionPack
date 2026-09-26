/*
 * Author: WaldoTheWarfighter
 * Maintains at most six reserved responders and examines at most eight candidates per request step.
 * Locality/authority: server owns reservations; current group owners validate and execute orders.
 * Repeat/JIP: unique tokens, shared deadlines and owner acknowledgements retire stale assignments.
 * Arguments: 0: request job <HASHMAP>.
 * Return Value: Next delay in seconds, or -1 on cleanup.
 * Current callers: Server scheduler.
 * Example: [_job] call Waldo_fnc_AIPassSupportStep;
 */
params ["_job"];
if (!isServer) exitWith {-1};
private _requester = _job get "requester";
private _leases = _job get "leases";
private _requests = missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap];
private _observedPhase = _requester getVariable ["Waldo_AIPass_PublicPhase","CALM"];
if (_observedPhase != "CALM") then {_job set ["sawContact",true]};
private _valid = !isNull _requester && {alive leader _requester} && {serverTime < (_job get "expiry")}
    && {missionNamespace getVariable ["Waldo_AIPass_Enable",false]}
    && {[_requester,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_AIPassFeatureEnabled}
    && {[_requester,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_AIPassFeatureEnabled}
    && {[_requester] call Waldo_fnc_AIPassIsEligible}
    && {!(_job getOrDefault ["sawContact",false]) || {_observedPhase != "CALM"}};
private _kept = [];
{
    _x params ["_helper","_token","_owner","_ackBy","_status"];
    private _lease = _helper getVariable ["Waldo_AIPass_SupportLease",[]];
    private _keep = _valid && {!isNull _helper} && {alive leader _helper} && {_status != "REJECTED"}
        && {[_helper] call Waldo_fnc_AIPassIsEligible}
        && {[_helper,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_AIPassFeatureEnabled}
        && {[_helper,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_AIPassFeatureEnabled}
        && {_lease isNotEqualTo [] && {(_lease select 0) == _token}};
    if (_keep && {groupOwner _helper != _owner}) then {
        _owner = groupOwner _helper; _ackBy = serverTime+15; _status = "PENDING";
        [_helper,_lease] remoteExecCall ["Waldo_fnc_AIPassSupportLocal",_owner];
    };
    if (_keep && {_status == "PENDING"} && {serverTime >= _ackBy}) then {_keep = false};
    if (_keep) then {_kept pushBack [_helper,_token,_owner,_ackBy,_status]} else {
        if (_lease isNotEqualTo [] && {(_lease select 0) == _token}) then {_helper setVariable ["Waldo_AIPass_SupportLease",nil,true]};
    };
} forEach _leases;
_job set ["leases",_kept];
if (!_valid) exitWith {_requests deleteAt (_job get "key"); -1};
private _candidates = _job get "candidates";
private _cursor = _job get "cursor";
for "_i" from 1 to 8 do {
    if (_cursor >= count _candidates || {count _kept >= (_job get "maximum")}) exitWith {};
    private _helper = (_candidates select _cursor) select 2;
    _cursor = _cursor+1;
    if (!isNull _helper && {alive leader _helper} && {(_helper getVariable ["Waldo_AIPass_SupportLease",[]]) isEqualTo []}
        && {[_helper] call Waldo_fnc_AIPassIsEligible} && {[_helper,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_AIPassFeatureEnabled}
        && {[_helper,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_AIPassFeatureEnabled}) then {
        private _token = format ["%1:%2",_job get "serial",_cursor];
        private _lease = [_token,_requester,_job get "expiry",+(_job get "rally"),_job get "at",[]];
        _helper setVariable ["Waldo_AIPass_SupportLease",_lease,true];
        _kept pushBack [_helper,_token,groupOwner _helper,serverTime+15,"PENDING"];
        [_helper,_lease] remoteExecCall ["Waldo_fnc_AIPassSupportLocal",groupOwner _helper];
    };
};
_job set ["cursor",_cursor];
_job set ["leases",_kept];
if (_cursor >= count _candidates && {_kept isEqualTo []}) exitWith {_requests deleteAt (_job get "key"); -1};
2
