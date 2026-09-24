/*
 * Author: WaldoTheWarfighter
 * Remove a mounted object through a server script when it needs a checked ground
 * position behind the vehicle. Players normally use ACE Carry to take cargo off.
 *
 * Locality and authority: Call on the server. A remote request is accepted only
 * from the named player's machine while that player is near the cargo.
 * Repeat and JIP: An unmounted object returns false. A successful removal clears
 * the public mount, restores physics on the object owner and releases WMP seat locks.
 *
 * Arguments:
 * 0: player <OBJECT> - requesting player; objNull for a server script.
 * 1: cargo <OBJECT> - object currently mounted on a vehicle.
 * Return Value: <BOOL> - true when a clear position was found and removal started.
 * Example: In a server script:
 * [objNull, myCrate] call Waldo_fnc_PhysicalCargoUnmountServer;
 * Result: WMP moves myCrate to a clear position behind its carrier. If no safe
 * position exists, it stays mounted.
 * Current callers: public server-script API; ordinary players use ACE Carry.
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
