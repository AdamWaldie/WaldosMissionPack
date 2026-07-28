/* Moves only the locally owned requesting player after server authorization. */
params [["_unit", objNull, [objNull]], ["_position", [], [[]]]];
if (remoteExecutedOwner != 2 || {isNull _unit} || {!local _unit} || {count _position < 2}) exitWith {false};
_unit setPosATL _position;
true
