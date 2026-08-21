/*
 * Author: WaldoTheWarfighter
 * Plays an optional registered CfgSounds voice line spatially from its speaker for one listener.
 * Locality/authority: interface local and accepts server remote execution only.
 * Repeat/JIP behaviour: transient; missing sound IDs fail cleanly without blocking subtitles.
 * Arguments: speaker OBJECT, sound ID STRING. Return Value: BOOL.
 * Current caller: ConversationRunServer. Example: server remote execution to current nearby listeners.
 */
params [["_speaker", objNull, [objNull]], ["_sound", "", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _speaker} || {_sound == ""}) exitWith {false};
if !(isClass (missionConfigFile >> "CfgSounds" >> _sound)) exitWith {diag_log format ["[WMP CONVERSATION] Missing CfgSounds id '%1'; subtitle continued without audio.", _sound]; false};
_speaker say3D _sound;
true
