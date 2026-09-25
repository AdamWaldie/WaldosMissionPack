/*
 * Author: WaldoTheWarfighter
 * Finds a covered position near a point, on the far side of a solid object from a threat.
 *
 * Uses the Smart Combat V2 method, which the audit found correct: the candidate sits outside the
 * object's bounding radius on the side away from the threat, and it is accepted only if a
 * line-of-fire ray from the threat's eye height to the candidate's chest height is blocked. Digii's
 * fault (spots 1.5-2 m from an object's centre, inside large buildings) is avoided, and a candidate
 * under the same object's roof is rejected. Trees, rocks, walls, fences, hides and buildings count;
 * bushes do not (they conceal but do not stop rounds). The engine's `findCover` is not implemented in
 * Arma 3, so this is scripted.
 * Locality and authority: read-only; callable anywhere.
 *
 * Arguments:
 * 0: position <ARRAY> - ATL point to search around
 * 1: threat <ARRAY> - ATL position of the threat
 * 2: radius <NUMBER> - search radius in metres (optional, default: 12)
 * 3: reserved <ARRAY> - ATL positions already taken by squad-mates (optional, default: [])
 *
 * Return Value:
 * Array - [coverPosATL, found <BOOL>]; the original position when no cover qualifies
 *
 * Example:
 * ([_boundPoint, _enemyPos, 12, _taken] call Waldo_fnc_AIPassFindCover) params ["_spot", "_found"];
 * Result: a nearby spot with solid cover between it and the enemy, if one exists.
 *
 * Current callers: Waldo_fnc_AIPassFlankStep, Waldo_fnc_AIPassGrenadeCheck and Waldo_fnc_AIPassAntiArmour.
 */

params [["_position", [], [[]]], ["_threat", [], [[]]], ["_radius", 12, [0]], ["_reserved", [], [[]]]];
if (count _position < 2 || {count _threat < 2}) exitWith {[_position, false]};
private _objects = nearestTerrainObjects [_position, ["TREE", "SMALL TREE", "ROCK", "ROCKS", "WALL", "FENCE", "HIDE", "BUILDING", "HOUSE"], _radius, true, true];
{_objects pushBackUnique _x} forEach (nearestObjects [_position, ["House", "Wall", "Strategic"], _radius, true]);
if (count _objects > 10) then {_objects resize 10};
private _threatASL = (AGLToASL _threat) vectorAdd [0, 0, 1.6];
private _result = [];
{
    private _object = _x;
    private _centre = getPosATL _object;
    private _bounds = boundingBoxReal _object;
    private _extent = ((_bounds select 1) vectorDiff (_bounds select 0));
    // Horizontal half-diagonal, capped so a long wall does not throw the spot far behind it.
    private _offset = (((vectorMagnitude [_extent select 0, _extent select 1, 0]) / 2) min 8) + 0.8;
    private _candidate = _centre getPos [_offset, (_threat getDir _centre)];
    _candidate set [2, 0];
    private _candidateASL = AGLToASL _candidate;
    private _free = !surfaceIsWater _candidate
        && {_reserved findIf {_x distance2D _candidate < 2} < 0}
        && {(lineIntersectsSurfaces [_candidateASL vectorAdd [0, 0, 0.5], _candidateASL vectorAdd [0, 0, 20], objNull, objNull, true, 1]) findIf {(_x select 2) == _object || {(_x select 3) == _object}} < 0};
    if (_free) then {
        private _endASL = _candidateASL vectorAdd [0, 0, 1];
        // Start the object ray 2 m out from the threat: starting at the believed enemy position
        // would hit the enemy soldier (or his own cover) and make every spot look covered.
        private _rayStart = _threatASL vectorAdd ((_threatASL vectorFromTo _endASL) vectorMultiply 2);
        private _blocked = terrainIntersectASL [_threatASL, _endASL]
            || {(lineIntersectsSurfaces [_rayStart, _endASL, objNull, objNull, true, 1, "FIRE", "GEOM"]) isNotEqualTo []};
        if (_blocked) then {_result = [_candidate, true]};
    };
    if (_result isNotEqualTo []) exitWith {};
} forEach _objects;
if (_result isEqualTo []) then {[_position, false]} else {_result}
