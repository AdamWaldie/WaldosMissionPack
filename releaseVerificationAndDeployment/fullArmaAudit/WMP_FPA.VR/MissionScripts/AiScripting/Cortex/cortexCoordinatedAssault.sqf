/*
 * Author: WaldoTheWarfighter
 * Combines a squad in contact with the squads that came to reinforce it into one prepared assault.
 *
 * The squad in contact becomes the base of fire
 * (its fire control keeps suppressing) and communicating reinforcing squads assault the enemy
 * position from safe separated sides of the line to the base of fire. The server can move two
 * responders concurrently when their approach
 * lanes remain separated; each mover retains alternating fire-team bounds and the gated final
 * assault sequence. Responders keep a fixed side of the supporting-fire axis. Original waypoints
 * survive the finite reservation. An accepted responder can enter the assault directly from its
 * current position; physical rally arrival is not a prerequisite and coordinated responders do not
 * receive an intermediate rally move. Nearby squads exploit a shared contact as soon as
 * communication succeeds instead of waiting for scheduled assembly.
 * It needs an enemy seen in the last 60 s within 400 m, STEADY
 * morale. Communication, available responders and safe avenues determine whether it can happen;
 * a behaviour profile never blocks an otherwise viable shared-contact action. Once responders have
 * acknowledged, the assault launches deterministically. Only one coordinated assault is made per
 * engagement. Responders must be
 * reserved by the server; receiving owners revalidate before execution, including after migration.
 * Locality and authority: call where the requesting group is local.
 *
 * Review contract: Responder selection rechecks eligibility immediately before issuing assault orders, including any Zeus hold received since reinforcement was requested.
 *
 * Reads the server-published bounded responder index rather than scanning all groups.
 * A prepared assault may dispatch from CONTACT or the immediately following SECURITY phase so a
 * short target occlusion cannot strand rallied responders. Once every acknowledged responder has
 * released its matching assault lease, the requester clears its coordinated ownership and resumes
 * the ordinary post-contact chain. Repeat/JIP: current feature gates and eligibility are rechecked;
 * owner jobs are retired on migration.
 * Dispatch is retried on a short cooldown until a responder acknowledges assault; sending
 * a request alone cannot consume the engagement if no responder was eligible.
 * Arguments:
 * 0: group <GROUP> - the squad in contact
 * 1: state <HASHMAP>
 *
 * Return Value:
 * Boolean - true while this group owns an acknowledged or pending coordinated base-of-fire role;
 * false when no coordinated movement was formed and a local tactic may be selected instead.
 *
 * Example:
 * [_group, _state] call Waldo_fnc_CortexCoordinatedAssault;
 * Result: two reinforcing squads sweep the enemy position from both flanks while the first squad fires.
 *
 * Current caller: Waldo_fnc_CortexGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]]];
private _publicResponders = _group getVariable ["Waldo_Cortex_SupportResponders",[]];
if (_state getOrDefault ["coordinated", false]) exitWith {
    private _active = _publicResponders findIf {
        _x params ["_helper","_token"];
        private _lease = _helper getVariable ["Waldo_AIPass_SupportLease",[]];
        private _status = _helper getVariable ["Waldo_AIPass_SupportStatus",[]];
        count _lease == 6 && {(_lease select 0) == _token} && {(_lease select 1) == _group}
            && {serverTime < (_lease select 2)} && {count _status == 4}
            && {(_status select 0) == _token} && {_status select 2} && {_status select 3}
    };
    if (_active >= 0) then {true} else {
        _state deleteAt "coordinated";
        _state deleteAt "coordinatedPendingUntil";
        false
    }
};
private _pendingUntil = _state getOrDefault ["coordinatedPendingUntil", 0];
if (time < _pendingUntil && {_publicResponders isNotEqualTo []}) exitWith {true};
if (_pendingUntil > 0 && {_publicResponders isEqualTo []}) then {
    // The server found no safe shared avenue and retired the reservation. Drop the asynchronous
    // ownership window on the next group tick so a local advance or flank can start immediately.
    _state deleteAt "coordinatedPendingUntil";
};
if ([_state, "coordinated"] call Waldo_fnc_CortexCooldown) exitWith {false};
if ((_state getOrDefault ["moraleState", "STEADY"]) != "STEADY") exitWith {false};
private _enemyPos = _state getOrDefault ["enemyPos", []];
private _leader = leader _group;
if (count _enemyPos < 2 || {time - (_state getOrDefault ["lastSeen", -1e6]) > 60} || {_leader distance2D _enemyPos > 400}) exitWith {false};
private _responders = [];
private _acknowledged = false;
{
    _x params ["_helper","_token"];
    private _lease = _helper getVariable ["Waldo_AIPass_SupportLease",[]];
    private _status = _helper getVariable ["Waldo_AIPass_SupportStatus",[]];
    if (count _lease == 6 && {(_lease select 0) == _token} && {(_lease select 1) == _group}
        && {count _status == 4} && {(_status select 0) == _token}
        && {_status select 2} && {[_helper] call Waldo_fnc_CortexIsEligible}) then {
        if (_status select 3) then {_acknowledged = true};
        _responders pushBack _helper;
    };
} forEach _publicResponders;
if (_acknowledged) exitWith {_state set ["coordinated",true]; _state deleteAt "coordinatedPendingUntil"; true};
if (_responders isEqualTo []) exitWith {false};
[_group,_enemyPos,clientOwner] remoteExecCall ["Waldo_fnc_CortexSupportAssaultServer",2];
[_state,"coordinated",10] call Waldo_fnc_CortexCooldown;
// Reserve the requester's movement role while the authenticated server dispatch and
// helper-owner acknowledgements cross the network. Without this finite ownership window,
// the same contact tick could start a local flank before the coordinated role arrived.
_state set ["coordinatedPendingUntil",time+15];
true // Owner acknowledgements complete the asynchronous dispatch.
