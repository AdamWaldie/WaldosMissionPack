/*
 * Author: WaldoTheWarfighter
 * Drains Waldo_Headless_MigrationQueue one group at a time with a short pause between each
 * setGroupOwner call (Waldo_Headless_MigrationPaceSeconds, default 3s). Migrating many groups
 * back-to-back in the same frame is a known source of a server hitch on a busy mission - the same
 * reason established headless-client tooling paces its own transfers rather than moving everything
 * the instant it becomes eligible.
 *
 * Locality and authority:
 * Server-only. Spawned by Waldo_fnc_HeadlessRebalance; guarded by
 * Waldo_Headless_MigrationWorkerActive so at most one worker drains the queue at a time - safe to
 * (re)spawn repeatedly. A queued entry for a group that is no longer eligible by the time its turn
 * comes up (dead, already moved, excluded since being queued) is simply a no-op inside
 * Waldo_fnc_HeadlessMigrateGroup's own guards.
 *
 * Arguments: None.
 * Return Value: Nothing.
 *
 * Example:
 * [] spawn Waldo_fnc_HeadlessMigrationWorker;
 *
 * Current caller: Waldo_fnc_HeadlessRebalance.
 */

if !(isServer) exitWith {};
if (missionNamespace getVariable ["Waldo_Headless_MigrationWorkerActive", false]) exitWith {};
missionNamespace setVariable ["Waldo_Headless_MigrationWorkerActive", true];

private _pace = (missionNamespace getVariable ["Waldo_Headless_MigrationPaceSeconds", 3]) max 0;
private _queue = missionNamespace getVariable ["Waldo_Headless_MigrationQueue", []];
while {count _queue > 0} do {
    private _entry = _queue deleteAt 0;
    missionNamespace setVariable ["Waldo_Headless_MigrationQueue", _queue];
    _entry params [["_group", grpNull, [grpNull]], ["_targetOwner", 2, [0]]];
    [_group, _targetOwner] call Waldo_fnc_HeadlessMigrateGroup;
    sleep _pace;
    _queue = missionNamespace getVariable ["Waldo_Headless_MigrationQueue", []];
};

missionNamespace setVariable ["Waldo_Headless_MigrationWorkerActive", false];
