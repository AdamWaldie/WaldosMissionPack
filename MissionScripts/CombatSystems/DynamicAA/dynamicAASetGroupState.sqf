/*
 * Author: WaldoTheWarfighter
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

private _eligibleTargets = _targets select {!isNull _x && {alive _x} && {_x isKindOf "Air"}};

{
    if (_active) then {
        _x enableAI "TARGET";
        // Strict detector ownership: ordinary Arma auto-targeting would allow the crew to acquire
        // low aircraft and ground units after one eligible aircraft activated the site.
        _x disableAI "AUTOTARGET";
        _x enableAI "WEAPONAIM";
        _x enableAI "SUPPRESSION";
    } else {
        _x doTarget objNull;
        _x doWatch objNull;
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
    {_group reveal [_x, 4]} forEach _eligibleTargets;
    private _targetCount = count _eligibleTargets;
    if (_targetCount > 0) then {
        {
            _x doTarget (_eligibleTargets select (_forEachIndex mod _targetCount));
        } forEach units _group;
    };
};
true
