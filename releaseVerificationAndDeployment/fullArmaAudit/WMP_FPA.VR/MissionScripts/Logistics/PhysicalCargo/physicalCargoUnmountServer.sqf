/*
 * Author: WaldoTheWarfighter
 * Purpose: Releases a visible physical mount to a checked nearby ground position.
 * Locality / Authority: Server validates the requesting player's owner and proximity.
 * Repeat / JIP: No-op when already unmounted; clears server registry and client physics state.
 * Arguments: player <OBJECT>, mounted object <OBJECT>. Return Value: <BOOL> released.
 * Current caller: mounted-object ACE Unmount action; public script call from server.
 * Example: [player, crate] remoteExecCall ["Waldo_fnc_PhysicalCargoUnmountServer", 2];
 */
params [["_player", objNull, [objNull]], ["_cargo", objNull, [objNull]]];
if (!isServer || {isNull _cargo}) exitWith {false};
if (isRemoteExecuted && {isNull _player}) exitWith {false};
private _vehicle = _cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull];
if (isNull _vehicle) exitWith {false};
if (!isNull _player && {!alive _player || {_player distance _cargo > 6}}) exitWith {false};
if (!isNull _player && {isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}}) exitWith {false};
if ({alive _x} count (crew _cargo) > 0) exitWith {false};
private _bounds = boundingBoxReal _vehicle;
private _back = abs ((_bounds select 0) select 1);
private _basis = _vehicle modelToWorld [0, -(_back + 2), 0];
private _clear = _basis findEmptyPosition [0, 6, typeOf _cargo];
if (_clear isEqualTo []) exitWith {false};
private _cargoBounds = boundingBoxReal _cargo;
_clear set [2, (_clear select 2) + (0.1 - ((_cargoBounds select 0) select 2)) max 0.1];
[_cargo, _player, _clear] call Waldo_fnc_PhysicalCargoClearServer
