/*
 * Author: WaldoTheWarfighter
 * Safely exits a local unit from an aircraft and places them into the configured static-line
 * parachute vehicle while preserving exit velocity. Damage protection is temporary and always
 * restored. Must run where the unit is local and in a scheduled environment.
 *
 * Arguments:
 * 0: jumping unit <OBJECT>
 * 1: aircraft <OBJECT>
 * 2: parachute vehicle class <STRING> (default "NonSteerable_Parachute_F")
 *
 * Return Value:
 * Boolean - true when the jump sequence was started.
 *
 * Called by:
 * Waldo_fnc_AddStaticJump and dynamic paradrop automatic sequencing.
 *
 * Example:
 * [player, aircraft, "NonSteerable_Parachute_F"] spawn Waldo_fnc_StaticJumpFunc;
 */

params [
    ["_unit", objNull, [objNull]],
    ["_vehicle", objNull, [objNull]],
    ["_chuteVehicleClass", "NonSteerable_Parachute_F", [""]]
];

if (isNull _unit || {isNull _vehicle} || {!local _unit} || {vehicle _unit != _vehicle}) exitWith {false};
if !(isClass (configFile >> "CfgVehicles" >> _chuteVehicleClass)) exitWith {false};

_unit allowDamage false;
private _direction = getDir _vehicle;
private _exitPosition = [_vehicle, 14, _direction + 188] call BIS_fnc_relPos;
_exitPosition set [2, (getPosATL _vehicle) select 2];
private _exitVelocity = velocity _vehicle;
moveOut _unit;
_unit setPosATL _exitPosition;
_unit setDir (_direction + 170);
sleep 1.5;

private _chute = createVehicle [_chuteVehicleClass, getPosATL _unit, [], 0, "CAN_COLLIDE"];
_unit moveInDriver _chute;
_chute setVelocity _exitVelocity;
[_unit] call Waldo_fnc_paraEquipmentSim;
sleep 0.5;
_unit allowDamage true;
true
