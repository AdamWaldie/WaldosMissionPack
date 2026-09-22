/*
 * Author: WaldoTheWarfighter
 * Purpose: Applies a server-approved complete physical-mount snapshot for JIP.
 * Locality / Authority: Interface client; only accepts a server-dispatched response.
 * Repeat / JIP: Reapplying a current mount is idempotent.
 * Arguments: mount rows <ARRAY>. Return Value: <BOOL> handled.
 * Current caller: Waldo_fnc_PhysicalCargoRequestStateServer.
 * Example: [mountRows] remoteExecCall ["Waldo_fnc_PhysicalCargoReceiveStateLocal", player];
 */
params [["_rows", [], [[]]]];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}}) exitWith {false};
missionNamespace setVariable ["Waldo_PhysicalCargo_Mounts", _rows];
{_x call Waldo_fnc_PhysicalCargoApplyLocal} forEach _rows;
true
