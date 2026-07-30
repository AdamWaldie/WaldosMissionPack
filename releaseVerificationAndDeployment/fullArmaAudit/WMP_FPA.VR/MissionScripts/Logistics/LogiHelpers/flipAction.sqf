/*
 * Compatibility wrapper for the former player-bound "Flip Vehicle" action.
 * New missions use the object-bound Set Vehicle Upright action.
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

private _caller = _this param [1, player];
private _vehicle = _this param [0, objNull];
if (isNull _vehicle || {!(_vehicle isKindOf "LandVehicle")}) then {
    _vehicle = (nearestObjects [_caller, ["LandVehicle"], 5]) param [0, objNull];
};
if (!isNull _vehicle) then {[_vehicle, _caller] remoteExecCall ["Waldo_fnc_VehicleUpright", 2]};

//=================================================================================================
