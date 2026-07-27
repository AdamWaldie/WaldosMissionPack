/* Plays an MHQ transition sound for interface clients close enough to hear its 3D source. */
params [["_target", objNull, [objNull]], ["_audioPath", "", [""]]];
if (!hasInterface || {isNull _target} || {_audioPath isEqualTo ""}) exitWith {false};
if (isNull player || {player distance _target > 140}) exitWith {false};
playSound3D [getMissionPath _audioPath, _target, false, getPosASL _target, 4, 1, 120];
diag_log format ["[WMP MHQ] Local transition audio target=%1 listener=%2 distance=%3", netId _target, name player, player distance _target];
true
