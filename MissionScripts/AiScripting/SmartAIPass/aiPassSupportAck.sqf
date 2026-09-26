/*
 * Author: WaldoTheWarfighter
 * Records only the current helper owner response for the current reservation token.
 * Locality/authority: server owns reservations; current group owners validate and execute orders.
 * Repeat/JIP: unique tokens, shared deadlines and owner acknowledgements retire stale assignments.
 * Arguments: 0: helper <GROUP>, grpNull; 1: token <STRING>, empty; 2: accepted <BOOL>, false; 3: exact lease snapshot <ARRAY>, [].
 * Return Value: Nothing.
 * Current callers: SupportApply.
 * Example: [_group, _token, true, _lease] remoteExecCall ["Waldo_fnc_AIPassSupportAck", 2];
 */
params [["_group",grpNull,[grpNull]],["_token","",[""]],["_accepted",false,[true]],["_snapshot",[],[[]]]];
if (!isServer || {isNull _group} || {remoteExecutedOwner != groupOwner _group}) exitWith {};
private _lease = _group getVariable ["Waldo_AIPass_SupportLease",[]];
if (_lease isEqualTo [] || {(_lease select 0) != _token} || {_lease isNotEqualTo _snapshot}) exitWith {};
private _requests = missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap];
private _job = _requests getOrDefault [netId (_lease select 1),createHashMap];
if (count _job == 0) exitWith {};
private _leases = _job get "leases";
private _index = _leases findIf {(_x select 0) == _group && {(_x select 1) == _token}};
if (_index >= 0) then {(_leases select _index) set [4,["REJECTED","ACCEPTED"] select _accepted]};
