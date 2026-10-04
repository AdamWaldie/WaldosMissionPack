/*
 * Author: WaldoTheWarfighter
 * Creates a bounded cross-owner support-discovery request or upgrades its remaining capacity for armour.
 * Locality/authority: server owns reservations; current group owners validate and execute orders.
 * Publishes a bounded responder index on the requester so its owner never scans every group.
 * Only groups with at least three combat-effective dismounts can enter the infantry responder
 * pool. Vehicle crews and mounted passenger groups remain available to their vehicle controllers
 * and future combined-arms roles instead of being misrouted through infantry bounds.
 * Reinforcement and coordinated assault independently permit this shared discovery channel, but a
 * responder is useful only when it shares at least one enabled mode with the requester. Coordinated
 * assault retains two manoeuvre slots when ordinary reinforcement count is zero, so an unrelated
 * tuning value cannot silently disable the separately enabled coordinated feature.
 * The rally anchor is selected once from seven bounded points behind the requester. Water,
 * cliff-like endpoints and unnecessarily rough approaches are rejected before responders reserve
 * their individual rally areas; the engine remains responsible for local pathfinding.
 * Publishes a compact ACTIVE request state on the requester. SupportStep replaces it with
 * NO_RESPONDER when every bounded candidate is exhausted, allowing one owner-side delayed retry.
 * Repeat/JIP: unique tokens, shared deadlines and owner acknowledgements retire stale assignments.
 * Arguments: 0: requester <GROUP>, grpNull; 1: believed enemy ATL <ARRAY>, []; 2: AT required <BOOL>, false.
 * Return Value: Nothing.
 * Current callers: Reinforce.
 * Example: [_group, _enemyPos, false] remoteExecCall ["Waldo_fnc_CortexSupportServer", 2];
 */
params [["_requester",grpNull,[grpNull]],["_enemy",[],[[]]],["_at",false,[true]]];
private _requesterReinforce = !isNull _requester && {[_requester,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
private _requesterCoordinated = !isNull _requester && {[_requester,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
private _supportEnabled = _requesterReinforce || {_requesterCoordinated};
if (!isServer || {isNull _requester} || {remoteExecutedOwner > 0 && {remoteExecutedOwner != groupOwner _requester}}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Enable",false])} || {[] call Waldo_fnc_CortexIsPaused}
    || {!([_requester,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
    || {!_supportEnabled}
    || {!([_requester] call Waldo_fnc_CortexIsEligible)} || {!([leader _requester] call Waldo_fnc_CortexCanTransmit)}
    || {count _enemy != 3} || {_enemy findIf {!(_x isEqualType 0)} >= 0}) exitWith {};
private _requests = missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap];
private _key = netId _requester;
private _existing = _requests getOrDefault [_key,createHashMap];
if (count _existing > 0) exitWith {
    _requester setVariable ["Waldo_Cortex_SupportRequestState",[_existing get "serial","ACTIVE",_existing get "expiry"],true];
    if (_at && {!(_existing getOrDefault ["at",false])}) then {_existing set ["at",true]; _existing set ["maximum",((_existing get "maximum")+1) min 6]};
};
if (count _requests >= 32) exitWith {};
private _configuredMaximum = missionNamespace getVariable ["Waldo_AIPass_Reinforce_MaxResponders",2];
private _maximum = ([_configuredMaximum,_configuredMaximum max 2] select _requesterCoordinated) + ([0,1] select _at);
if (_maximum <= 0) exitWith {};
private _radius = missionNamespace getVariable ["Waldo_AIPass_Reinforce_Radius",600];
private _candidates = [];
{if (_x != _requester && {side _x == side _requester} && {alive leader _x}
    && {[leader _x] call Waldo_fnc_CortexCanTransmit}
    && {count ((units _x) select {[_x] call Waldo_fnc_CortexCombatEffective && {vehicle _x == _x}}) >= 3}
    && {leader _x distance2D leader _requester <= _radius}) then {
    _candidates pushBack [leader _x distance2D leader _requester,_forEachIndex,_x];
}} forEach allGroups;
_candidates sort true;
private _requesterPosition=getPosATL leader _requester;
private _rallyDirection=_requesterPosition getDir _enemy;
private _rallyCandidates=[];
{
    _x params ["_distance","_offset"];
    _rallyCandidates pushBack [_requesterPosition getPos [_distance,_rallyDirection+180+_offset]];
} forEach [[80,0],[80,-30],[80,30],[80,-60],[80,60],[60,0],[100,0]];
private _rallyRoute=[_requesterPosition,_rallyCandidates,_enemy] call Waldo_fnc_CortexSelectAvenue;
// The requester's occupied position is a safe last anchor. Individual responders still receive
// separated areas behind it, and SupportStep terrain-checks their actual destination routes.
private _rally=if (_rallyRoute isEqualTo []) then {+_requesterPosition} else {+(_rallyRoute select 0)};
private _serial = (missionNamespace getVariable ["Waldo_AIPass_SupportSerial",0])+1;
missionNamespace setVariable ["Waldo_AIPass_SupportSerial",_serial];
private _job = createHashMapFromArray [["requester",_requester],["key",_key],["serial",_serial],["at",_at],["maximum",_maximum min 6],
    ["rallyDirection",_rallyDirection],["enemy",+_enemy],
    ["expiry",serverTime+300],["rally",_rally],
    ["candidates",_candidates],["cursor",0],["leases",[]]];
// Publish only this request's bounded responder index. Requester owners consume it
// without scanning allGroups on every contact tick.
_requester setVariable ["Waldo_Cortex_SupportResponders",[],true];
_requester setVariable ["Waldo_Cortex_SupportRequestState",[_serial,"ACTIVE",_job get "expiry"],true];
_requests set [_key,_job];
missionNamespace setVariable ["Waldo_AIPass_SupportRequests",_requests];
[Waldo_fnc_CortexSupportStep,_job,1] call Waldo_fnc_CortexQueueJob;
