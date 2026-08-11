/*
 * Author: WaldoTheWarfighter
 * Returns normalized headless-client diagnostics: connected clients, assigned-group counts, excluded
 * groups (with reasons, from the last rebalance pass), failed transfers, and ownership consistency
 * (registry vs. actual groupOwner). Waldo_Headless_ManagedGroups only ever holds groups currently
 * assigned to a connected client and is pruned of dead groups on every rebalance pass, so a
 * non-empty "orphaned" count here should only ever be transient (between a client disconnecting and
 * the following rebalance pass reconciling it) rather than a structural leak.
 *
 * Reports a single DISABLED check while Waldo_Headless_Enable is false, matching the rest of WMP's
 * optional-feature diagnostics convention.
 *
 * Locality and authority: read-only, server-only (headless registries are server state).
 *
 * Arguments: None.
 * Return Value: HashMap - the Waldo_fnc_DiagnosticFeatureReport shape for area "headless".
 * Example: [] call Waldo_fnc_HeadlessGetDiagnostics;
 * Current caller: Waldo_fnc_RunDiagnostics.
 */

if !(missionNamespace getVariable ["Waldo_Headless_Enable", false]) exitWith {
    ["headless", [["headless", "headless-enable", "DISABLED", "Waldo_Headless_Enable is false in MissionConfig\\headlessConfig.sqf"]]] call Waldo_fnc_DiagnosticFeatureReport
};

private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
private _excluded = missionNamespace getVariable ["Waldo_Headless_ExcludedGroups", []];
private _failed = missionNamespace getVariable ["Waldo_Headless_FailedTransfers", []];
private _queue = missionNamespace getVariable ["Waldo_Headless_MigrationQueue", []];
private _workerActive = missionNamespace getVariable ["Waldo_Headless_MigrationWorkerActive", false];
private _clientOwnerIds = _clients apply {_x select 0};

private _assigned = _managed select {(_x select 1) isEqualType 0 && {(_x select 1) in _clientOwnerIds}};
private _mismatched = _assigned select {isNull (_x select 0) || {groupOwner (_x select 0) != (_x select 1)}};
private _orphaned = _managed select {(_x select 1) isEqualType 0 && {!((_x select 1) in _clientOwnerIds)}};

private _failedDetail = format ["failed=%1", count _failed];
if (count _failed > 0) then {_failedDetail = [_failedDetail, "Check the RPT for [WMP HEADLESS] entries naming the failed group(s) and reason; a group can be pinned server-side with _group setVariable [""Waldo_Headless_ExcludeGroup"", true, true] if it should never migrate."] call Waldo_fnc_DiagnosticFoldHint;};
private _consistencyDetail = format ["mismatched=%1 orphaned=%2", count _mismatched, count _orphaned];
if (count _mismatched > 0 || {count _orphaned > 0}) then {_consistencyDetail = [_consistencyDetail, "The headless registry and actual group ownership have drifted apart - this should self-correct on the next rebalance pass; if it persists, check the RPT for [WMP HEADLESS] errors from Waldo_fnc_HeadlessMigrateGroup."] call Waldo_fnc_DiagnosticFoldHint;};
private _checks = [
    ["headless", "headless-clients", if (count _clients > 0) then {"ACTIVE"} else {"UNCONFIGURED"}, format ["connected=%1", count _clients]],
    ["headless", "headless-managed-groups", if (count _assigned > 0) then {"ACTIVE"} else {"LOADED"}, format ["assigned=%1", count _assigned]],
    ["headless", "headless-excluded-groups", "LOADED", format ["excluded=%1 (reasons in Waldo_Headless_ExcludedGroups / RPT)", count _excluded]],
    ["headless", "headless-failed-transfers", if (count _failed > 0) then {"ERROR"} else {"LOADED"}, _failedDetail],
    ["headless", "headless-ownership-consistency", if (count _mismatched > 0 || {count _orphaned > 0}) then {"ERROR"} else {"LOADED"}, _consistencyDetail],
    ["headless", "headless-migration-queue", if (count _queue > 0) then {"ACTIVE"} else {"LOADED"}, format ["queued=%1 workerActive=%2 startDelay=%3 minGroupAge=%4 pace=%5", count _queue, _workerActive, missionNamespace getVariable ["Waldo_Headless_StartDelaySeconds", 30], missionNamespace getVariable ["Waldo_Headless_MinGroupAgeSeconds", 10], missionNamespace getVariable ["Waldo_Headless_MigrationPaceSeconds", 3]]]
];

["headless", _checks] call Waldo_fnc_DiagnosticFeatureReport
