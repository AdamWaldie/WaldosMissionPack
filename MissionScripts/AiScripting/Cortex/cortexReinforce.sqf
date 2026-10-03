/*
 * Author: WaldoTheWarfighter
 * Sends idle nearby squads to support a squad in contact, and optionally calls in an airborne drop.
 *
 * Reinforcement has a responder cap and requires a
 * transmission path (Waldo_fnc_CortexCanTransmit; jamming blocks it, inventory radios are not required). A request is made on first
 * contact and again if the squad falls below 60% of its peak strength. When known armour appears
 * one more request is made that only squads with an anti-tank
 * gunner answer, with one extra responder slot. Candidates are considered by distance. Up to
 * Waldo_AIPass_Reinforce_MaxResponders eligible squads may answer across server and HC owners.
 * The server reserves slots before dispatch, and the current owner checks capability and accepts.
 * Posted orders, player groups and feature-owned crews are excluded. A shared 300-second expiry
 * bounds the assignment; owner migration revalidates it without creating another reservation.
 * Locality/authority: requester owner submits; server coordinates; responder owner executes.
 * A request is not treated as permanently consumed merely because it was dispatched. The server
 * publishes ACTIVE or NO_RESPONDER state; if the first dispatch is lost or exhausts every candidate,
 * the owner makes one delayed retry. This is event-driven and capped, so locality/network delay can
 * recover without creating a polling loop or support-request storm.
 * Repeat/JIP: requests and acknowledgements use tokens; old combat requests are not replayed to JIP.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 *
 * Return Value:
 * Number - 0; dispatch is asynchronous and acknowledged by responder owners
 *
 * Example:
 * [_group, _state] call Waldo_fnc_CortexReinforce;
 * Result: the platoon's other squads move up behind the squad that made contact.
 *
 * Current caller: Waldo_fnc_CortexGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]]];
private _alive = {alive _x} count units _group;
private _peak = (_group getVariable ["Waldo_AIPass_PeakSize", _alive]) max 1;
private _requests = _state getOrDefault ["reinforceRequested", 0];
private _requestState = _group getVariable ["Waldo_Cortex_SupportRequestState",[]];
private _requestActive = count _requestState == 3 && {(_requestState select 1) == "ACTIVE"}
    && {serverTime < (_requestState select 2)};
private _lastDispatch = _state getOrDefault ["reinforceDispatchedAt",-1e6];
// The first request may disappear before the server can publish state, or may exhaust every
// candidate. Permit one retry after 20 seconds; a live request remains authoritative for its lease.
private _retryable = _requests == 1 && {!_requestActive} && {time >= _lastDispatch+20};
private _armour = _state getOrDefault ["armourSeen", false];
private _armourCall = _armour && {!(_state getOrDefault ["armourRequested", false])};
if (!_armourCall && {_requests >= 2 || {_requests == 1 && {!_retryable} && {_alive / _peak >= 0.6}}}) exitWith {0};
private _leader = leader _group;
private _enemyPos = _state getOrDefault ["enemyPos", []];
if (count _enemyPos < 2 || {!([_leader] call Waldo_fnc_CortexCanTransmit)}) exitWith {0};
_state set ["reinforceRequested", _requests + 1];
_state set ["reinforceDispatchedAt",time];
if (_armourCall) then {_state set ["armourRequested", true]};

[_group,_enemyPos,_armourCall] remoteExecCall ["Waldo_fnc_CortexSupportServer",2];
0 // Dispatch is asynchronous; acceptance is recorded by SupportAck.
