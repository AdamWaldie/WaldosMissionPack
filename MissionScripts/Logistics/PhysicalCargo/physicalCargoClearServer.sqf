/*
 * Author: WaldoTheWarfighter
 * Purpose: Clears a mount on pickup, ACE internal load, explicit unmount or failed attachment.
 * Locality / Authority: Server only; the server validates remote carrier identity and range.
 * Repeat / JIP: No-op after a clear; public mount registry and object state are updated.
 *
 * Arguments: 0: crate <OBJECT>; 1: carrier <OBJECT> (objNull for server event);
 *            2: optional drop position <ARRAY> ([]).
 * Return Value: BOOLEAN - true when prior physical-cargo state was cleared.
 * Current callers: Waldo_fnc_PhysicalCargoInitLocal and Waldo_fnc_PhysicalCargoInitServer.
 * Example: [crate, player] remoteExecCall ["Waldo_fnc_PhysicalCargoClearServer", 2];
 */
params [
    ["_cargo", objNull, [objNull]],
    ["_carrier", objNull, [objNull]],
    ["_dropPosition", [], [[]]]
];
if (!isServer || {isNull _cargo}) exitWith {false};
if (isRemoteExecuted && {isNull _carrier}) exitWith {false};
if (!isNull _carrier && {isRemoteExecuted} && {remoteExecutedOwner isNotEqualTo owner _carrier}) exitWith {false};
if (!isNull _carrier && {_carrier distance _cargo > 6}) exitWith {false};
private _vehicle = _cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull];
private _mounts = +(missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]);
private _mountIndex = _mounts findIf {(_x select 0) isEqualTo _cargo};
if (isNull _vehicle && {_mountIndex < 0}) exitWith {false};
if (isNull _vehicle && {_mountIndex >= 0}) then {_vehicle = (_mounts select _mountIndex) select 1};
private _safeDrop = count _dropPosition == 3;
private _priorSimulation = _cargo getVariable ["Waldo_PhysicalCargo_PreviousSimulation", true];
private _priorCollision = _cargo getVariable ["Waldo_PhysicalCargo_PreviousCollision", true];
private _restoreToken = -1;
if (_safeDrop) then {
    // Never wake detached cargo while its model still intersects the carrier.
    _cargo enableSimulationGlobal false;
    _restoreToken = (_cargo getVariable ["Waldo_PhysicalCargo_RestoreSerial", 0]) + 1;
    _cargo setVariable ["Waldo_PhysicalCargo_RestoreSerial", _restoreToken, true];
    _cargo setVariable ["Waldo_PhysicalCargo_RestorePending",
        [_restoreToken, _vehicle, _priorSimulation, _priorCollision], true];
};
_cargo setVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull, true];
[_cargo, _vehicle, false] call Waldo_fnc_PhysicalCargoSeatsServer;
_mounts = _mounts select {(_x select 0) isNotEqualTo _cargo};
missionNamespace setVariable ["Waldo_PhysicalCargo_Mounts", _mounts, true];
[_cargo, _vehicle, _priorCollision, _dropPosition, _restoreToken]
    remoteExecCall ["Waldo_fnc_PhysicalCargoRestoreLocal", 0];
// ACE owns the simulation state after an internal load. Never re-enable it behind ACE's back.
if (!_safeDrop && {!(_cargo in (_vehicle getVariable ["ace_cargo_loaded", []]))}) then {
    _cargo enableSimulationGlobal _priorSimulation;
};
if (!_safeDrop) then {
    _cargo setVariable ["Waldo_PhysicalCargo_PreviousSimulation", nil, true];
    _cargo setVariable ["Waldo_PhysicalCargo_PreviousCollision", nil, true];
};
_cargo setVariable ["Waldo_PhysicalCargo_Mode", nil, true];
if (_safeDrop) then {
    [_cargo, _vehicle, _priorCollision, _dropPosition, _restoreToken] spawn {
        params ["_cargo", "_vehicle", "_priorCollision", "_dropPosition", "_restoreToken"];
        sleep 1;
        if (!isNull _cargo && {(_cargo getVariable ["Waldo_PhysicalCargo_RestorePending", []]) param [0, -1] == _restoreToken}) then {
            [_cargo, _vehicle, _priorCollision, _dropPosition, _restoreToken]
                remoteExecCall ["Waldo_fnc_PhysicalCargoRestoreLocal", 0];
        };
    };
};
true
