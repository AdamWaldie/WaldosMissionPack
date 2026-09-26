/*
 * Author: WaldoTheWarfighter
 * Moves a player to a server-approved open rally position.
 * Locality and authority: Must run where that player unit is local. Rejects remote callers other
 * than the server; the server validates and chooses the destination first.
 * Repeat/JIP: Each call moves the unit once and installs no handler or JIP state.
 * Arguments:
 * 0: player unit <OBJECT> (default objNull)
 * 1: safe PositionATL <ARRAY> (default [])
 * Return Value: <BOOL> - true after local movement; false for invalid unit or position.
 * Current callers: Waldo_fnc_RallyPointRequestServer and RallyPointInit respawn placement.
 * Example: [player, _safePosition] call Waldo_fnc_RallyPointMoveLocal;
 * Result: The local player moves to the checked rally position.
 */
params [["_unit", objNull, [objNull]], ["_position", [], [[]]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (isNull _unit || {!local _unit} || {count _position < 2}) exitWith {false};
_unit setPosATL _position;
diag_log format ["[WMP RALLY] Redeployed local unit=%1 position=%2 owner=%3", name _unit, _position, owner _unit];
true
