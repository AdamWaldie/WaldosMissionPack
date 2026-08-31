/*
 * Author: WaldoTheWarfighter
 * Validates a local axe swing and forwards one requested tree hit to the server.
 * Locality/authority: interface-local prefilter only; the server repeats all authoritative checks.
 * Repeat/JIP behaviour: stateless and inert while disabled. Non-target IMS swings return before tool
 * checks, notifications or network traffic.
 * Arguments: unit OBJECT, weapon STRING, target OBJECT.
 * Return Value: BOOL - true when one request was sent.
 * Current callers: TreeFellingInit action and optional IMS swing callback.
 * Example: [player, currentWeapon player, cursorObject] call Waldo_fnc_TreeFellingSwing;
 */

params [
    ["_unit", objNull, [objNull]],
    ["_weapon", "", [""]],
    ["_target", objNull, [objNull]]
];
if !(hasInterface && {local _unit}) exitWith {false};
if (remoteExecutedOwner > 0) exitWith {false};
if !([_target, _unit] call Waldo_fnc_TreeFellingCanTargetLocal) exitWith {false};

private _patterns = missionNamespace getVariable ["Waldo_TreeFelling_WeaponPatterns", ["axe", "hatchet"]];
private _weaponLower = toLowerANSI _weapon;
if (_patterns findIf {_weaponLower find toLowerANSI _x >= 0} < 0) exitWith {
    ["TREE FELLING", "An axe or configured cutting tool is required.", "WARNING", "TREE_FELLING"] call Waldo_fnc_FeatureNotifyLocal;
    false
};

[_unit, _weapon, _target] remoteExecCall ["Waldo_fnc_TreeFellingProcess", 2];
true
