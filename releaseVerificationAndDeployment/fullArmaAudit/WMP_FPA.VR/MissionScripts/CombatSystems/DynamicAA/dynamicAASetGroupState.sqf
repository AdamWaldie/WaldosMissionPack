/*
 * Author: Waldo
 * Enables or suppresses one server-local air-defence group without deleting it.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: active <BOOLEAN>
 *
 * Return Value:
 * Boolean - true when the group was updated
 *
 * Example:
 * [_group, false] call Waldo_fnc_DynamicAASetGroupState;
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_active", false, [false]],
    ["_targets", [], [[]]]
];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (isNull _group) exitWith {false};
if !(local _group) exitWith {
    if !(isServer) exitWith {false};
    private _groupOwner = groupOwner _group;
    if (_groupOwner <= 0 || {_groupOwner == clientOwner}) exitWith {false};
    [_group, _active, _targets] remoteExecCall ["Waldo_fnc_DynamicAASetGroupState", _groupOwner];
    true
};

{
    if (_active) then {
        _x enableAI "TARGET";
        _x enableAI "AUTOTARGET";
        _x enableAI "WEAPONAIM";
        _x enableAI "SUPPRESSION";
    } else {
        _x doTarget objNull;
        _x disableAI "TARGET";
        _x disableAI "AUTOTARGET";
        _x disableAI "WEAPONAIM";
        _x disableAI "SUPPRESSION";
    };
} forEach units _group;

_group enableAttack _active;
_group setCombatMode (["BLUE", "RED"] select _active);
_group setBehaviourStrong (["SAFE", "COMBAT"] select _active);
if (_active) then {
    {_group reveal [_x, 4]} forEach (_targets select {!isNull _x});
};
true
