/*
 * Author: WaldoTheWarfighter
 * The single funnel for every setGroupOwner call this rework performs. No other WMP script may call
 * setGroupOwner directly - every migration routes through here so Waldo_Headless_ManagedGroups stays
 * authoritative and diagnostics never drifts from the truth, unlike the legacy
 * MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf's self-contained bolt-on arrays.
 *
 * Waldo_Headless_ManagedGroups only ever holds groups CURRENTLY assigned to a connected headless
 * client - a group returning to the server (or found dead/empty) is removed from the registry
 * entirely rather than kept as a stale "SERVER" record. This keeps the array bounded by "groups
 * actually on a headless client right now" instead of growing for the rest of the mission, and
 * means a later ownership-consistency check never has to special-case a dead entry.
 *
 * Reapplication of locality-sensitive AI/waypoint/vehicle handlers is deliberately not reimplemented
 * here. WMP's existing "current owner executes" redispatch (Waldo_fnc_DynamicAASetGroupState, the
 * whole Logistics\TransportServices folder, Zen_convoyModule.sqf) and per-unit engine "Local"
 * event-handler adoption (AI rebalance, improved helicopter landing) already react correctly the
 * moment setGroupOwner changes who is local. A third-party AI mod (VCOM AI, LAMBS, ASR AI3, ...)
 * that installs its own per-unit behaviour on a one-shot unit/group init event rather than
 * continuously re-checking locality has no such adoption path of its own - the legacy
 * WerthlesHeadless.sqf's best-known failure mode was exactly this class of mod going silently
 * unresponsive after a migration it never found out about. This function cannot fix a third-party
 * mod's own locality handling, so it broadcasts Waldo_Headless_GroupMigrated (a CBA global event,
 * params [group, previousOwner, newOwner]) after every successful move specifically so a mission's
 * own compatibility layer can listen and re-trigger that mod's setup function on whichever machine
 * is now local. See wiki/Headless-Client-Support.md for a worked example.
 *
 * Locality and authority:
 * Server-only. Refuses a null/empty group (and prunes any stale registry record for it - a group
 * that died while assigned to a headless client is cleaned up the same way a returned one is). A
 * target owner that is not a currently connected headless client falls back to the server (owner id
 * 2), so a stale or disconnected id can never strand a group off-authority.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: targetOwner <NUMBER> - a connected headless client's network owner id; anything else (including
 *    the server's own id, 2) returns the group to the server.
 *
 * Return Value:
 * Boolean - true when the group was (re)assigned; false on failure (recorded in
 * Waldo_Headless_FailedTransfers) or when the group was null/empty (nothing to migrate).
 *
 * Example:
 * [_group, _hcOwnerId] call Waldo_fnc_HeadlessMigrateGroup;
 * Result: _group becomes local to the headless client with that owner id, or to the server if
 * _hcOwnerId is no longer connected.
 *
 * Current callers: Waldo_fnc_HeadlessMigrationWorker (draining Waldo_fnc_HeadlessRebalance's
 * queue), Waldo_fnc_HeadlessReassignOnDisconnect (returning a disconnected client's groups
 * immediately, without going through the paced queue).
 */

params [["_group", grpNull, [grpNull]], ["_targetOwner", 2, [0]]];
if !(isServer) exitWith {false};

private _removeRegistryEntry = {
    private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
    private _idx = _managed findIf {(_x select 0) == _group};
    if (_idx >= 0) then {
        _managed deleteAt _idx;
        missionNamespace setVariable ["Waldo_Headless_ManagedGroups", _managed, true];
    };
};

if (isNull _group || {count units _group == 0}) exitWith {
    [] call _removeRegistryEntry;
    false
};

private _recordFailure = {
    params ["_reason"];
    private _failed = missionNamespace getVariable ["Waldo_Headless_FailedTransfers", []];
    _failed pushBack [_group, _targetOwner, serverTime, _reason];
    missionNamespace setVariable ["Waldo_Headless_FailedTransfers", _failed];
};

private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
private _clientOwnerIds = _clients apply {_x select 0};
private _isHcTarget = _targetOwner in _clientOwnerIds;
private _finalOwner = if (_isHcTarget) then {_targetOwner} else {2};

private _previousOwner = groupOwner _group;
private _ok = _group setGroupOwner _finalOwner;
if !(_ok) exitWith {
    diag_log format ["[WMP HEADLESS] setGroupOwner failed for group=%1 target=%2.", _group, _finalOwner];
    ["setGroupOwner-failed"] call _recordFailure;
    false
};

if (_finalOwner == 2) then {
    [] call _removeRegistryEntry;
} else {
    private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
    private _idx = _managed findIf {(_x select 0) == _group};
    private _record = [_group, _finalOwner];
    if (_idx >= 0) then {_managed set [_idx, _record];} else {_managed pushBack _record;};
    missionNamespace setVariable ["Waldo_Headless_ManagedGroups", _managed, true];
};

["Waldo_Headless_GroupMigrated", [_group, _previousOwner, _finalOwner]] call CBA_fnc_globalEvent;
diag_log format ["[WMP HEADLESS] Group %1 migrated from owner=%2 to owner=%3.", _group, _previousOwner, _finalOwner];
true
