/*
 * Author: WaldoTheWarfighter
 * Summarises what a group already knows about nearby enemies, using only engine knowledge.
 *
 * The pass uses existing engine detection and preserves AI Rebalance settings. Enemies come from the leader's `targets` list. The believed
 * position is `getHideFrom`, which the engine extrapolates when the enemy is out of sight. Seen age
 * is the newest lastSeen/lastThreat across up to eight living members, so a leader in cover does not
 * hide a firefight the rest of the squad is in. An enemy counts only if the group knows about it
 * (knownByGroup and knowsAbout of at least 1), which also covers `lastSeen` being 0 before any sighting.
 * At most eight enemies, nearest first, are examined.
 * Locality and authority: read-only; call where the group is local. Nothing is broadcast.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: range <NUMBER> - metres from the leader (optional, default: Waldo_AIPass_EngageRange)
 *
 * Return Value:
 * Array - [enemies, seenCount]. enemies is an array of
 * [enemy <OBJECT>, believedPosATL <ARRAY>, seenAge <NUMBER>, distance <NUMBER>, errorMargin <NUMBER>],
 * nearest first. seenCount counts enemies seen within the last 5 seconds.
 *
 * Example:
 * ([_group] call Waldo_fnc_AIPassKnowledge) params ["_enemies", "_seenCount"];
 * Result: the group's nearest known enemies and how many of them it can currently see.
 *
 * Current callers: Waldo_fnc_AIPassGroupTick and the behaviour functions it calls.
 */

params [["_group", grpNull, [grpNull]], ["_range", -1, [0]]];
if (_range < 0) then {_range = missionNamespace getVariable ["Waldo_AIPass_EngageRange", 800]};
private _leader = leader _group;
if (isNull _leader || {!alive _leader}) exitWith {[[], 0]};

private _candidates = [];
{
    private _enemy = _x;
    if (alive _enemy && {!captive _enemy} && {_leader knowsAbout _enemy >= 1}) then {
        private _position = _leader getHideFrom _enemy;
        if (_position isNotEqualTo [0, 0, 0]) then {
            // The unique index breaks ties so sort never has to compare objects.
            _candidates pushBack [_leader distance2D _position, count _candidates, _enemy, _position];
        };
    };
} forEach (_leader targets [true, _range]);
_candidates sort true;
if (count _candidates > 8) then {_candidates resize 8};

private _members = (units _group) select {alive _x};
if (count _members > 8) then {_members resize 8};
private _enemies = [];
private _seenCount = 0;
{
    _x params ["_distance", "_order", "_enemy", "_position"];
    private _newest = -1;
    private _knownByGroup = false;
    private _error = 1000;
    {
        private _knowledge = _x targetKnowledge _enemy;
        if (_knowledge select 0) then {_knownByGroup = true};
        _newest = _newest max ((_knowledge select 2) max (_knowledge select 3));
        _error = _error min (_knowledge select 5);
    } forEach _members;
    if (_knownByGroup) then {
        private _age = if (_newest > 0) then {time - _newest} else {1e6};
        if (_age <= 5) then {_seenCount = _seenCount + 1};
        _enemies pushBack [_enemy, _position, _age, _distance, _error];
    };
} forEach _candidates;
[_enemies, _seenCount]
