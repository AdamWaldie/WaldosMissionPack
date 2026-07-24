/*
 * Author: Waldo
 * Plants a signal tracker on a unit or vehicle so a chosen side can follow it on the map - the
 * C-Track style of electronic reconnaissance. Server-authoritative: it registers the target in the
 * broadcast tracker registry (so JIP players inherit it) and starts a light server prune loop that
 * drops trackers whose target has died or been deleted. The actual map markers are drawn locally on
 * each tracking client (Waldo_fnc_TrackerRender) so they stay hidden from the tracked side.
 *
 * Arguments:
 * 0: Target <OBJECT> - the unit or vehicle to track
 * 1: Tracking side <SIDE or STRING> - who sees the marker: a side, or "ALL" (optional, default: the
 *      caller's side; on the server, "ALL")
 * 2: Label <STRING> - marker label (optional, default: "TRK-<id>")
 * 3: Active <BOOL> - start active (optional, default: true)
 *
 * Return Value:
 * Number <NUMBER> - the tracker id (server side); -1 when forwarded from a client
 *
 * Example:
 * [enemyTruck, west, "Convoy Lead"] call Waldo_fnc_Tracker;
 */

params [["_target", objNull], ["_side", sideUnknown], ["_label", ""], ["_active", true]];

if (isNull _target) exitWith { -1 };

if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_Tracker", 2];
    -1
};

// Normalise the tracking side.
private _sideN = _side;
if (_side isEqualType "") then {
    switch (toUpper _side) do {
        case "ALL": { _sideN = "ALL"; };
        case "WEST"; case "BLUFOR": { _sideN = west; };
        case "EAST"; case "OPFOR": { _sideN = east; };
        case "IND"; case "INDEP"; case "INDFOR"; case "GUER": { _sideN = independent; };
        case "CIV"; case "CIVILIAN": { _sideN = civilian; };
        default { _sideN = "ALL"; };
    };
};
if (_sideN isEqualType sideUnknown && {_sideN == sideUnknown}) then { _sideN = "ALL"; };

private _id = missionNamespace getVariable ["Waldo_Tracker_NextId", 0];
missionNamespace setVariable ["Waldo_Tracker_NextId", _id + 1, true];

if (_label == "") then { _label = format ["TRK-%1", _id]; };

private _registry = missionNamespace getVariable ["Waldo_Tracker_Registry", []];
_registry pushBack [_id, _target, _sideN, _label, _active];
missionNamespace setVariable ["Waldo_Tracker_Registry", _registry, true];

// Lazy server prune loop: removes trackers whose target is gone.
if !(missionNamespace getVariable ["Waldo_Tracker_PruneRunning", false]) then {
    missionNamespace setVariable ["Waldo_Tracker_PruneRunning", true];
    [] spawn {
        while {true} do {
            private _reg = missionNamespace getVariable ["Waldo_Tracker_Registry", []];
            private _kept = _reg select { !isNull (_x select 1) && {alive (_x select 1)} };
            if (count _kept != count _reg) then {
                missionNamespace setVariable ["Waldo_Tracker_Registry", _kept, true];
            };
            sleep 5;
        };
    };
};

diag_log format ["[WMP TRK] Tracker %1 (%2) planted on %3 for %4.", _id, _label, _target, _sideN];

_id
