/*
 * Author: WaldoTheWarfighter
 * Creates a bounded cross-owner reinforcement request or upgrades its remaining capacity for armour.
 * Locality/authority: server owns reservations; current group owners validate and execute orders.
 * Repeat/JIP: unique tokens, shared deadlines and owner acknowledgements retire stale assignments.
 * Arguments: 0: requester <GROUP>, grpNull; 1: believed enemy ATL <ARRAY>, []; 2: AT required <BOOL>, false.
 * Return Value: Nothing.
 * Current callers: Reinforce.
 * Example: [_group, _enemyPos, false] remoteExecCall ["Waldo_fnc_AIPassSupportServer", 2];
 */
params [["_requester",grpNull,[grpNull]],["_enemy",[],[[]]],["_at",false,[true]]];
if (!isServer || {isNull _requester} || {remoteExecutedOwner > 0 && {remoteExecutedOwner != groupOwner _requester}}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Enable",false])} || {[] call Waldo_fnc_AIPassIsPaused}
    || {!([_requester,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_AIPassFeatureEnabled)}
    || {!([_requester,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_AIPassFeatureEnabled)}
    || {!([_requester] call Waldo_fnc_AIPassIsEligible)} || {!([leader _requester] call Waldo_fnc_AIPassCanTransmit)}
    || {count _enemy != 3} || {_enemy findIf {!(_x isEqualType 0)} >= 0}) exitWith {};
private _requests = missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap];
private _key = netId _requester;
private _existing = _requests getOrDefault [_key,createHashMap];
if (count _existing > 0) exitWith {
    if (_at && {!(_existing getOrDefault ["at",false])}) then {_existing set ["at",true]; _existing set ["maximum",((_existing get "maximum")+1) min 6]};
};
if (count _requests >= 32) exitWith {};
private _maximum = (missionNamespace getVariable ["Waldo_AIPass_Reinforce_MaxResponders",2]) + ([0,1] select _at);
if (_maximum <= 0) exitWith {};
private _radius = missionNamespace getVariable ["Waldo_AIPass_Reinforce_Radius",600];
private _candidates = [];
{if (_x != _requester && {side _x == side _requester} && {alive leader _x} && {leader _x distance2D leader _requester <= _radius}) then {
    _candidates pushBack [leader _x distance2D leader _requester,_forEachIndex,_x];
}} forEach allGroups;
_candidates sort true;
private _serial = (missionNamespace getVariable ["Waldo_AIPass_SupportSerial",0])+1;
missionNamespace setVariable ["Waldo_AIPass_SupportSerial",_serial];
private _job = createHashMapFromArray [["requester",_requester],["key",_key],["serial",_serial],["at",_at],["maximum",_maximum min 6],
    ["expiry",serverTime+300],["rally",(getPosATL leader _requester) getPos [80,_enemy getDir leader _requester]],
    ["candidates",_candidates],["cursor",0],["leases",[]]];
_requests set [_key,_job];
missionNamespace setVariable ["Waldo_AIPass_SupportRequests",_requests];
[Waldo_fnc_AIPassSupportStep,_job,1] call Waldo_fnc_AIPassQueueJob;
