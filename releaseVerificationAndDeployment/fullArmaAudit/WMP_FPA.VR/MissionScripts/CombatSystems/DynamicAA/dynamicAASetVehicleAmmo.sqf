/*
 * Author: WaldoTheWarfighter
 * Applies a Dynamic AA ammunition fraction where the vehicle is currently local.
 * Arguments: 0: vehicle <OBJECT>; 1: ammunition fraction <NUMBER>
 * Return Value: Boolean
 * Locality and authority: Server calls on an owner-local vehicle run here; if ownership has
 * moved, the server forwards once to the current owner. Rejects untrusted remote senders.
 * Repeat/JIP: Reapplying a fraction updates live ammo state, which the vehicle replicates.
 * Current callers: DynamicAADetectorLoop and DynamicAADestroy.
 * Example: [_aaVehicle, 0.5] call Waldo_fnc_DynamicAASetVehicleAmmo;
 * Result: The AA vehicle receives the requested fraction of ammunition on its owner.
 */

params [["_vehicle", objNull, [objNull]], ["_fraction", 1, [0]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (isNull _vehicle) exitWith {false};
if !(local _vehicle) exitWith {
    if !(isServer) exitWith {false};
    private _vehicleOwner = owner _vehicle;
    if (_vehicleOwner <= 0 || {_vehicleOwner == clientOwner}) exitWith {false};
    [_vehicle, _fraction] remoteExecCall ["Waldo_fnc_DynamicAASetVehicleAmmo", _vehicleOwner];
    true
};
_vehicle setVehicleAmmo ((_fraction max 0) min 1);
true
