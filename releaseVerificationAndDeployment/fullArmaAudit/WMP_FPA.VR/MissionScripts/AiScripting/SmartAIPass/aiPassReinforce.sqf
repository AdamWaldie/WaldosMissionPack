/*
 * Author: WaldoTheWarfighter
 * Sends idle nearby squads to support a squad in contact, and optionally calls in an airborne drop.
 *
 * From Digii's reinforcement with its responder cap, plus Scorpion's rule that the call needs a
 * working radio (Waldo_fnc_AIPassCanTransmit, so jamming blocks it). A request is made on first
 * contact and again if the squad falls below 60% of its peak strength. When known armour appears
 * (Scorpion's capability-aware support), one more request is made that only squads with an anti-tank
 * gunner answer, with one extra responder slot, and squads with AT are preferred in every request. Up to
 * Waldo_AIPass_Reinforce_MaxResponders CALM, eligible, unordered squads of three or more on the same
 * side, owned by the same machine and within Waldo_AIPass_Reinforce_Radius move to a rally point 80 m
 * behind the squad in contact (away from the enemy) through an inserted waypoint, so their own
 * patrols resume afterwards. A responder stands down when the requester returns to CALM, is wiped
 * out, or 300 s pass; if it makes contact itself it fights normally.
 * If no responder is available and Waldo_AIPass_Airborne_Auto is on, an airborne reinforcement is
 * requested from the server (Waldo_fnc_AIPassAirborneRequest), which applies its own budget and
 * cooldown.
 * Locality and authority: call where the requesting group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 *
 * Return Value:
 * Number - responders dispatched
 *
 * Example:
 * [_group, _state] call Waldo_fnc_AIPassReinforce;
 * Result: the platoon's other squads move up behind the squad that made contact.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]]];
private _alive = {alive _x} count units _group;
private _peak = (_group getVariable ["Waldo_AIPass_PeakSize", _alive]) max 1;
private _requests = _state getOrDefault ["reinforceRequested", 0];
private _armour = _state getOrDefault ["armourSeen", false];
private _armourCall = _armour && {!(_state getOrDefault ["armourRequested", false])};
if (!_armourCall && {_requests >= 2 || {_requests == 1 && {_alive / _peak >= 0.6}}}) exitWith {0};
private _leader = leader _group;
private _enemyPos = _state getOrDefault ["enemyPos", []];
if (count _enemyPos < 2 || {!([_leader] call Waldo_fnc_AIPassCanTransmit)}) exitWith {0};
_state set ["reinforceRequested", _requests + 1];
if (_armourCall) then {_state set ["armourRequested", true]};

private _side = side _group;
private _radius = missionNamespace getVariable ["Waldo_AIPass_Reinforce_Radius", 600];
private _maximum = missionNamespace getVariable ["Waldo_AIPass_Reinforce_MaxResponders", 2];
private _already = {
    local _x && {((_x getVariable ["Waldo_AIPass_State", createHashMap]) getOrDefault ["respondingTo", grpNull]) == _group}
} count allGroups;
// Armour gets one extra responder slot so an anti-tank squad can still be sent.
if (_armourCall) then {_maximum = _maximum + 1};
if (_already >= _maximum) exitWith {0};
private _candidates = [];
{
    private _candidate = _x;
    private _candidateLeader = leader _candidate;
    if (_candidate != _group && {local _candidate} && {side _candidate == _side} && {alive _candidateLeader}
        && {_candidateLeader distance2D _leader <= _radius} && {({alive _x} count units _candidate) >= 3}
        && {(_candidate getVariable ["Waldo_AIPass_Garrison", []]) isEqualTo []}
        && {!(_candidate getVariable ["Waldo_AIPass_ClearBuilding", false])}
        && {!(_candidate getVariable ["Waldo_AIPass_RegroupQueued", false])}) then {
        private _candidateState = _candidate getVariable ["Waldo_AIPass_State", createHashMap];
        if ((_candidateState getOrDefault ["phase", "CALM"]) == "CALM" && {!(_candidateState getOrDefault ["responding", false])}
            && {behaviour _candidateLeader != "CARELESS"} && {[_candidate] call Waldo_fnc_AIPassIsEligible}) then {
            // Scorpion's capability-aware support: against armour, squads with an AT gunner go first.
            private _hasAT = (units _candidate) findIf {alive _x && {([_x] call Waldo_fnc_AIPassUnitRole) == "AT"}} >= 0;
            if (!_armourCall || {_hasAT}) then {
                _candidates pushBack [[1, 0] select (_armour && {_hasAT}), _candidateLeader distance2D _leader, _forEachIndex, _candidate];
            };
        };
    };
} forEach allGroups;
_candidates sort true;
private _rally = (getPosATL _leader) getPos [80, _enemyPos getDir _leader];
private _sent = 0;
{
    if (_already + _sent >= _maximum) exitWith {};
    private _responder = _x select 3;
    private _responderState = [_responder] call Waldo_fnc_AIPassGroupState;
    [_responder, _rally, 40] call Waldo_fnc_AIPassGroupMove;
    _responderState set ["responding", true];
    _responderState set ["respondingTo", _group];
    _responderState set ["respondUntil", time + 300];
    _sent = _sent + 1;
} forEach _candidates;
if (_sent > 0) then {
    missionNamespace setVariable ["Waldo_AIPass_ReinforcementsSent", (missionNamespace getVariable ["Waldo_AIPass_ReinforcementsSent", 0]) + _sent];
};
if (_sent == 0 && {_already == 0} && {missionNamespace getVariable ["Waldo_AIPass_Airborne_Enable", false]}
    && {missionNamespace getVariable ["Waldo_AIPass_Airborne_Auto", false]}) then {
    if (isServer) then {
        [_side, _enemyPos, createHashMapFromArray [["automatic", true]]] call Waldo_fnc_AIPassAirborneRequest;
    } else {
        [_side, _enemyPos, createHashMapFromArray [["automatic", true]]] remoteExecCall ["Waldo_fnc_AIPassAirborneRequest", 2];
    };
};
_sent
