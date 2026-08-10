/*
 * Author: WaldoTheWarfighter
 * Distributes eligible, currently server-local AI groups across connected headless clients with a
 * simple load-following pass, so each headless client ends up with a roughly even AI group count.
 * This is the scheduling brain of the headless-client rework; the actual reassignment always routes
 * through Waldo_fnc_HeadlessMigrateGroup, never setGroupOwner directly.
 *
 * Eligibility excludes, and records to Waldo_Headless_ExcludedGroups with a reason:
 * - empty groups;
 * - any group with a human-player leader or member (Waldo_fnc_HeadlessMigrateGroup only ever moves
 *   AI, never a player's own group);
 * - a group with the group variable Waldo_Headless_ExcludeGroup set true - the opt-out convention
 *   any WMP subsystem can set on groups it owns and wants pinned to the server, without this feature
 *   needing to know that subsystem by name;
 * - sideLogic groups (curator helper/ZEN module logic);
 * - any group currently crewing a registered Airborne Gunship aircraft (Waldo_Gunship_Registry) -
 *   gunship crew is documented as staying server-owned and its control handoff is unrelated to
 *   group locality, so migrating its crew group is out of scope here;
 * - a group not currently local to the server (already on a headless client, or otherwise not this
 *   machine's to move);
 * - a group already recorded as assigned to a still-connected headless client in
 *   Waldo_Headless_ManagedGroups.
 *
 * Locality and authority:
 * Server-only. Safe to call repeatedly - a group already assigned to a connected headless client is
 * left alone; only newly eligible or newly disconnected-orphaned groups move.
 *
 * Arguments: None.
 *
 * Return Value:
 * Number - count of groups migrated by this pass.
 *
 * Example:
 * [] call Waldo_fnc_HeadlessRebalance;
 *
 * Current callers: Waldo_fnc_HeadlessRegisterClient, Waldo_fnc_HeadlessReassignOnDisconnect.
 */

if !(isServer) exitWith {0};

private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
if (_clients isEqualTo []) exitWith {0};

private _clientOwnerIds = _clients apply {_x select 0};
private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];

private _gunshipCrewGroups = [];
{
    private _aircraft = _x getOrDefault ["aircraft", objNull];
    if !(isNull _aircraft) then {_gunshipCrewGroups pushBackUnique (group _aircraft);};
} forEach (values (missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap]));

private _excluded = [];
private _eligible = [];
{
    private _group = _x;
    private _reason = "";
    if (count units _group == 0) then {
        _reason = "empty";
    } else {
        if ((units _group) findIf {isPlayer _x} >= 0) then {
            _reason = "player-led";
        } else {
            if (_group getVariable ["Waldo_Headless_ExcludeGroup", false]) then {
                _reason = "opted-out";
            } else {
                if (side _group == sideLogic) then {
                    _reason = "curator-logic";
                } else {
                    if (_group in _gunshipCrewGroups) then {
                        _reason = "gunship-crew";
                    } else {
                        if !(local _group) then {
                            _reason = "not-server-local";
                        } else {
                            private _managedIdx = _managed findIf {
                                (_x select 0) == _group
                                && {(_x select 1) isEqualType 0}
                                && {(_x select 1) in _clientOwnerIds}
                            };
                            if (_managedIdx >= 0) then {_reason = "already-managed";};
                        };
                    };
                };
            };
        };
    };
    if (_reason == "") then {_eligible pushBack _group;} else {_excluded pushBack [_group, _reason];};
} forEach allGroups;
missionNamespace setVariable ["Waldo_Headless_ExcludedGroups", _excluded];

if (_eligible isEqualTo []) exitWith {0};

private _loadByOwner = createHashMapFromArray (_clientOwnerIds apply {[_x, 0]});
{
    _x params ["_mgGroup", "_mgOwner"];
    if (_mgOwner in _clientOwnerIds) then {_loadByOwner set [_mgOwner, (_loadByOwner get _mgOwner) + 1];};
} forEach _managed;

private _migrated = 0;
{
    private _group = _x;
    private _bestOwner = -1;
    private _bestLoad = 1e9;
    {
        private _load = _loadByOwner get _x;
        if (_load < _bestLoad) then {_bestLoad = _load; _bestOwner = _x;};
    } forEach _clientOwnerIds;
    if (_bestOwner > 0) then {
        if ([_group, _bestOwner] call Waldo_fnc_HeadlessMigrateGroup) then {
            _loadByOwner set [_bestOwner, _bestLoad + 1];
            _migrated = _migrated + 1;
        };
    };
} forEach _eligible;

diag_log format ["[WMP HEADLESS] Rebalance pass: eligible=%1 excluded=%2 migrated=%3 clients=%4.", count _eligible, count _excluded, _migrated, count _clients];
_migrated
