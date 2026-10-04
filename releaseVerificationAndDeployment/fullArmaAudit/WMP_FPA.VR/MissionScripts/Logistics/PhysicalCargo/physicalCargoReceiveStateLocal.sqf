/*
 * Author: WaldoTheWarfighter
 * Purpose: Applies a server-approved complete physical-mount snapshot for JIP.
 * Locality / Authority: Interface or headless client; only accepts a server-dispatched response.
 * Repeat / JIP: Ignores snapshots older than locally observed mount deltas.
 * Arguments: mount rows <ARRAY>, server revision <NUMBER> (0). Return Value: <BOOL> handled.
 * Current caller: Waldo_fnc_PhysicalCargoRequestStateServer.
 * Example: [mountRows, 4] remoteExecCall ["Waldo_fnc_PhysicalCargoReceiveStateLocal", player];
 * Result: The receiving client reconciles mounts at or newer than its observed revision.
 */
params [["_rows", [], [[]]], ["_revision", 0, [0]]];
if ((!hasInterface && {isServer}) || {isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}}) exitWith {false};
if (_revision < (missionNamespace getVariable ["Waldo_PhysicalCargo_LocalRevision", 0])) exitWith {false};
missionNamespace setVariable ["Waldo_PhysicalCargo_LocalRevision", _revision];
missionNamespace setVariable ["Waldo_PhysicalCargo_Mounts", _rows];
{(_x + [_revision]) call Waldo_fnc_PhysicalCargoApplyLocal} forEach _rows;
true
