/*
 * Author: WaldoTheWarfighter
 * Pure paradrop route geometry: the standby, green, red, spawn, exit and re-alignment circuit
 * positions around a drop-point centre and an approach heading. No waypoints, no group/aircraft
 * state, no side effects - just the math.
 *
 * Factored out of Waldo_fnc_ParadropBuildFlightRoute so the exact line the AI will actually fly
 * can be computed by a caller that has no aircraft or flight group yet - originally so the live
 * deployment-direction preview (Waldo_fnc_ParadropPreviewStart) can draw the real route while a
 * curator is still choosing a heading, but it is a generic, reusable helper.
 * Waldo_fnc_ParadropBuildFlightRoute still owns clamping the raw altitude/speed/approach/run
 * length/exit distance/lifecycle inputs before calling this - this function trusts its numeric
 * arguments as already valid.
 *
 * Arguments:
 * 0: centre <ARRAY> - drop point position (2 or 3 element; Z is overwritten by altitude below).
 * 1: direction <NUMBER> - degrees; the approach heading through the line (default 0).
 * 2: altitude <NUMBER> - Z written onto every returned position (default 300). Callers that only
 *    want a flat/ground-plane shape (e.g. a top-down preview) should pass 0.
 * 3: approach distance <NUMBER> - metres from standby to the spawn/rejoin point (default 2500).
 * 4: run length <NUMBER> - metres of the green-to-red jump run (default 2500).
 * 5: exit distance <NUMBER> - metres flown past the red line before turning off (default 2500).
 * 6: circuit direction <STRING> - LEFT or RIGHT, which way the LOOP circuit turns (default LEFT).
 *
 * Return Value:
 * HashMap - standby, green, centre, red, spawn, exit, crosswind, downwind, rejoin, hold (each a 3D
 * position with Z set to the supplied altitude), plus circuitWidth. Empty HashMap when centre is
 * invalid.
 *
 * Example:
 * [getMarkerPos "dz1", 45, 300, 2500, 2500, 2500, "LEFT"] call Waldo_fnc_ParadropRouteGeometry;
 *
 * Current callers: Waldo_fnc_ParadropBuildFlightRoute, Waldo_fnc_ParadropPreviewStart.
 */

params [
    ["_centre", [], [[]]],
    ["_direction", 0, [0]],
    ["_altitude", 300, [0]],
    ["_approach", 2500, [0]],
    ["_runLength", 2500, [0]],
    ["_exitDistance", 2500, [0]],
    ["_circuitDirection", "LEFT", [""]]
];
if (count _centre < 2) exitWith {createHashMap};

_centre = +_centre;
if (count _centre < 3) then {_centre pushBack 0};
_direction = _direction mod 360;
_circuitDirection = toUpperANSI _circuitDirection;
private _circuitTurn = if (_circuitDirection == "RIGHT") then {90} else {-90};

private _standby = [_centre, _runLength * 0.65, _direction + 180] call BIS_fnc_relPos;
private _green = [_centre, _runLength * 0.5, _direction + 180] call BIS_fnc_relPos;
private _red = [_centre, _runLength * 0.5, _direction] call BIS_fnc_relPos;
private _spawn = [_standby, _approach, _direction + 180] call BIS_fnc_relPos;
private _exit = [_red, _exitDistance, _direction] call BIS_fnc_relPos;
private _circuitWidth = ((_approach max _runLength) * 0.75) max 1200;
private _crosswind = [_exit, _circuitWidth, _direction + _circuitTurn] call BIS_fnc_relPos;
private _downwind = [_spawn, _circuitWidth, _direction + _circuitTurn] call BIS_fnc_relPos;
private _rejoin = [_spawn, _approach * 0.6, _direction + 180] call BIS_fnc_relPos;
private _hold = [_exit, 1800, _direction] call BIS_fnc_relPos;
{_x set [2, _altitude]} forEach [_standby, _green, _centre, _red, _spawn, _exit, _crosswind, _downwind, _rejoin, _hold];

createHashMapFromArray [
    ["standby", _standby], ["green", _green], ["centre", _centre], ["red", _red],
    ["spawn", _spawn], ["exit", _exit], ["crosswind", _crosswind], ["downwind", _downwind],
    ["rejoin", _rejoin], ["hold", _hold], ["circuitWidth", _circuitWidth]
]
