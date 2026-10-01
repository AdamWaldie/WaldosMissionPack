/*
 * Author: WaldoTheWarfighter
 * Selects and starts one viable local infantry manoeuvre for a squad in contact.
 *
 * Flank and advance profile values are relative preferences, not independent permission rolls.
 * A positive enabled preference enters the selection; zero excludes that manoeuvre. When both are
 * available, one bounded random draw chooses which is tried first and the other is an immediate
 * fallback if the preferred manoeuvre cannot satisfy its own actor, range, route or cooldown gates.
 * This prevents a capable squad from idling because two unrelated chance rolls both failed while
 * preserving profile differences in tactical style. The selector creates no scheduler or per-unit
 * loop; the selected start function owns any finite drill it creates.
 *
 * Locality and authority: call only where the group is local. It reads the current server-published
 * feature gates and behaviour profile, then delegates to owner-local start functions.
 * Repeat/JIP: start functions reject active leases, drills and cooldowns, so repeated calls are safe.
 * Profile and feature changes apply on the next group tick; no state is replayed to JIP clients.
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
 * Result: Cortex prefers a profile-weighted flank or advance and immediately tries the other viable
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

private _flankWeight = [0, [_group, "flankChance"] call Waldo_fnc_CortexProfile] select _flankEnabled;
private _advanceWeight = [0, [_group, "advanceChance"] call Waldo_fnc_CortexProfile] select _advanceEnabled;
private _totalWeight = _flankWeight + _advanceWeight;
if (_totalWeight <= 0) exitWith {false};

private _preferFlank = if (_advanceWeight <= 0) then {true} else {
    if (_flankWeight <= 0) then {false} else {random _totalWeight < _flankWeight}
};
private _started = false;
if (_preferFlank) then {
    _started = [_group, _state, _enemies] call Waldo_fnc_CortexFlankStart;
    if (!_started && {_advanceWeight > 0}) then {
        _started = [_group, _state, _enemies] call Waldo_fnc_CortexAdvanceStart;
    };
} else {
    _started = [_group, _state, _enemies] call Waldo_fnc_CortexAdvanceStart;
    if (!_started && {_flankWeight > 0}) then {
        _started = [_group, _state, _enemies] call Waldo_fnc_CortexFlankStart;
    };
};
_started
