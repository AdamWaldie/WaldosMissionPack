/*
 * Author: WaldoTheWarfighter
 * Combines a squad in contact with the squads that came to reinforce it into one prepared assault.
 *
 * The squad in contact becomes the base of fire
 * (its fire control keeps suppressing) and the reinforcing squads that have reached their rally
 * point assault the enemy position together from alternate sides (90 degrees left and right of the
 * line to the base of fire). Each assault is a SEEK AND DESTROY waypoint inserted ahead of the
 * squad's own waypoints, so they resume afterwards. The assault launches when every responder has
 * arrived, or 60 s after the first did. It needs an enemy seen in the last 60 s within 400 m, STEADY
 * morale, and a successful roll against the requesting squad's behaviour profile coordinatedChance
 * (a failed roll waits 120 s). Only one coordinated assault is made per engagement. Responders must be
 * owned by the same machine, like reinforcement itself.
 * Locality and authority: call where the requesting group is local.
 *
 * Review contract: Responder selection rechecks eligibility immediately before issuing assault orders, including any Zeus hold received since reinforcement was requested.
 *
 * Arguments:
 * 0: group <GROUP> - the squad in contact
 * 1: state <HASHMAP>
 *
 * Return Value:
 * Number - squads sent into the assault
 *
 * Example:
 * [_group, _state] call Waldo_fnc_AIPassCoordinatedAssault;
 * Result: two reinforcing squads sweep the enemy position from both flanks while the first squad fires.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]]];
if (_state getOrDefault ["coordinated", false] || {[_state, "coordinated"] call Waldo_fnc_AIPassCooldown}) exitWith {0};
if ((_state getOrDefault ["moraleState", "STEADY"]) != "STEADY") exitWith {0};
private _enemyPos = _state getOrDefault ["enemyPos", []];
private _leader = leader _group;
if (count _enemyPos < 2 || {time - (_state getOrDefault ["lastSeen", -1e6]) > 60} || {_leader distance2D _enemyPos > 400}) exitWith {0};
private _responders = [];
private _arrivals = [];
{
    private _responderState = _x getVariable ["Waldo_AIPass_State", createHashMap];
    if (local _x && {[_x] call Waldo_fnc_AIPassIsEligible} && {(_responderState getOrDefault ["respondingTo", grpNull]) == _group} && {_responderState getOrDefault ["responding", false]}) then {
        _responders pushBack _x;
        private _arrived = _responderState getOrDefault ["arrivedAt", -1];
        if (_arrived >= 0) then {_arrivals pushBack _arrived};
    };
} forEach allGroups;
if (_arrivals isEqualTo []) exitWith {0};
private _first = 1e9;
{_first = _first min _x} forEach _arrivals;
if (count _arrivals < count _responders && {time - _first < 60}) exitWith {0};
if (random 1 > ([_group, "coordinatedChance"] call Waldo_fnc_AIPassProfile)) exitWith {
    [_state, "coordinated", 120] call Waldo_fnc_AIPassCooldown;
    0
};
private _toBase = _enemyPos getDir _leader;
private _sent = 0;
{
    private _responderState = _x getVariable ["Waldo_AIPass_State", createHashMap];
    if ((_responderState getOrDefault ["arrivedAt", -1]) >= 0) then {
        private _attack = _enemyPos getPos [25, _toBase + ([90, -90] select (_sent mod 2 == 1))];
        [_x, _attack, 20, "SAD"] call Waldo_fnc_AIPassGroupMove;
        _responderState set ["assaulting", true];
        _sent = _sent + 1;
    };
} forEach _responders;
_state set ["coordinated", true];
missionNamespace setVariable ["Waldo_AIPass_CoordinatedAssaults", (missionNamespace getVariable ["Waldo_AIPass_CoordinatedAssaults", 0]) + 1];
diag_log format ["[WMP AI PASS] %1 coordinated assault with %2 squads on %3", _group, _sent, _enemyPos];
_sent
