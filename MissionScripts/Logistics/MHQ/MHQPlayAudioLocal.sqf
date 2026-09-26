/*
 * Author: WaldoTheWarfighter
 * Plays one MHQ deploy/tear-down sound for nearby players.
 * Locality and authority: Runs on each receiving interface client after a server-approved
 * transition. Repeated calls play another sound; audio is transient and is not JIP replayed.
 * Arguments: 0: MHQ <OBJECT>; 1: mission-relative sound path <STRING> (empty disables audio).
 * Return Value: <BOOL> true when this client played the sound; false if too far away or invalid.
 * Current caller: Waldo_fnc_MHQRequestServer after a deploy or tear-down.
 * Example: [myMHQ, "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_New.ogg"]
 *   call Waldo_fnc_MHQPlayAudioLocal;
 * Result: Players within hearing range hear the 3D transition sound at the MHQ.
 */
params [["_target", objNull, [objNull]], ["_audioPath", "", [""]]];
if (!hasInterface || {isNull _target} || {_audioPath isEqualTo ""}) exitWith {false};
if (isNull player || {player distance _target > 140}) exitWith {false};
playSound3D [getMissionPath _audioPath, _target, false, getPosASL _target, 4, 1, 120];
diag_log format ["[WMP MHQ] Local transition audio target=%1 listener=%2 distance=%3", netId _target, name player, player distance _target];
true
