/*
 * Author: WaldoTheWarfighter
 * Selects a recently known convoy threat, preferring an enemy that actually endangered the observer.
 * Locality/authority: read-only on the observer's owner; never reveals enemies or reads their live position.
 * Repeat/JIP: no persistent state; callers throttle queries to five seconds. At most 16 knowledge entries are inspected.
 * Arguments: 0: observer <OBJECT>, objNull; 1: range metres <NUMBER>, 800.
 * Return Value: Array [enemy OBJECT, believed ATL ARRAY, active danger BOOL], or [] when no recent hostile is known.
 * Current callers: ConvoyTick and ConvoyCrewLocal.
 * Example: private _report = [gunner tank1] call Waldo_fnc_ConvoyThreat;
 */
params [["_observer", objNull, [objNull]], ["_range", 800, [0]]];
if (isNull _observer || {!local _observer} || {!alive _observer}) exitWith {[]};
private _result = [];
private _best = -1e9;
private _targets = _observer nearTargets ((_range max 50) min 1200);
if (count _targets > 16) then {_targets resize 16};
{
    _x params ["_position", "", "_side", "", "_enemy"];
    if (!isNull _enemy && {alive _enemy} && {(side group _observer) getFriend _side < 0.6}
        && {_observer knowsAbout _enemy >= 1.5}) then {
        private _knowledge = _observer targetKnowledge _enemy;
        private _seen = _knowledge select 2;
        private _endangered = _knowledge select 3;
        if ((_seen >= 0 && {time - _seen <= 30}) || {_endangered > 0 && {time - _endangered <= 15}}) then {
            private _active = _endangered > 0 && {time - _endangered <= 15};
            private _score = ([0, 10000] select _active) - (_observer distance2D _position);
            if (_score > _best) then {_best = _score; _result = [_enemy, +_position, _active]};
        };
    };
} forEach _targets;
_result
