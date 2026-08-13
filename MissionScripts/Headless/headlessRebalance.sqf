/*
 * Author: WaldoTheWarfighter
 * Distributes eligible, currently server-local AI groups across connected headless clients with a
 * simple load-following pass, so each headless client ends up with a roughly even AI group count.
 * This is the scheduling brain of the headless-client rework; the actual reassignment always routes
 * through Waldo_fnc_HeadlessMigrateGroup, never setGroupOwner directly - and even that is never
 * called straight out of this scan. Groups this pass decides to move are queued in
 * Waldo_Headless_MigrationQueue and drained one at a time, a short pause apart, by
 * Waldo_fnc_HeadlessMigrationWorker: migrating many groups back-to-back in a single frame is a known
 * source of a server hitch, which is why the community's own headless-client tooling paces its
 * transfers the same way rather than moving everything the instant it becomes eligible.
 *
 * Eligibility excludes, and records to Waldo_Headless_ExcludedGroups with a reason:
 * - empty groups;
 * - any group with a human-player leader or member (Waldo_fnc_HeadlessMigrateGroup only ever moves
 *   AI, never a player's own group);
 * - a group with the group variable Waldo_Headless_ExcludeGroup set true - the opt-out convention
 *   any WMP subsystem can set on groups it owns and wants pinned to the server, without this feature
 *   needing to know that subsystem by name;
 * - any group or crewed vehicle classified Waldo_ServerOwnedFeature by WMP. This central check is
 *   intentionally independent of individual feature registries and also recognises ACE's vehicle
 *   blacklist, so WMP state-machine assets never enter the HC queue;
 * - sideLogic groups (curator helper/ZEN module logic);
 * - AI-crewed helicopter groups. Live dedicated testing confirmed that transferring an airborne
 *   helicopter between server/HC ownership makes Zeus movement and regrouping dive into terrain;
 *   helicopters therefore remain server-local while infantry and ground AI use HCs normally;
 * - any group currently crewing a registered Airborne Gunship aircraft (Waldo_Gunship_Registry) -
 *   gunship crew is documented as staying server-owned and its control handoff is unrelated to
 *   group locality, so migrating its crew group is out of scope here;
 * - a group WMP has not seen for at least Waldo_Headless_MinGroupAgeSeconds yet (default 10s) - a
 *   group migrated the instant it exists can outrun a spawner script (a custom AI mod, a mission
 *   trigger, WMP's own Dynamic AO) that is still in the middle of populating or configuring it;
 *   giving every group a short settle time first is the same mitigation the original headless-client
 *   community tooling documents for exactly this class of interference;
 * - a group not currently local to the server (already on a headless client, or otherwise not this
 *   machine's to move);
 * - a group already recorded as assigned to a still-connected headless client in
 *   Waldo_Headless_ManagedGroups.
 *
 * Waldo_Headless_ManagedGroups is pruned of dead/empty groups at the start of every pass (a group
 * that died while assigned to a headless client without ever triggering a disconnect event would
 * otherwise sit in the registry for the rest of the mission, permanently reporting a phantom
 * ownership-consistency error and skewing future load-following decisions).
 *
 * This function also does nothing at all until Waldo_Headless_StartDelaySeconds (default 30) of
 * mission time have passed, mirroring the same "start delay" every established headless-client tool
 * documents: mission-wide AI-spawning infrastructure (a custom AI mod's own initial pass, DAC/UPSMON
 * style spawners, WMP's own systems) needs a moment to finish its own startup before anything begins
 * moving AI off the server.
 *
 * Locality and authority:
 * Server-only. Safe to call repeatedly - a group already assigned to a connected headless client, or
 * already queued, is left alone; only newly eligible groups are added to the queue.
 *
 * Arguments: None.
 *
 * Return Value:
 * Number - count of groups newly added to Waldo_Headless_MigrationQueue by this pass (not
 * necessarily migrated yet - see Waldo_fnc_HeadlessMigrationWorker).
 *
 * Example:
 * [] call Waldo_fnc_HeadlessRebalance;
 *
 * Current callers: Waldo_fnc_HeadlessRegisterClient, Waldo_fnc_HeadlessReassignOnDisconnect.
 */

