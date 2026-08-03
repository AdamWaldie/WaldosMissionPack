/* Moves only the locally owned requesting player after server authorization. */
params [["_unit", objNull, [objNull]], ["_position", [], [[]]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (isNull _unit || {!local _unit} || {count _position < 2}) exitWith {false};
_unit setPosATL _position;
diag_log format ["[WMP RALLY] Redeployed local unit=%1 position=%2 owner=%3", name _unit, _position, owner _unit];
true
