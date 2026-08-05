/*
 * Author: WaldoTheWarfighter, Val
 * Clears WMP transport waypoints and stops an AI service group on its current locality owner.
 *
 * Arguments: 0 group <GROUP>; 1 stop position <ARRAY> (informational).
 * Return Value: Boolean - true on the owning machine.
 * Example: [_group,getPosATL leader _group] call Waldo_fnc_TransportStopGroupLocal;
 * Current caller: Waldo_fnc_TransportReportServer after physical RTB.
 */
params ["_group", ["_position", [], [[]]]];
if (isNull _group) exitWith {false};
if (!local _group) exitWith {[_group, _position] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group]; true};
for "_i" from ((count waypoints _group) - 1) to 0 step -1 do {deleteWaypoint [_group, _i]};
doStop leader _group;
true

