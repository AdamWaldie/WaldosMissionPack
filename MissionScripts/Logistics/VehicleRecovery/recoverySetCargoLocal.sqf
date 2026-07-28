/* Executes the local setVehicleCargo command only for a server-authorized request. */
params [["_carrier", objNull, [objNull]], ["_cargo", objNull, [objNull]]];
if (remoteExecutedOwner != 2 || {isNull _carrier} || {!local _carrier}) exitWith {false};
_carrier setVehicleCargo _cargo;
true
