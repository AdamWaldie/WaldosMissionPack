/*
 * Author: WaldoTheWarfighter
 * Applies one changed HC ownership-debug snapshot to authoritative public mission state. This
 * isolates the network broadcast from the low-frequency observer loop, so publication happens once
 * per real ownership transition rather than being embedded in recurring work.
 *
 * Locality and authority:
 * Server-only and repeat-safe. Equal snapshots are ignored. A changed snapshot is broadcast once
 * through missionNamespace, making the latest ownership map available to current and JIP curators.
 * Repeat/JIP: Equal snapshots return false without broadcast. The latest changed snapshot is
 * public mission state for current and joining curators.
 *
 * Arguments:
 * 0: ownership snapshot <ARRAY> - rows shaped `[group, network owner id]` (default []).
 *
 * Return Value: Boolean - true when a changed snapshot was published; false otherwise.
 * Current caller: Waldo_fnc_HeadlessPublishDebugSnapshot's server observer.
 * Example: [[_group, groupOwner _group]] call Waldo_fnc_HeadlessSetDebugSnapshot;
 * Result: Returns true and publishes a changed snapshot, or false for an equal snapshot or
 * a call outside the server.
 */
params [["_snapshot", [], [[]]]];
if !(isServer) exitWith {false};
if (_snapshot isEqualTo (missionNamespace getVariable ["Waldo_Headless_GroupOwnerSnapshot", []])) exitWith {false};
missionNamespace setVariable ["Waldo_Headless_GroupOwnerSnapshot", _snapshot, true];
true
