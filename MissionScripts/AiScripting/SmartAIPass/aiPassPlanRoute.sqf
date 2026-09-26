/*
 * Author: WaldoTheWarfighter
 * Turns a list of leg end points into bound points, inserting street crossings.
 *
 * Shared by the flank and advance drills. Each leg is cut into bounds of
 * Waldo_AIPass_Flank_BoundDistance (minimum 15 m). With Waldo_AIPass_StreetCrossing_Enable, a leg is
 * sampled every 6 m. Where it runs onto a road (isOnRoad and roadAt, bridges excluded), a CROSS_NEAR
 * point is placed at the near edge and a CROSS_FAR point just past the far edge, using the road width
 * from getRoadInfo, and ordinary bound points inside the road are dropped. The last point gets the
 * requested final kind.
 * Locality and authority: pure calculation; callable anywhere.
 *
 * Arguments:
 * 0: start <ARRAY> - ATL position
 * 1: legs <ARRAY> - ATL leg end points, in order
 * 2: final kind <STRING> - kind for the last point (optional, default: "FINAL")
 *
 * 3: group <GROUP> - optional group feature exclusions, default grpNull.
 * Repeat/JIP: pure bounded calculation, no persistent state.
 * Return Value:
 * Array - [[positionATL, kind], ...] with kind BOUND, CROSS_NEAR, CROSS_FAR or the final kind
 *
 * Example:
 * private _points = [_start, [_wide, _close]] call Waldo_fnc_AIPassPlanRoute;
 * Result: a bounding route that pauses and smokes at each road it crosses.
 *
 * Current callers: Waldo_fnc_AIPassFlankStart and Waldo_fnc_AIPassAdvanceStart.
 */

params [["_start", [], [[]]], ["_legs", [], [[]]], ["_finalKind", "FINAL", [""]], ["_group",grpNull,[grpNull]]];
private _bound = (missionNamespace getVariable ["Waldo_AIPass_Flank_BoundDistance", 40]) max 15;
private _streets = [_group,"Waldo_AIPass_StreetCrossing_Enable",true] call Waldo_fnc_AIPassFeatureEnabled;
private _points = [];
private _from = _start;
{
    private _to = _x;
    private _length = _from distance2D _to;
    private _direction = _from getDir _to;
    private _crossings = [];
    if (_streets) then {
        private _clearUntil = -1;
        for "_along" from 6 to (_length - 3) step 6 do {
            if (_along > _clearUntil) then {
                private _sample = _from getPos [_along, _direction];
                if (isOnRoad _sample) then {
                    private _road = roadAt _sample;
                    if (!isNull _road) then {
                        private _info = getRoadInfo _road;
                        if !(_info param [8, false]) then {
                            private _halfWidth = ((_info param [1, 8]) max 4) / 2;
                            _crossings pushBack [_along, _halfWidth];
                            _clearUntil = _along + _halfWidth * 2 + 6;
                        };
                    };
                };
            };
        };
    };
    private _marks = [];
    for "_along" from _bound to (_length - 1) step _bound do {
        private _mark = _along;
        if (_crossings findIf {abs (_mark - (_x select 0)) < (_x select 1) + 6} < 0) then {_marks pushBack [_mark, "BOUND"]};
    };
    {
        _x params ["_centre", "_halfWidth"];
        _marks pushBack [(_centre - _halfWidth - 3) max 1, "CROSS_NEAR"];
        _marks pushBack [(_centre + _halfWidth + 4) min _length, "CROSS_FAR"];
    } forEach _crossings;
    _marks sort true;
    {_points pushBack [_from getPos [_x select 0, _direction], _x select 1]} forEach _marks;
    _points pushBack [_to, if (_forEachIndex == count _legs - 1) then {_finalKind} else {"BOUND"}];
    _from = _to;
} forEach _legs;
_points
