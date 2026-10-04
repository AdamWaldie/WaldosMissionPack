/*
 * Author: WaldoTheWarfighter
 * Purpose: Right one tipped land vehicle using its current owner for locality-sensitive movement.
 * Locality/authority: a server request validates remote player identity/distance and forwards
 * to the vehicle owner when required. Only the server or its forwarded owner request may act.
 * Repeat/JIP: each accepted call is a one-shot orientation change; normal vehicle state syncs
 * to current and joining clients. No persistent action or replay is created here.
 * Arguments:
 * 0: vehicle <OBJECT> (default objNull, rejected) - existing land vehicle.
 * 1: actor <OBJECT> (default objNull) - requesting player for a remote player action; server
 *    mission scripts may omit it.
 * Return value: BOOL - true after local movement or a server forward; false if rejected.
 * Current callers: the local Set Vehicle Upright action and server mission scripts.
 * Example: [_vehicle] call Waldo_fnc_VehicleUpright; // in initServer.sqf or server script
 * Result: a validated land vehicle is set upright by its current owner.
 */
params [
    ["_vehicle", objNull, [objNull]],
    ["_actor", objNull, [objNull]]
];
if (isNull _vehicle || {!(_vehicle isKindOf "LandVehicle")}) exitWith {false};

if (isServer && {remoteExecutedOwner > 0}) then {
    private _requesterIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _requester = if (_requesterIndex >= 0) then {allPlayers select _requesterIndex} else {objNull};
    if (isNull _requester || {!(_requester isEqualTo _actor)} || {_requester distance _vehicle > 8}) exitWith {false};
};

if (isServer && {!local _vehicle}) exitWith {
    private _vehicleOwner = owner _vehicle;
    if (_vehicleOwner <= 2) exitWith {false};
    [_vehicle] remoteExecCall ["Waldo_fnc_VehicleUpright", _vehicleOwner];
    true
};
if (!isServer && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _vehicle) exitWith {false};

private _position = getPosATL _vehicle;
private _heading = getDir _vehicle;
private _bounds = boundingBoxReal _vehicle;
private _minimumZ = ((_bounds param [0, [0, 0, -0.25]]) param [2, -0.25]);
private _clearance = (0.15 - _minimumZ) max 0.25;
private _surfaceUp = surfaceNormal (getPosWorld _vehicle);

_vehicle setVelocity [0, 0, 0];
_vehicle setVectorDirAndUp [[sin _heading, cos _heading, 0], _surfaceUp];
_vehicle setPosATL [_position select 0, _position select 1, _clearance];
true
