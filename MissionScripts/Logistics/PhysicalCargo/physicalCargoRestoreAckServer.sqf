/*
 * Author: WaldoTheWarfighter
 * Purpose: Completes a safe unload only after the cargo owner detached and placed the object.
 * Locality / Authority: Server validates an acknowledgement from the current cargo owner.
 * Repeat / JIP: One restore token can complete once; stale or duplicate acknowledgements are ignored.
 * Arguments: 0: cargo <OBJECT>; 1: restore token <NUMBER>.
 * Return Value: <BOOL> true when the saved simulation/collision state was restored.
 * Current caller: Waldo_fnc_PhysicalCargoRestoreLocal after a checked unload placement.
 * Example: [crate, 3] remoteExecCall ["Waldo_fnc_PhysicalCargoRestoreAckServer", 2];
 * Result: The server completes cleanup only for the matching restore token.
 */
params [["_cargo", objNull, [objNull]], ["_token", -1, [0]]];
if (!isServer || {isNull _cargo} || {_token < 0}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _cargo}) exitWith {false};
private _pending = _cargo getVariable ["Waldo_PhysicalCargo_RestorePending", []];
if (count _pending != 4 || {(_pending select 0) != _token}) exitWith {false};
_pending params ["_savedToken", "_vehicle", "_priorSimulation", "_priorCollision"];
if (!isNull (_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])) exitWith {false};
if (!isNull attachedTo _cargo) exitWith {false};
if (!isNull _vehicle && {_cargo distance _vehicle < 2}) exitWith {false};
_cargo setVariable ["Waldo_PhysicalCargo_RestorePending", []];
_cargo setVariable ["Waldo_PhysicalCargo_PreviousSimulation", nil];
_cargo setVariable ["Waldo_PhysicalCargo_PreviousCollision", nil];
[_cargo, _vehicle, _priorCollision, [], _token, true]
    remoteExecCall ["Waldo_fnc_PhysicalCargoRestoreLocal", 0];
_cargo enableSimulationGlobal _priorSimulation;
// The object is now clear of the vehicle, so the mass held back while mounted can return.
private _mass = _cargo getVariable ["Waldo_PhysicalCargo_RestoreMass", 0];
if (_mass > 0) then {
    _cargo setVariable ["Waldo_PhysicalCargo_RestoreMass", nil];
    ["ace_common_setMass", [_cargo, _mass]] call CBA_fnc_globalEvent;
};
diag_log format ["[WMP PHYSICAL CARGO] Safe unload restored %1, simulation=%2 collision=%3.",
    typeOf _cargo, _priorSimulation, _priorCollision];
true
