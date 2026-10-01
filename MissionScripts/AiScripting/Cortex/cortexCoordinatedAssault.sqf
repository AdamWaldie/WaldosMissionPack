/*
 * Author: WaldoTheWarfighter
 * Combines a squad in contact with the squads that came to reinforce it into one prepared assault.
 *
 * The squad in contact becomes the base of fire
 * (its fire control keeps suppressing) and the reinforcing squads that have reached their rally
 * point assault the enemy position together from alternate sides (90 degrees left and right of the
 * line to the base of fire). The server alternates moving and covering squads; each mover
 * uses successive fire-team bounds and the gated final assault sequence. Original waypoints
 * survive the finite reservation. The assault launches when every responder has
 * arrived, or 60 s after the first did. It needs an enemy seen in the last 60 s within 400 m, STEADY
 * morale, and a positive requesting-squad coordinatedChance profile weight. Once responders have
 * assembled, the assault launches deterministically rather than discarding the prepared action on a
 * second random roll. Only one coordinated assault is made per engagement. Responders must be
 * reserved by the server; receiving owners revalidate before execution, including after migration.
 * Locality and authority: call where the requesting group is local.
 *
 * Review contract: Responder selection rechecks eligibility immediately before issuing assault orders, including any Zeus hold received since reinforcement was requested.
 *
 * Reads the server-published bounded responder index rather than scanning all groups.
 * Repeat/JIP: current feature gates and eligibility are rechecked; owner jobs are retired on migration.
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
if (_state getOrDefault ["coordinated", false]) exitWith {true};
private _pendingUntil = _state getOrDefault ["coordinatedPendingUntil", 0];
if (time < _pendingUntil) exitWith {true};
if ([_state, "coordinated"] call Waldo_fnc_CortexCooldown) exitWith {false};
if ((_state getOrDefault ["moraleState", "STEADY"]) != "STEADY") exitWith {false};
if (([_group, "coordinatedChance"] call Waldo_fnc_CortexProfile) <= 0) exitWith {false};
private _enemyPos = _state getOrDefault ["enemyPos", []];
private _leader = leader _group;
if (count _enemyPos < 2 || {time - (_state getOrDefault ["lastSeen", -1e6]) > 60} || {_leader distance2D _enemyPos > 400}) exitWith {false};
private _responders = [];
private _arrivals = [];
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
        if ((_status select 1) >= 0) then {_arrivals pushBack (_status select 1)};
    };
} forEach (_group getVariable ["Waldo_Cortex_SupportResponders",[]]);
if (_acknowledged) exitWith {_state set ["coordinated",true]; _state deleteAt "coordinatedPendingUntil"; true};
if (_arrivals isEqualTo []) exitWith {false};
private _first = 1e9;
{_first = _first min _x} forEach _arrivals;
if (count _arrivals < count _responders && {serverTime - _first < 60}) exitWith {false};
[_group,_enemyPos,clientOwner] remoteExecCall ["Waldo_fnc_CortexSupportAssaultServer",2];
[_state,"coordinated",10] call Waldo_fnc_CortexCooldown;
// Reserve the requester's movement role while the authenticated server dispatch and
// helper-owner acknowledgements cross the network. Without this finite ownership window,
// the same contact tick could start a local flank before the coordinated role arrived.
_state set ["coordinatedPendingUntil",time+15];
true // Owner acknowledgements complete the asynchronous dispatch.
