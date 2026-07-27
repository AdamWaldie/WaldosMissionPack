/*
 * Author: WaldoTheWarfighter
 * Removes a depot-spawned vehicle together with its crew, executing the deletion on
 * the machine that owns the vehicle. Virtual Vehicle Depot vehicles (and their crew,
 * including engine-managed UAV AI) are created with createVehicle / createVehicleCrew
 * on whichever client pressed spawn, so they are owned by that client. A deleteVehicle
 * or deleteVehicleCrew issued from any other machine silently no-ops on the remote
 * object, which is the dominant cause of UAV crew being left orphaned on removal. By
 * routing the whole deletion to owner _veh, the crew and hull are torn down where they
 * are local. (A UAV with a player currently connected via a terminal remains an engine
 * edge case and is not guaranteed by this helper.)
 *
 * Arguments:
 * 0: _veh <OBJECT> - the vehicle to remove (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_vehicle] call Waldo_fnc_VVDPurgeVehicle;
 */

params [["_veh", objNull]];

if (isNull _veh) exitWith {};

// Hand off to the owning machine when the vehicle is not local here, so the crew and
// hull deletions below run where the objects (and UAV AI agents) actually live.
if (!local _veh) exitWith {
    [_veh] remoteExec ["Waldo_fnc_VVDPurgeVehicle", owner _veh];
};

// deleteVehicleCrew is the sanctioned removal for AI/UAV crew; delete crew before the hull.
{ _veh deleteVehicleCrew _x } forEach (crew _veh);

// Strip attached decorations/objects, but never the depot's own game logic.
{
    if !("Logic" in (_x call BIS_fnc_objectType)) then { deleteVehicle _x };
} forEach (attachedObjects _veh);

deleteVehicle _veh;
