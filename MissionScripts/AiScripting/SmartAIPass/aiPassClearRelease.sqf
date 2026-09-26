/*
 * Author: WaldoTheWarfighter
 * Cancels a clearing order immediately and restores the original behaviour.
 * Locality/authority: server authenticates dispatch; the current owner executes group commands.
 * Repeat/JIP: request tokens are consumed once; no stale order is replayed for JIP.
 * Arguments: 0: group <GROUP>, default grpNull.
 * Return Value: Boolean, a clearing order existed.
 * Current callers: AI Orders, replacement orders, Zeus release and stop.
 * Example: [_group] call Waldo_fnc_AIPassClearRelease;
 */
params [["_group", grpNull, [grpNull]]];
if (isNull _group || {!local _group} || {remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}}) exitWith {false};
private _order = _group getVariable ["Waldo_AIPass_ClearOrder", []];
if (_order isEqualTo []) exitWith {false};
_group setVariable ["Waldo_AIPass_ClearGeneration", (_group getVariable ["Waldo_AIPass_ClearGeneration", 0]) + 1];
_group setVariable ["Waldo_AIPass_ClearOrder", nil, true];
_group setVariable ["Waldo_AIPass_ClearBuilding", nil, true];
_group setVariable ["Waldo_AIPass_ClearApplied", nil];
{if (alive _x && {local _x}) then {_x doFollow leader _group}} forEach units _group;
if (behaviour leader _group == "COMBAT") then {_group setBehaviour (_order select 3)};
true
