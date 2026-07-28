/*
 * Author: Waldo
 * Validates a local axe swing and forwards the requested tree hit to the server.
 *
 * Arguments:
 * 0: unit <OBJECT> - swinging player
 * 1: weapon <STRING> - active weapon classname
 * 2: target <OBJECT> - tree under the cursor
 *
 * Return Value:
 * Boolean - true when a request was sent
 *
 * Example:
 * [player, currentWeapon player, cursorObject] call Waldo_fnc_TreeFellingSwing;
 */

params [
    ["_unit", objNull, [objNull]],
    ["_weapon", "", [""]],
    ["_target", objNull, [objNull]]
];
if !(hasInterface && {local _unit}) exitWith {false};
if (remoteExecutedOwner > 0) exitWith {false};
if (!isNull _target && {_unit distance _target > (missionNamespace getVariable ["Waldo_TreeFelling_Range", 3])}) exitWith {false};

private _patterns = missionNamespace getVariable ["Waldo_TreeFelling_WeaponPatterns", ["axe", "hatchet"]];
private _weaponLower = toLowerANSI _weapon;
if (_patterns findIf {_weaponLower find toLowerANSI _x >= 0} < 0) exitWith {
    systemChat "[WMP] An axe or configured cutting tool is required.";
    false
};

[_unit, _weapon, _target] remoteExecCall ["Waldo_fnc_TreeFellingProcess", 2];
true
