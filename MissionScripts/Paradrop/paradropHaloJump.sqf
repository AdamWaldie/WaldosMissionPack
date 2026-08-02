/*
 * Author: WaldoTheWarfighter
 * Safely exits a local unit from an aircraft for a HALO jump, preserves their original backpack
 * and contents through Waldo_fnc_ParaBackpack, equips the selected steerable parachute backpack,
 * applies the configured equipment simulation, and restores damage after the exit transition.
 * Must run where the jumping unit is local and in a scheduled environment.
 *
 * Arguments:
 * 0: jumping unit <OBJECT>
 * 1: aircraft <OBJECT>
 * 2: parachute backpack class <STRING> (default "B_Parachute")
 *
 * Return Value:
 * Boolean - true when the jump sequence was started.
 *
 * Called by:
 * Waldo_fnc_AddHaloJump and dynamic paradrop automatic player sequencing.
 *
 * Example:
 * [player, aircraft, "B_Parachute"] spawn Waldo_fnc_HaloJumpFunc;
 */

params [
    ["_unit", objNull, [objNull]],
    ["_vehicle", objNull, [objNull]],
    ["_chuteBackpackClass", "B_Parachute", [""]]
];

if (isNull _unit || {isNull _vehicle} || {!local _unit} || {vehicle _unit != _vehicle}) exitWith {false};
if !(isClass (configFile >> "CfgVehicles" >> _chuteBackpackClass)) exitWith {false};

_unit allowDamage false;
private _direction = getDir _vehicle;
private _exitPosition = [_vehicle, 14, _direction + 188] call BIS_fnc_relPos;
_exitPosition set [2, (getPosATL _vehicle) select 2];
moveOut _unit;
_unit setPosATL _exitPosition;
_unit setDir (_direction + 170);
sleep 1.5;
[_unit] call Waldo_fnc_paraEquipmentSim;
[_unit, _chuteBackpackClass] call Waldo_fnc_ParaBackpack;
sleep 0.5;
_unit allowDamage true;
true
