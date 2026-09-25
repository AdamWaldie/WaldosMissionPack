/*
 * Author: WaldoTheWarfighter
 * Makes one AI soldier jump from an aircraft on a parachute of his own, keeping his backpack.
 *
 * The soldier leaves behind the aircraft with its speed, and a parachute vehicle (the pack's
 * static-line class, WALDO_STATIC_STATICCHUTE, default NonSteerable_Parachute_F) is created for him a
 * moment later, so his backpack is never swapped out (PROTOCOL Airborne's addBackpack dropped the
 * real backpack under the aircraft). He is protected from damage for the few seconds of the exit.
 * AI leave a parachute on their own when they land. For players, use the Paradrop feature instead.
 * Locality and authority: call where the soldier is local (moveOut and moveInDriver are local-argument).
 *
 * Arguments:
 * 0: soldier <OBJECT>
 * 1: aircraft <OBJECT>
 *
 * Return Value:
 * Boolean - true when the soldier jumped
 *
 * Example:
 * [_soldier, _helicopter] call Waldo_fnc_AIPassParachuteJump;
 * Result: the soldier drops behind the helicopter and his parachute opens.
 *
 * Current caller: Waldo_fnc_AIPassAirborneDropStep.
 */

params [["_unit", objNull, [objNull]], ["_aircraft", objNull, [objNull]]];
if (isNull _unit || {!alive _unit} || {!local _unit} || {isPlayer _unit} || {vehicle _unit != _aircraft}) exitWith {false};
private _chuteClass = missionNamespace getVariable ["WALDO_STATIC_STATICCHUTE", "NonSteerable_Parachute_F"];
if !(isClass (configFile >> "CfgVehicles" >> _chuteClass)) then {_chuteClass = "NonSteerable_Parachute_F"};
private _velocity = velocity _aircraft;
// Just behind and below the airframe, clear of rotors and tail ramp.
private _exit = _aircraft modelToWorld [0, ((((boundingBoxReal _aircraft) select 0) select 1) min -6) - 2, -3];
_unit allowDamage false;
unassignVehicle _unit;
moveOut _unit;
_unit setPosATL _exit;
_unit setVelocity _velocity;
[{
    params ["_unit", "_chuteClass", "_velocity"];
    if (!alive _unit || {!local _unit} || {vehicle _unit != _unit}) exitWith {_unit allowDamage true};
    private _chute = createVehicle [_chuteClass, getPosATL _unit, [], 0, "CAN_COLLIDE"];
    _chute setDir getDir _unit;
    _unit moveInDriver _chute;
    _chute setVelocity (_velocity vectorMultiply 0.5);
    [{_this allowDamage true}, _unit, 3] call CBA_fnc_waitAndExecute;
}, [_unit, _chuteClass, _velocity], 0.8] call CBA_fnc_waitAndExecute;
true
