/*
 * Author: WaldoTheWarfighter
 * Installs repeat-safe local load and unload controls on one registered recovery carrier.
 *
 * Visibility uses the combined physical-bay and synchronized virtual-manifest count, so the same
 * controls work for engine cargo carriers and arbitrary virtual carriers. Requests contain no
 * trusted state; the server revalidates the actor, carrier, capacity and package operation.
 *
 * Arguments:
 * 0: carrier <OBJECT>
 *
 * Return Value:
 * Boolean - true when installed; false when unavailable or already installed.
 *
 * Example:
 * [_carrier] remoteExecCall ["Waldo_fnc_RecoverySetupCarrierLocal", 0, _carrier];
 *
 * Current caller: Waldo_fnc_RecoveryRegisterCarrier for current and joining clients.
 */
params [["_target", objNull, [objNull]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _target} || {_target getVariable ["Waldo_Recovery_CarrierActionsInstalled", false]}) exitWith {false};
private _load = _target addAction [
    "<t color='#F4C542'>Load Recovery Package</t>",
    {params ["_target", "_actor"]; [_actor, "LOAD", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];},
    [], 1.4, true, true, "", "_this distance _target <= ((_target getVariable ['Waldo_Recovery_CarrierRange', 10]) max 3) && {alive _target} && {abs speed _target < 1} && {(count (getVehicleCargo _target)) + (count (_target getVariable ['Waldo_Recovery_AttachedPackages', []])) + (count (_target getVariable ['Waldo_Recovery_VirtualPackages', []])) < (_target getVariable ['Waldo_Recovery_CarrierCapacity', 1])}", 30
];
private _unload = _target addAction [
    "<t color='#F4C542'>Unload Recovery Package</t>",
    {params ["_target", "_actor"]; [_actor, "UNLOAD", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];},
    [], 1.4, true, true, "", "_this distance _target <= ((_target getVariable ['Waldo_Recovery_CarrierRange', 10]) max 3) && {alive _target} && {abs speed _target < 1} && {(count (getVehicleCargo _target)) + (count (_target getVariable ['Waldo_Recovery_AttachedPackages', []])) + (count (_target getVariable ['Waldo_Recovery_VirtualPackages', []])) > 0}", 30
];
_target setVariable ["Waldo_Recovery_CarrierActionIds", [_load, _unload]];
_target setVariable ["Waldo_Recovery_CarrierActionsInstalled", true];
true
