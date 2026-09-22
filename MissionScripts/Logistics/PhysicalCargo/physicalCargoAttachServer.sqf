/*
 * Author: WaldoTheWarfighter
 * Purpose: Validates the released object, then records an inert physical-cargo mount.
 * Locality / Authority: Server validates remote carrier ownership, geometry and proximity.
 * Repeat / JIP: Repeat requests are ignored; public mount state and request/replay support JIP.
 *
 * Arguments: 0: carrier <OBJECT>; 1: crate <OBJECT>; 2: vehicle <OBJECT>;
 *            3: vehicle-model offset <ARRAY of 3 NUMBERS>;
 *            4: vehicle-model forward vector <ARRAY of 3 NUMBERS>;
 *            5: vehicle-model up vector <ARRAY of 3 NUMBERS>.
 * Return Value: BOOLEAN - true when the crate was mounted.
 * Current caller: Waldo_fnc_PhysicalCargoReleaseLocal by server remote execution.
 * Example: [player, crate, truck, [0,-1,1], [0,1,0], [0,0,1]] remoteExecCall ["Waldo_fnc_PhysicalCargoAttachServer", 2];
 */
params [
    ["_carrier", objNull, [objNull]],
    ["_cargo", objNull, [objNull]],
    ["_vehicle", objNull, [objNull]],
    ["_offset", [], [[]]],
    ["_relativeDir", [], [[]]],
    ["_relativeUp", [], [[]]]
];
if (!isServer) exitWith {false};
if !(missionNamespace getVariable ["Waldo_PhysicalCargo_Enable", false]) exitWith {false};
if (isNull _carrier || {isNull _cargo} || {isNull _vehicle}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _carrier}) exitWith {false};
if (_cargo isKindOf "StaticWeapon") exitWith {false};
if !(_cargo getVariable ["Waldo_PhysicalCargo_Eligible", _cargo isKindOf "ReammoBox_F"]) exitWith {false};
if !(_vehicle isKindOf "LandVehicle" || {_vehicle isKindOf "Air"} || {_vehicle isKindOf "Ship"}) exitWith {false};
// A HEMMT's bed can be many metres from its centre. Validate against the actual
// contact point plus the carried object, never the vehicle centre.
if (!alive _cargo || {!alive _vehicle} || {_carrier distance _cargo > 6}
    || {_carrier distance (_vehicle modelToWorld _offset) > 6}) exitWith {false};
if (abs speed _vehicle >= 5) exitWith {false};
if !(_offset isEqualTypeArray [0, 0, 0] && {_relativeDir isEqualTypeArray [0, 0, 0]} && {_relativeUp isEqualTypeArray [0, 0, 0]}) exitWith {false};
if (_cargo in (_vehicle getVariable ["ace_cargo_loaded", []])) exitWith {false};
if (!isNull (_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])) exitWith {false};

private _bounds = boundingBoxReal _vehicle;
_bounds params ["_minimum", "_maximum"];
private _withinVehicle = true;
for "_axis" from 0 to 2 do {
    if ((_offset select _axis) < ((_minimum select _axis) - 2.5)
        || {(_offset select _axis) > ((_maximum select _axis) + 2.5)}) exitWith {
        _withinVehicle = false;
    };
};
if (!_withinVehicle) exitWith {false};
if (vectorMagnitude _relativeDir < 0.5 || {vectorMagnitude _relativeUp < 0.5}) exitWith {false};
_cargo setVariable ["Waldo_PhysicalCargo_PreviousSimulation", simulationEnabled _cargo, true];
// Arma returns [BOOL] here, while setPhysicsCollisionFlag consumes BOOL.
_cargo setVariable ["Waldo_PhysicalCargo_PreviousCollision",
    (getPhysicsCollisionFlag _cargo) param [0, true], true];
_cargo enableSimulationGlobal false;
_cargo setVariable ["Waldo_PhysicalCargo_Mode", "CARGO", true];
_cargo setVariable ["Waldo_PhysicalCargo_AttachedVehicle", _vehicle, true];
[_cargo, _vehicle, true, _offset, _relativeDir, _relativeUp] call Waldo_fnc_PhysicalCargoSeatsServer;
private _mounts = +(missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]);
_mounts pushBack [_cargo, _vehicle, _offset, _relativeDir, _relativeUp];
missionNamespace setVariable ["Waldo_PhysicalCargo_Mounts", _mounts, true];
[_cargo, _vehicle, _offset, _relativeDir, _relativeUp]
    remoteExec ["Waldo_fnc_PhysicalCargoApplyLocal", 0];
[_cargo, _vehicle, _offset, _relativeDir, _relativeUp] spawn {
    params ["_cargo", "_vehicle", "_offset", "_relativeDir", "_relativeUp"];
    sleep 1.5;
    if (!isNull _cargo && {(_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull]) isEqualTo _vehicle}
        && {attachedTo _cargo isNotEqualTo _vehicle}) then {
        // If object ownership migrated between the initial dispatch and execution, try its
        // current owner once more. The owner function is idempotent for this exact mount.
        [_cargo, _vehicle, _offset, _relativeDir, _relativeUp]
            remoteExec ["Waldo_fnc_PhysicalCargoApplyLocal", 0];
    };
    sleep 4;
    if (!isNull _cargo && {(_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull]) isEqualTo _vehicle}
        && {attachedTo _cargo isNotEqualTo _vehicle}) then {
        [_cargo] call Waldo_fnc_PhysicalCargoClearServer;
        diag_log format ["[WMP PHYSICAL CARGO] Mount acknowledgement failed for %1; crate simulation restored.", typeOf _cargo];
    };
};
diag_log format ["[WMP PHYSICAL CARGO] Mounted %1 on %2 at %3.", typeOf _cargo,
    typeOf _vehicle, _offset];
true