if !(isServer) exitWith {0};

private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
if (_clients isEqualTo []) exitWith {0};

private _startDelay = missionNamespace getVariable ["Waldo_Headless_StartDelaySeconds", 30];
if (time < _startDelay) exitWith {0};
private _minGroupAge = missionNamespace getVariable ["Waldo_Headless_MinGroupAgeSeconds", 10];

private _clientOwnerIds = _clients apply {_x select 0};
private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
private _liveManaged = _managed select {!(isNull (_x select 0)) && {count units (_x select 0) > 0}};
if (count _liveManaged != count _managed) then {
    missionNamespace setVariable ["Waldo_Headless_ManagedGroups", _liveManaged, true];
};
_managed = _liveManaged;

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
            if (_group getVariable ["Waldo_ServerOwnedFeature", false]
                || {(units _group) findIf {
                    private _vehicle = vehicle _x;
                    _vehicle getVariable ["Waldo_ServerOwnedFeature", false]
                    || {_vehicle getVariable ["acex_headless_blacklist", false]}
                } >= 0}) then {
                _reason = "wmp-server-owned";
            } else {
                if ((units _group) findIf {(vehicle _x) isKindOf "Helicopter"} >= 0) then {
                    _reason = "helicopter-flight-locality";
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
                            private _firstSeen = _group getVariable ["Waldo_Headless_FirstSeenTime", -1];
                            if (_firstSeen < 0) then {
                                _group setVariable ["Waldo_Headless_FirstSeenTime", time];
                                _reason = "too-new";
                            } else {
                                if ((time - _firstSeen) < _minGroupAge) then {
                                    _reason = "too-new";
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

private _queue = missionNamespace getVariable ["Waldo_Headless_MigrationQueue", []];
private _alreadyQueued = _queue apply {_x select 0};
{
    _x params ["_qGroup", "_qOwner"];
    if (_qOwner in _clientOwnerIds) then {_loadByOwner set [_qOwner, (_loadByOwner get _qOwner) + 1];};
} forEach _queue;

private _queuedNow = 0;
{
    private _group = _x;
    if !(_group in _alreadyQueued) then {
        private _bestOwner = -1;
        private _bestLoad = 1e9;
        {
            private _load = _loadByOwner get _x;
            if (_load < _bestLoad) then {_bestLoad = _load; _bestOwner = _x;};
        } forEach _clientOwnerIds;
        if (_bestOwner > 0) then {
            _queue pushBack [_group, _bestOwner];
            _loadByOwner set [_bestOwner, _bestLoad + 1];
            _queuedNow = _queuedNow + 1;
        };
    };
} forEach _eligible;
missionNamespace setVariable ["Waldo_Headless_MigrationQueue", _queue];

if (_queuedNow > 0 && {!(missionNamespace getVariable ["Waldo_Headless_MigrationWorkerActive", false])}) then {
    [] spawn Waldo_fnc_HeadlessMigrationWorker;
};

diag_log format ["[WMP HEADLESS] Rebalance pass: eligible=%1 excluded=%2 queuedNow=%3 queueLength=%4 clients=%5.", count _eligible, count _excluded, _queuedNow, count _queue, count _clients];
private _reasonTally = [];
{
    _x params ["", "_reason"];
    private _tIdx = _reasonTally findIf {(_x select 0) == _reason};
    if (_tIdx >= 0) then {(_reasonTally select _tIdx) set [1, ((_reasonTally select _tIdx) select 1) + 1];}
    else {_reasonTally pushBack [_reason, 1];};
} forEach _excluded;
["REBALANCE", format [
    "eligible=%1 excluded=%2 queuedNow=%3 queueLength=%4 loadByOwner=%5 excludedReasons=%6",
    count _eligible, count _excluded, _queuedNow, count _queue, _loadByOwner, _reasonTally
]] call Waldo_fnc_HeadlessDebugLog;
_queuedNow
