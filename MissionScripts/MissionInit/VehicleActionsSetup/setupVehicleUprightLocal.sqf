/*
 * Author: WaldoTheWarfighter
 * Purpose: Install the Set Vehicle Upright action on a land vehicle for one interface client.
 * Locality/authority: local UI setup only; selection sends a request to the server, where player
 * identity and distance are validated before the vehicle owner's movement command runs.
 * Repeat/JIP: repeat calls reuse the stored action ID on that client. Client vehicle setup invokes
 * this for current and joining players; no server-side action is installed.
 * Arguments: 0 vehicle <OBJECT> (default objNull, rejected) - land vehicle receiving the action.
 * Return value: BOOL - true when installed/already present, false for no interface or bad vehicle.
 * Current caller: Waldo_fnc_AddVehicleFunctions during client vehicle setup.
 * Example: [_vehicle] call Waldo_fnc_SetupVehicleUprightLocal;
 * Result: this interface shows Set Vehicle Upright on the valid tipped vehicle.
 */
params [["_vehicle", objNull, [objNull]]];
if (!hasInterface || {isNull _vehicle} || {!(_vehicle isKindOf "LandVehicle")}) exitWith {false};
if (_vehicle getVariable ["Waldo_VehicleUpright_Action", -1] >= 0) exitWith {true};

private _action = _vehicle addAction [
    "<t color='#4FA9E8'>Set Vehicle Upright</t>",
    {
        params ["_target", "_caller"];
        [_target, _caller] remoteExecCall ["Waldo_fnc_VehicleUpright", 2];
    },
    [],
    0,
    false,
    true,
    "",
    "vehicle _this == _this && {_this distance _target <= 6} && {speed _target < 3} && {(vectorUp _target select 2) < 0.65}",
    6
];
_vehicle setVariable ["Waldo_VehicleUpright_Action", _action];
true
