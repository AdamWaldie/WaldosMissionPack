/*
 * Author: WaldoTheWarfighter
 * Curator/mission-script convenience wrapper: runs one headless-client rebalance pass immediately,
 * bypassing nothing (still goes through the normal Waldo_fnc_HeadlessRebalance eligibility rules,
 * start delay and settle time - this only skips waiting for the next automatic trigger, which is
 * otherwise only registration or disconnect events). Useful right after enabling the feature mid-test,
 * clearing a group's Waldo_Headless_ExcludeGroup flag, or after manually returning a group to the
 * server, when a mission maker doesn't want to wait for the next natural rebalance trigger.
 *
 * Server-authoritative; self-forwards to the server when called from a client, matching
 * Waldo_fnc_Jammer and the other public registration-style APIs.
 *
 * Arguments: None.
 *
 * Return Value:
 * Number - count of groups newly queued for migration by this pass (see Waldo_fnc_HeadlessRebalance).
 *
 * Example:
 * [] call Waldo_fnc_HeadlessForceRebalance;
 *
 * Current callers: Waldo_fnc_ZenHeadlessControl (the "Headless Client - Force Rebalance Now" module),
 * mission scripts.
 */

if !(isServer) exitWith {[] remoteExecCall ["Waldo_fnc_HeadlessForceRebalance", 2]; 0};

if !(missionNamespace getVariable ["Waldo_Headless_Enable", false]) exitWith {
    ["FORCE_REBALANCE", "Skipped: Waldo_Headless_Enable is false."] call Waldo_fnc_HeadlessDebugLog;
    0
};

private _queuedNow = [] call Waldo_fnc_HeadlessRebalance;
private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
[createHashMapFromArray [
    ["title", "HEADLESS CLIENT"],
    ["message", format ["Manual rebalance: %1 group(s) newly queued, %2 headless client(s) connected.", _queuedNow, count _clients]],
    ["state", "INFO"], ["duration", 8], ["placement", "TOP"], ["channel", "HEADLESS_DEBUG"],
    ["source", "ZEUS"], ["audience", "UNITS"],
    ["units", (allCurators apply {getAssignedCuratorUnit _x}) select {!isNull _x}]
]] call Waldo_fnc_NotificationBroadcast;
_queuedNow
