/*
 * Author: WaldoTheWarfighter
 * Returns normalized headless-client diagnostics: connected clients, assigned-group counts, excluded
 * groups (with reasons, from the last rebalance pass), failed transfers, and ownership consistency
 * (registry vs. actual groupOwner, and orphaned managed entries pointing at a disconnected client
 * that a rebalance pass has not yet reconciled).
 *
 * Locality and authority: read-only, server-only (headless registries are server state).
 *
 * Arguments: None.
 * Return Value: HashMap - the Waldo_fnc_DiagnosticFeatureReport shape for area "headless".
 * Example: [] call Waldo_fnc_HeadlessGetDiagnostics;
 * Current caller: Waldo_fnc_RunDiagnostics.
 */

private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
private _excluded = missionNamespace getVariable ["Waldo_Headless_ExcludedGroups", []];
private _failed = missionNamespace getVariable ["Waldo_Headless_FailedTransfers", []];
private _clientOwnerIds = _clients apply {_x select 0};

private _assigned = _managed select {(_x select 1) isEqualType 0 && {(_x select 1) in _clientOwnerIds}};
private _mismatched = _assigned select {isNull (_x select 0) || {groupOwner (_x select 0) != (_x select 1)}};
private _orphaned = _managed select {(_x select 1) isEqualType 0 && {!((_x select 1) in _clientOwnerIds)}};

private _checks = [
    ["headless", "headless-clients", if (count _clients > 0) then {"ACTIVE"} else {"UNCONFIGURED"}, format ["connected=%1", count _clients]],
    ["headless", "headless-managed-groups", if (count _assigned > 0) then {"ACTIVE"} else {"LOADED"}, format ["assigned=%1", count _assigned]],
    ["headless", "headless-excluded-groups", "LOADED", format ["excluded=%1 (reasons in Waldo_Headless_ExcludedGroups / RPT)", count _excluded]],
    ["headless", "headless-failed-transfers", if (count _failed > 0) then {"ERROR"} else {"LOADED"}, format ["failed=%1", count _failed]],
    ["headless", "headless-ownership-consistency", if (count _mismatched > 0 || {count _orphaned > 0}) then {"ERROR"} else {"LOADED"}, format ["mismatched=%1 orphaned=%2", count _mismatched, count _orphaned]]
];

["headless", _checks] call Waldo_fnc_DiagnosticFeatureReport
