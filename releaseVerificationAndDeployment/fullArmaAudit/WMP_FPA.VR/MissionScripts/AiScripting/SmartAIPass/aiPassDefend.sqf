/*
 * Author: WaldoTheWarfighter
 * Orders an AI group to hold a defensive line facing a direction, with a rear reserve.
 *
 * From Smart Combat V2's defence: about two thirds of the squad form a firing line across the facing
 * direction, spread over the given width. Each soldier's spot is snapped to cover facing the threat,
 * and soldiers watch overlapping sectors (up to 30 degrees either side of the facing). The rest form a
 * reserve 40 m behind the centre; squads of three or fewer are all line. Soldiers hold with doStop
 * rather than a PATH lock, so they can still take cover and turn. The reserve is committed once
 * (Waldo_fnc_AIPassDefendStep) to the weakest point of the line when a third of the line is lost, or
 * to the line spot nearest an enemy believed within 60 m of the line. The order breaks at
 * Waldo_AIPass_Garrison_BreakFraction of its strength, or when morale breaks, and the survivors then
 * fight normally.
 * The order and each soldier's spot are published once as group and unit variables, so a new owner
 * after a headless-client handover re-applies them in its discovery sweep. Zeus waypoints release it.
 * Locality and authority: call where the group is local, or on the server, which forwards to the
 * owner. Non-server, non-owner copies do nothing. Needs the Smart AI Pass running.
 *
 * Arguments:
 * 0: group <GROUP or OBJECT> - the group, or a unit in it
 * 1: centre <ARRAY or OBJECT> - ATL position or object at the middle of the line
 * 2: facing <NUMBER or ARRAY or OBJECT> - compass direction, or a position/object the line faces
 * 3: width <NUMBER> - line width in metres (optional, default: 60)
 *
 * Return Value:
 * Boolean - true when the order was applied or forwarded
 *
 * Example:
 * [group this, getMarkerPos "ridge", 45, 80] call Waldo_fnc_AIPassDefend;
 * Result: the squad forms an 80 m line on the ridge facing north-east, with a reserve behind it.
 *
 * Current callers: mission scripts and the AI Orders ZEN module.
 */

params [["_group", grpNull, [grpNull, objNull]], ["_centre", [], [[], objNull]], ["_facing", 0, [0, [], objNull]], ["_width", 60, [0]]];
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    if (isServer) then {[_group, _centre, _facing, _width] remoteExecCall ["Waldo_fnc_AIPassDefend", groupOwner _group]; true} else {false};
};
if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {
    diag_log format ["[WMP AI PASS] %1 defend refused: the Smart AI Pass is not running on this machine.", _group];
    false
};
if (_centre isEqualType objNull) then {_centre = getPosATL _centre};
if (count _centre < 2) then {_centre = getPosATL leader _group};
if !(_facing isEqualType 0) then {
    private _towards = if (_facing isEqualType objNull) then {getPosATL _facing} else {_facing};
    _facing = _centre getDir _towards;
};
private _units = (units _group) select {alive _x && {vehicle _x == _x}};
if (_units isEqualTo []) exitWith {false};
private _reserveCount = if (count _units >= 4) then {floor (count _units / 3)} else {0};
private _line = _units select [0, count _units - _reserveCount];
private _reserve = _units select [count _line, _reserveCount];
private _threat = _centre getPos [150, _facing];
private _spacing = _width / ((count _line - 1) max 1);
private _taken = [];
{
    private _offset = (_forEachIndex - (count _line - 1) / 2) * _spacing;
    private _spot = ([_centre getPos [_offset, _facing + 90], _threat, 8, _taken] call Waldo_fnc_AIPassFindCover) select 0;
    _taken pushBack _spot;
    private _sector = _facing + ((_forEachIndex / ((count _line - 1) max 1)) - 0.5) * 60;
    _x setVariable ["Waldo_AIPass_DefendPos", [_spot, _sector, "LINE"], true];
} forEach _line;
private _rear = _centre getPos [40, _facing + 180];
{
    _x setVariable ["Waldo_AIPass_DefendPos", [_rear getPos [(_forEachIndex - (count _reserve - 1) / 2) * 5, _facing + 90], _facing, "RESERVE"], true];
} forEach _reserve;
if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_AIPassGarrisonRelease};
_group setVariable ["Waldo_AIPass_Defend", [_centre, _facing, _width, count _units], true];
_group setVariable ["Waldo_AIPass_DefendApplied", false];
[_group] call Waldo_fnc_AIPassDefendApplyLocal;
diag_log format ["[WMP AI PASS] %1 defending %2 facing %3 (line %4, reserve %5)", _group, _centre, round _facing, count _line, count _reserve];
true
