/*
 * Author: WaldoTheWarfighter
 * Reports whether Zeus currently has priority over a group (see Waldo_fnc_AIPassZeusMark).
 *
 * A group is held while:
 * - its latest Zeus hold token is younger than its duration, timed on this machine's own clock from
 *   when this machine first saw the token; or
 * - Zeus changed its waypoints and it still has waypoints ahead that the pass did not add (a cycling
 *   Zeus patrol therefore stays Zeus's until the curator returns it with the AI Orders module).
 * When those Zeus waypoints are finished, the owning machine clears the flag once.
 * Waldo_fnc_AIPassIsEligible calls this, so a held group is skipped by every behaviour: it is not
 * managed, flanked, merged, sent to reinforce or used for artillery. Zeus can also exclude a group
 * permanently with AI Orders, which sets Waldo_AIPass_Exclude.
 * Locality and authority: read-mostly; callable anywhere. It writes only this machine's timing cache,
 * plus the one broadcast when the waypoint flag is cleared by the owner.
 *
 * Arguments:
 * 0: group <GROUP>
 *
 * Return Value:
 * Boolean - true while Zeus has priority
 *
 * Example:
 * if ([_group] call Waldo_fnc_AIPassZeusHeld) exitWith {};
 * Result: the pass does nothing with a group Zeus is commanding.
 *
 * Current callers: Waldo_fnc_AIPassIsEligible and Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]]];
if (isNull _group) exitWith {false};
private _token = _group getVariable ["Waldo_AIPass_ZeusHold", []];
if (_token isNotEqualTo [] && {(_group getVariable ["Waldo_AIPass_ZeusSeenToken", -1]) != (_token select 0)}) then {
    _group setVariable ["Waldo_AIPass_ZeusSeenToken", _token select 0];
    _group setVariable ["Waldo_AIPass_ZeusLocalUntil", time + (_token select 1)];
};
if (time < (_group getVariable ["Waldo_AIPass_ZeusLocalUntil", -1])) exitWith {true};
if !(_group getVariable ["Waldo_AIPass_ZeusWaypoints", false]) exitWith {false};
private _remaining = false;
for "_index" from (currentWaypoint _group) to ((count waypoints _group) - 1) do {
    if (!_remaining && {waypointDescription [_group, _index] != "WMP AI PASS"}) then {_remaining = true};
};
if (!_remaining && {local _group}) then {_group setVariable ["Waldo_AIPass_ZeusWaypoints", false, true]};
_remaining
