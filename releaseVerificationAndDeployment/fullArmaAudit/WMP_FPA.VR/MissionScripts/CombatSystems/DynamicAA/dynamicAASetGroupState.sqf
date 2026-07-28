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
    ["_active", false, [false]]
];
if (isNull _group || {!local _group}) exitWith {false};

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
true
