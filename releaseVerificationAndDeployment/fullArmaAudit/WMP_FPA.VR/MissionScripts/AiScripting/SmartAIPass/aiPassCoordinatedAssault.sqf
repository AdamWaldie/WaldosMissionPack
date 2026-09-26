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
 * reserved by the server; receiving owners revalidate before execution, including after migration.
 * Locality and authority: call where the requesting group is local.
 *
 * Review contract: Responder selection rechecks eligibility immediately before issuing assault orders, including any Zeus hold received since reinforcement was requested.
 *
 * Repeat/JIP: current feature gates and eligibility are rechecked; owner jobs are retired on migration.
 * Arguments:
 * 0: group <GROUP> - the squad in contact
 * 1: state <HASHMAP>
 *
 * Return Value:
 * Number - 0; dispatch is asynchronous through the server reservation
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
    private _lease = _x getVariable ["Waldo_AIPass_SupportLease",[]];
    private _status = _x getVariable ["Waldo_AIPass_SupportStatus",[]];
    if (count _lease == 6 && {(_lease select 1) == _group} && {count _status == 4} && {(_status select 0) == (_lease select 0)}
        && {_status select 2} && {[_x] call Waldo_fnc_AIPassIsEligible}) then {
        _responders pushBack _x;
        if ((_status select 1) >= 0) then {_arrivals pushBack (_status select 1)};
    };
} forEach allGroups;
if (_arrivals isEqualTo []) exitWith {0};
private _first = 1e9;
{_first = _first min _x} forEach _arrivals;
if (count _arrivals < count _responders && {serverTime - _first < 60}) exitWith {0};
if (random 1 > ([_group, "coordinatedChance"] call Waldo_fnc_AIPassProfile)) exitWith {
    [_state, "coordinated", 120] call Waldo_fnc_AIPassCooldown;
    0
};
[_group,_enemyPos] remoteExecCall ["Waldo_fnc_AIPassSupportAssaultServer",2];
_state set ["coordinated",true];
0 // Owner acknowledgements complete the asynchronous dispatch.
