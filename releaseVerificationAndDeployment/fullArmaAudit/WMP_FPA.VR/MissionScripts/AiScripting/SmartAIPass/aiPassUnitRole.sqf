/*
 * Author: WaldoTheWarfighter
 * Classifies a soldier's combat role from what he carries.
 *
 * MG: primary magazine holds 75 rounds or more. AT: carries a launcher with ammunition. MEDIC: ACE
 * or vanilla medic trait. LEADER: group leader. Otherwise RIFLE. Magazine sizes are cached per class
 * in a machine-local map, so repeated calls cost a lookup.
 * Locality and authority: read-only; callable anywhere.
 *
 * Arguments:
 * 0: unit <OBJECT>
 *
 * Return Value:
 * String - "LEADER", "MG", "AT", "MEDIC" or "RIFLE"
 *
 * Example:
 * if (([_unit] call Waldo_fnc_AIPassUnitRole) == "MG") then {...};
 * Result: machine gunners are preferred for suppression and kept in the base of fire.
 *
 * Current callers: Waldo_fnc_AIPassFlankStart, Waldo_fnc_AIPassFireControl and Waldo_fnc_AIPassAntiArmour.
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith {"RIFLE"};
if (leader group _unit == _unit) exitWith {"LEADER"};
if (secondaryWeapon _unit != "" && {(secondaryWeaponMagazine _unit) isNotEqualTo [] || {({_x in (compatibleMagazines (secondaryWeapon _unit))} count magazines _unit) > 0}}) exitWith {"AT"};
private _cache = missionNamespace getVariable ["Waldo_AIPass_MagazineSizes", createHashMap];
private _magazine = (primaryWeaponMagazine _unit) param [0, ""];
private _size = _cache getOrDefault [_magazine, -1];
if (_size < 0) then {
    _size = getNumber (configFile >> "CfgMagazines" >> _magazine >> "count");
    _cache set [_magazine, _size];
    missionNamespace setVariable ["Waldo_AIPass_MagazineSizes", _cache];
};
if (_size >= 75) exitWith {"MG"};
if (_unit getUnitTrait "Medic" || {(_unit getVariable ["ace_medical_medicClass", 0]) > 0}) exitWith {"MEDIC"};
"RIFLE"
