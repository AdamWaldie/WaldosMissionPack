/*
 * Compatibility wrapper for the former player-bound "Flip Vehicle" action.
 * New missions use the object-bound Set Vehicle Upright action.
 * Author: WaldoTheWarfighter
 *
 * Arguments: addAction payload with:
 * 0: _target <OBJECT> - unused
 * 1: _caller <OBJECT> - the player who triggered the action
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * player addAction ["Flip Vehicle", "MissionScripts\Logistics\LogiHelpers\flipAction.sqf"];
 * Locality and authority: Runs from a local legacy player action and sends an eligible
 * nearby vehicle to the server's VehicleUpright validation. Repeated requests are checked
 * there; this wrapper creates no persistent JIP state.
 * Current caller: legacy mission-maker player addAction setup.
 * Result: The server receives a request to set the selected land vehicle upright.
 */

private _caller = _this param [1, player];
private _vehicle = _this param [0, objNull];
if (isNull _vehicle || {!(_vehicle isKindOf "LandVehicle")}) then {
    _vehicle = (nearestObjects [_caller, ["LandVehicle"], 5]) param [0, objNull];
};
if (!isNull _vehicle) then {[_vehicle, _caller] remoteExecCall ["Waldo_fnc_VehicleUpright", 2]};

//=================================================================================================
