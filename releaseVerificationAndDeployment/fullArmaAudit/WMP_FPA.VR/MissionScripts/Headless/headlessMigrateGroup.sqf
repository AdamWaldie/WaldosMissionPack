/*
 * Author: WaldoTheWarfighter
 * The single funnel for every setGroupOwner call this rework performs. No other WMP script may call
 * setGroupOwner directly - every migration routes through here so Waldo_Headless_ManagedGroups stays
 * authoritative and diagnostics never drifts from the truth, unlike the legacy
 * MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf's self-contained bolt-on arrays.
 *
 * Reapplication of locality-sensitive AI/waypoint/vehicle handlers is deliberately not reimplemented
 * here. WMP's existing "current owner executes" redispatch (Waldo_fnc_DynamicAASetGroupState, the
 * whole Logistics\TransportServices folder, Zen_convoyModule.sqf) and per-unit engine "Local"
 * event-handler adoption (AI rebalance, improved helicopter landing) already react correctly the
 * moment setGroupOwner changes who is local - this function's only job is to make that change
 * safely and record it.
 *
 * Locality and authority:
 * Server-only. Refuses a null/empty group. A target owner that is not a currently connected headless
 * client falls back to the server (owner id 2), so a stale or disconnected id can never strand a
 * group off-authority.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: targetOwner <NUMBER> - a connected headless client's network owner id; anything else (including
 *    the server's own id, 2) returns the group to the server.
 *
 * Return Value:
 * Boolean - true when the group was (re)assigned; false on failure (recorded in
 * Waldo_Headless_FailedTransfers).
 *
 * Example:
 * [_group, _hcOwnerId] call Waldo_fnc_HeadlessMigrateGroup;
 * Result: _group becomes local to the headless client with that owner id, or to the server if
 * _hcOwnerId is no longer connected.
 *
 * Current callers: Waldo_fnc_HeadlessRebalance, Waldo_fnc_HeadlessReassignOnDisconnect.
 */

params [["_group", grpNull, [grpNull]], ["_targetOwner", 2, [0]]];
if !(isServer) exitWith {false};
if (isNull _group || {count units _group == 0}) exitWith {false};

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

private _ok = _group setGroupOwner _finalOwner;
if !(_ok) exitWith {
    diag_log format ["[WMP HEADLESS] setGroupOwner failed for group=%1 target=%2.", _group, _finalOwner];
    ["setGroupOwner-failed"] call _recordFailure;
    false
};

private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
private _idx = _managed findIf {(_x select 0) == _group};
private _record = [_group, if (_finalOwner == 2) then {"SERVER"} else {_finalOwner}];
if (_idx >= 0) then {_managed set [_idx, _record];} else {_managed pushBack _record;};
missionNamespace setVariable ["Waldo_Headless_ManagedGroups", _managed, true];

diag_log format ["[WMP HEADLESS] Group %1 migrated to owner=%2.", _group, _record select 1];
true
