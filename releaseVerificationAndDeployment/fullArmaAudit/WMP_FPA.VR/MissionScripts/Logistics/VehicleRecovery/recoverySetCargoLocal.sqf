/*
 * Author: WaldoTheWarfighter
 * Loads a packaged vehicle through Arma's vehicle-in-vehicle cargo command.
 * Locality and authority: Runs only on the carrier's current owner after a server-sent
 * request. Calls from another remote owner are rejected. Repeat requests reapply the same
 * cargo command; the vehicle's resulting engine state is visible to JIP clients.
 * Arguments: 0: recovery carrier <OBJECT>; 1: packaged vehicle <OBJECT>.
 * Return Value: <BOOL> true when the command ran on the carrier owner; false otherwise.
 * Current caller: Waldo_fnc_RecoveryRequestServer for physical carrier loading.
 * Example: [recoveryTruck, damagedCar] remoteExecCall
 *   ["Waldo_fnc_RecoverySetCargoLocal", owner recoveryTruck];
 * Result: The carrier attempts to place the packaged vehicle in its configured bay.
 */
params [["_carrier", objNull, [objNull]], ["_cargo", objNull, [objNull]]];
if (remoteExecutedOwner != 2 || {isNull _carrier} || {!local _carrier}) exitWith {false};
_carrier setVehicleCargo _cargo;
true
