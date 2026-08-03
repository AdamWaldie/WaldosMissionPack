/*
 * Author: WaldoTheWarfighter
 * Finalises a server-created curator utility object for smooth Zeus manipulation. Configuration is
 * completed on the server first, then ownership is transferred to the requesting curator and the
 * object is added to every curator. Simulation state is applied explicitly: ordinary utility
 * objects are enabled, while optional freezing remains available only for genuinely static
 * interaction props. Feature state continues to follow the object's live networked transform.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: curator network owner <NUMBER>
 * 2: freeze simulation <BOOL> (default false)
 * 3: include crew <BOOL> (default false)
 *
 * Return Value: BOOL - true when a live object was finalised on the server.
 *
 * Example: [_jammer, owner _curatorPlayer, false] call Waldo_fnc_ZenAssignObjectOwnerServer;
 * Current callers: ZEN jammer, crate, loadout-save, field-resupply and paradrop boarding creation.
 */
params [
    ["_object", objNull, [objNull]],
    ["_ownerId", 2, [0]],
    ["_freezeSimulation", false, [true]],
    ["_includeCrew", false, [true]]
];
if (!isServer || {isNull _object}) exitWith {false};
_object enableSimulationGlobal (!_freezeSimulation);
{_x addCuratorEditableObjects [[_object], _includeCrew]} forEach allCurators;
if (_ownerId > 2) then {_object setOwner _ownerId};
true
