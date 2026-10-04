/*
 * Author: WaldoTheWarfighter
 * Gives an unarmed civilian one finite, engine-native escape response away from nearby danger.
 * Three separated escape headings use the shared bounded terrain selector, then one safe-position
 * adjustment is accepted only when its complete route remains passable. This avoids sending a
 * civilian into water, a cliff or an abrupt grade without installing a continuous path controller.
 * It does not install an FSM, force an animation, reserve a vehicle or continually steer the unit.
 * Simple Civilian Behaviour, Zeus, player control and externally owned actors always take priority.
 *
 * Locality / Authority: execute where the civilian is local. The reaction marker is public so a
 * locality transfer cannot immediately duplicate the same response.
 * Repeat/JIP: reactions are cooldown limited and expire naturally; JIP needs no replay.
 *
 * Arguments:
 * 0: civilian <OBJECT>, default objNull
 * 1: threat <OBJECT or ARRAY position>, default objNull
 *
 * Return Value:
 * Boolean - true when a real flee order was issued.
 *
 * Current callers: FiredNear and Hit handlers installed by Waldo_fnc_CortexCivilianSetup.
 *
 * Example:
 * [_civilian,_shooter] call Waldo_fnc_CortexCivilianReact;
 * Result: the civilian runs to a safe point away from the shooter without a polling controller.
 */

params [["_unit",objNull,[objNull]],["_threat",objNull,[objNull,[]]]];
if (isNull _unit || {!local _unit} || {!alive _unit} || {isPlayer _unit}
    || {side group _unit != civilian}
    || {primaryWeapon _unit != "" || {secondaryWeapon _unit != ""} || {handgunWeapon _unit != ""}}
    || {!(missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Enable",true])}
    || {[_unit] call Waldo_fnc_CortexExternalOwner != ""}
    || {!isNull (_unit getVariable ["bis_fnc_moduleRemoteControl_owner",objNull])}
    || {[group _unit] call Waldo_fnc_CortexZeusHeld}) exitWith {false};
private _cooldown=missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Cooldown",20];
if (serverTime < (_unit getVariable ["Waldo_Cortex_CivilianReactionUntil",0])) exitWith {false};
private _threatPos=if (_threat isEqualType objNull) then {
    if (isNull _threat) then {getPosATL _unit vectorAdd [sin (random 360),cos (random 360),0]} else {getPosATL _threat}
} else {+_threat};
private _origin=getPosATL _unit;
private _away=_origin vectorDiff _threatPos;
_away set [2,0];
if (vectorMagnitude _away < 1) then {_away=[sin (random 360),cos (random 360),0]};
_away=vectorNormalized _away;
private _distance=(missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Distance",180])*(0.75+random 0.5);
private _escapeBearing=_origin getDir (_origin vectorAdd _away);
private _routes=[];
{_routes pushBack [[_origin getPos [_distance,_escapeBearing+_x]]]} forEach [0,-45,45];
private _threatObject=if (_threat isEqualType objNull) then {_threat} else {objNull};
private _route=[_origin,_routes,_threatPos,[],_threatObject,"INFANTRY"] call Waldo_fnc_CortexSelectAvenue;
if (_route isEqualTo []) exitWith {false};
private _routeDestination=+(_route select 0);
private _safeDestination=[_routeDestination,0,35,3,0,0.35,0,[],[_routeDestination,_routeDestination]] call BIS_fnc_findSafePos;
private _safeRoute=[_origin,[[_safeDestination]],_threatPos,[],_threatObject,"INFANTRY"] call Waldo_fnc_CortexSelectAvenue;
private _destination=if (_safeRoute isEqualTo []) then {_routeDestination} else {+(_safeRoute select 0)};
_unit setVariable ["Waldo_Cortex_CivilianReactionUntil",serverTime+(_cooldown max 2),true];
_unit setBehaviour "CARELESS";
_unit setSpeedMode "FULL";
_unit setUnitPos "UP";
_unit doMove _destination;
true
