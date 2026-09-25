/*
 * Author: WaldoTheWarfighter
 * Ends a defence order: soldiers rejoin formation and fight as a normal squad.
 *
 * Clears each soldier's spot and watch direction and the published order, so no machine re-applies
 * it. Called automatically when a defence breaks (losses or broken morale) or Zeus gives the group
 * waypoints, or by the AI Orders ZEN module and scripts.
 * Locality and authority: call where the group is local, or on the server, which forwards to the
 * owner.
 *
 * Arguments:
 * 0: group <GROUP or OBJECT>
 *
 * Return Value:
 * Boolean - true when released or forwarded
 *
 * Example:
 * [_group] call Waldo_fnc_AIPassDefendRelease;
 * Result: the defenders leave the line and move with their leader.
 *
 * Current callers: Waldo_fnc_AIPassGroupTick, the AI Orders ZEN module and mission scripts.
 */

params [["_group", grpNull, [grpNull, objNull]]];
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    if (isServer) then {[_group] remoteExecCall ["Waldo_fnc_AIPassDefendRelease", groupOwner _group]; true} else {false};
};
private _leader = leader _group;
{
    if (alive _x && {local _x}) then {
        _x doWatch objNull;
        _x doFollow _leader;
    };
    _x setVariable ["Waldo_AIPass_DefendPos", nil, true];
    _x setVariable ["Waldo_AIPass_DefendHolding", nil];
} forEach units _group;
_group setVariable ["Waldo_AIPass_Defend", nil, true];
_group setVariable ["Waldo_AIPass_DefendApplied", nil];
diag_log format ["[WMP AI PASS] %1 defence released", _group];
true
