/*
 * Author: WaldoTheWarfighter
 * Performs the server-only ACRE API half of a validated rack hardware change requested by the
 * selected rack worker client. ACRE sends the resulting mount/unmount/remove event back to that
 * client, where Waldo_fnc_ACRE2RackClientApply verifies the actual state transition.
 * Locality/authority: server only. The running request token and remote client owner are checked;
 * the rack must belong to the configured vehicle. No public/JIP state is created by WMP.
 * Repeat behaviour: stale or mismatched requests are rejected; ACRE owns operation idempotence.
 *
 * Arguments:
 * 0: rack vehicle/object <OBJECT>
 * 1: request token <STRING>
 * 2: rack unique ID <STRING>
 * 3: operation <STRING> - REMOVE_RACK, UNMOUNT_RADIO or MOUNT_RADIO
 * 4: radio value <STRING> - mounted unique ID for unmount, base classname for mount
 * Return Value: BOOL - true when ACRE accepted the server request.
 * Current caller: Waldo_fnc_ACRE2RackClientApply.
 * Example: [_vehicle, _token, _rackId, "MOUNT_RADIO", "ACRE_PRC152"] remoteExecCall
 *          ["Waldo_fnc_ACRE2RackHardwareServer", 2];
 */
params [
    ["_vehicle", objNull, [objNull]], ["_token", "", [""]], ["_rackId", "", [""]],
    ["_operation", "", [""]], ["_radio", "", [""]]
];
if (!isServer || {remoteExecutedOwner <= 2} || {isNull _vehicle}) exitWith {false};
if ((_vehicle getVariable ["Waldo_ACRE2_RackClientOwner", -1]) != remoteExecutedOwner) exitWith {false};
if ((_vehicle getVariable ["Waldo_ACRE2_RackClientToken", ""]) != _token) exitWith {false};
if !(_rackId in ([_vehicle] call acre_api_fnc_getVehicleRacks)) exitWith {false};
switch (toUpperANSI _operation) do {
    case "REMOVE_RACK": {[_vehicle, _rackId] call acre_api_fnc_removeRackFromVehicle};
    case "UNMOUNT_RADIO": {if (_radio == "") then {false} else {[_rackId, _radio] call acre_api_fnc_unmountRackRadio}};
    case "MOUNT_RADIO": {if (_radio == "") then {false} else {[_rackId, _radio] call acre_api_fnc_mountRackRadio}};
    default {false};
}
