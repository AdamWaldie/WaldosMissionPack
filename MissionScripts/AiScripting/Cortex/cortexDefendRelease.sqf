/*
 * Author: WaldoTheWarfighter
 * Ends a defence order: soldiers normally rejoin formation and fight as a normal squad. Replacement-
 * order release clears Cortex state and releases only a still-owned combat-labelled hold, so a
 * new group waypoint can move the soldier without overwriting a newer direct unit command.
 *
 * Clears each soldier's spot and watch direction and the published order, so no machine re-applies
 * it. Called automatically when a defence breaks (losses or broken morale) or Zeus gives the group
 * waypoints, or by the AI Orders ZEN module and scripts.
 * Locality and authority: call where the group is local, or on the server, which forwards to the
 * owner.
 *
 * Repeat/JIP: repeated release clears published assignments; new owners do not replay a released order.
 * Arguments:
 * 0: group <GROUP or OBJECT>
 * 1: restore formation <BOOL> - false when Zeus already supplied replacement movement (default true)
 *
 * Return Value:
 * Boolean - true when released or forwarded
 *
 * Example:
 * [_group] call Waldo_fnc_CortexDefendRelease;
 * Result: the defenders leave the line and move with their leader.
 *
 * Current callers: Waldo_fnc_CortexGroupTick, the AI Orders ZEN module and mission scripts.
 */

params [["_group", grpNull, [grpNull, objNull]],["_restore",true,[true]]];
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    if (isServer) then {[_group,_restore] remoteExecCall ["Waldo_fnc_CortexDefendRelease", groupOwner _group]; true} else {false};
};
// No Cortex assignment means there is nothing for this release to restore.
if ((_group getVariable ["Waldo_AIPass_Defend",[]]) isEqualTo [] && {units _group findIf {(_x getVariable ["Waldo_AIPass_DefendPos",[]]) isNotEqualTo []} < 0}) exitWith {false};
private _leader = leader _group;
{
    private _ownedHold = (_x getVariable ["Waldo_AIPass_DefendHolding",false])
        || {(_x getVariable ["Waldo_AIPass_DefendPos",[]]) isNotEqualTo []};
    if (alive _x && {local _x}) then {
        _x doWatch objNull;
        private _command = toUpperANSI currentCommand _x;
        if (_restore || {_ownedHold && {_command in ["","STOP","ATTACK","FIRE","SUPPRESS"]}}) then {
            _x doFollow _leader
        };
    };
    _x setVariable ["Waldo_AIPass_DefendPos", nil, true];
    _x setVariable ["Waldo_AIPass_DefendFailed",nil,true];
    _x setVariable ["Waldo_AIPass_DefendHolding", nil];
} forEach units _group;
_group setVariable ["Waldo_AIPass_Defend", nil, true];
_group setVariable ["Waldo_AIPass_DefendApplied", nil];
diag_log format ["[WMP CORTEX] %1 defence released", _group];
true
