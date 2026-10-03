/*
 * Author: WaldoTheWarfighter
 * Selects and starts one viable local infantry manoeuvre from the squad's live tactical context.
 *
 * An active forward MOVE, SAD or DESTROY order prefers a bounded advance because that manoeuvre
 * preserves the authored objective. A squad without such an order prefers a flank against its live
 * contact. The other enabled manoeuvre is tried immediately when the preferred one cannot satisfy
 * its actor, range, avenue, cooldown or safety gates. Behaviour profiles do not assign squads a
 * fixed movement pattern and no random permission roll can leave a capable squad idle. Feature
 * switches remain the explicit mission-maker controls. The selector adds no scheduler, terrain
 * scan or per-unit loop; the selected start function owns the finite movement it creates.
 *
 * Locality and authority: call only where the group is local. It reads the current server-published
 * feature gates and the live authored order/contact context, then delegates to owner-local starts.
 * Repeat/JIP: start functions reject active leases, drills and cooldowns, so repeated calls are safe.
 * Feature and order changes apply on the next group tick; no state is replayed to JIP clients.
 *
 * Arguments:
 * 0: group <GROUP> - local infantry group in contact
 * 1: state <HASHMAP> - current Cortex group state
 * 2: enemies <ARRAY> - current Waldo_fnc_CortexKnowledge result
 * 3: flank enabled <BOOL> - authoritative live feature gate (default true)
 * 4: advance enabled <BOOL> - authoritative live feature gate (default true)
 *
 * Return Value:
 * Boolean - true when either manoeuvre started
 *
 * Current caller: Waldo_fnc_CortexGroupTick.
 *
 * Example:
 * private _started = [_group, _state, _enemies, true, true] call Waldo_fnc_CortexTacticalStart;
 * Result: Cortex follows the live objective/contact context and immediately tries the other viable
 * manoeuvre if the first cannot start.
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_state", createHashMap, [createHashMap]],
    ["_enemies", [], [[]]],
    ["_flankEnabled", true, [true]],
    ["_advanceEnabled", true, [true]]
];
if (isNull _group || {!local _group}) exitWith {false};

if (!_flankEnabled && {!_advanceEnabled}) exitWith {false};
private _waypointIndex = currentWaypoint _group;
private _hasForwardOrder = _waypointIndex < count waypoints _group
    && {waypointDescription [_group,_waypointIndex] != "WMP AI PASS"}
    && {waypointType [_group,_waypointIndex] in ["MOVE","SAD","DESTROY"]}
    && {leader _group distance2D waypointPosition [_group,_waypointIndex] > 80};
private _preferFlank = _flankEnabled && {!_advanceEnabled || {!_hasForwardOrder}};
private _started = false;
if (_preferFlank) then {
    _started = [_group, _state, _enemies] call Waldo_fnc_CortexFlankStart;
    if (!_started && {_advanceEnabled}) then {
        _started = [_group, _state, _enemies] call Waldo_fnc_CortexAdvanceStart;
    };
} else {
    _started = [_group, _state, _enemies] call Waldo_fnc_CortexAdvanceStart;
    if (!_started && {_flankEnabled}) then {
        _started = [_group, _state, _enemies] call Waldo_fnc_CortexFlankStart;
    };
};
_started
