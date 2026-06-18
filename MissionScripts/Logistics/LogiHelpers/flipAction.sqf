/*
 * Adds the "Flip Vehicle" behaviour - resets the nearest land vehicle upright, just off the ground.
 * Bound to the player "Flip Vehicle" addAction in initPlayerLocal.sqf.
 * (Original author unknown; retained as-is.)
 *
 * Arguments (addAction):
 * 0: _target <OBJECT> - unused
 * 1: _caller <OBJECT> - the player who triggered the action
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * player addAction ["Flip Vehicle", "MissionScripts\Logistics\LogiHelpers\flipAction.sqf"];
 */

////     FLIPACTION.SQF    ////====================================================================
// Not my script originally, but cannot remember the original author. Works as intended, just resets vehilces position to the right way up, just off the ground. I advise not editing.

private ["_caller","_veh"];
_caller = _this select 1;
_veh = nearestObjects [_caller, ["landVehicle"], 5] select 0;
_veh setVectorUp [0,0,1];
_veh setPosATL [(getPosATL _veh) select 0, (getPosATL _veh) select 1, 0];

//=================================================================================================