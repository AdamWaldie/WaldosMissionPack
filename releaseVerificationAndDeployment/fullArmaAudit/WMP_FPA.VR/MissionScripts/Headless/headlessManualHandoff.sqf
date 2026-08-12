/*
 * Author: WaldoTheWarfighter
 * Curator-driven manual override: immediately hands a specific AI group off to a specific
 * destination, bypassing Waldo_fnc_HeadlessRebalance's own eligibility scan, start delay and settle
 * time (a mission maker actively directing traffic during a test doesn't want to wait for those). It
 * still refuses a null/empty group and, matching the automatic system's own invariant, refuses any
 * group with a human-player leader or member - this rework only ever moves AI, manual override
 * included. It still routes exclusively through Waldo_fnc_HeadlessMigrateGroup, the single funnel for
 * every setGroupOwner call this rework performs, so Waldo_Headless_ManagedGroups and diagnostics never
 * drift from the truth regardless of whether a move was automatic or manual.
 *
 * Server-authoritative; self-forwards to the server when called from a client, matching
 * Waldo_fnc_Jammer and the other public registration-style APIs.
 *
 * Arguments:
 * 0: group <GROUP> - the AI group to hand off.
 * 1: destination <STRING or NUMBER> - "AUTO" (send to whichever connected headless client currently
 *    has the fewest managed groups), "SERVER" (return it to the server), or an explicit connected
 *    headless client owner id.
 *
 * Return Value:
 * Boolean - true when the handoff was applied.
 *
 * Example:
 * [cursorObject call {group (cursorObject)}, "AUTO"] call Waldo_fnc_HeadlessManualHandoff;
 * [_group, "SERVER"] call Waldo_fnc_HeadlessManualHandoff;
 *
 * Current callers: Waldo_fnc_ZenHeadlessControl (the "Headless Client - Manual Handoff" module),
 * mission scripts.
 */

params [["_group", grpNull, [grpNull]], ["_destination", "SERVER", ["", 0]]];
if !(isServer) exitWith {[_group, _destination] remoteExecCall ["Waldo_fnc_HeadlessManualHandoff", 2]; false};

if (isNull _group || {count units _group == 0}) exitWith {false};
if ((units _group) findIf {isPlayer _x} >= 0) exitWith {
    ["MANUAL_HANDOFF", format ["Refused group=%1: has a human player leader/member.", _group]] call Waldo_fnc_HeadlessDebugLog;
    false
};

private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
private _clientOwnerIds = _clients apply {_x select 0};

private _targetOwner = 2;
if (_destination isEqualType 0) then {
    _targetOwner = if (_destination in _clientOwnerIds) then {_destination} else {2};
} else {
    if (toUpperANSI _destination == "AUTO" && {count _clientOwnerIds > 0}) then {
        private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
        private _loadByOwner = createHashMapFromArray (_clientOwnerIds apply {[_x, 0]});
        {
            _x params ["", "_mgOwner"];
            if (_mgOwner in _clientOwnerIds) then {_loadByOwner set [_mgOwner, (_loadByOwner get _mgOwner) + 1];};
        } forEach _managed;
        private _bestOwner = -1;
        private _bestLoad = 1e9;
        {
            private _load = _loadByOwner get _x;
            if (_load < _bestLoad) then {_bestLoad = _load; _bestOwner = _x;};
        } forEach _clientOwnerIds;
        _targetOwner = if (_bestOwner > 0) then {_bestOwner} else {2};
    };
    // toUpperANSI _destination == "SERVER", or AUTO with no connected clients, both fall through to 2.
};

private _ok = [_group, _targetOwner] call Waldo_fnc_HeadlessMigrateGroup;
["MANUAL_HANDOFF", format [
    "group=%1 unitCount=%2 requestedDestination=%3 resolvedOwner=%4 ok=%5",
    _group, count units _group, _destination, _targetOwner, _ok
]] call Waldo_fnc_HeadlessDebugLog;
_ok
