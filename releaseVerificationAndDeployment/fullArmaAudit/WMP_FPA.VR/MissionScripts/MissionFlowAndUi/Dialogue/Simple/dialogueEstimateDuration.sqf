/*
 * Author: WaldoTheWarfighter
 * Calculates readable line time from word count, punctuation pauses, configured bounds, and an
 * optional explicit override. Locality/authority: pure helper on any machine.
 * Repeat/JIP behaviour: deterministic for the same text/settings.
 * Arguments: 0 text <STRING>; 1 override seconds <NUMBER> (default -1). Return Value: NUMBER seconds.
 * Current callers: simple and advanced server playback. Example: ["Wait, please!", -1] call Waldo_fnc_DialogueEstimateDuration;
 */
params [["_text", "", [""]], ["_override", -1, [0]]];
private _minimum = missionNamespace getVariable ["Waldo_Dialogue_MinimumLineSeconds", 1.5];
private _maximum = missionNamespace getVariable ["Waldo_Dialogue_MaximumLineSeconds", 15];
if (_override >= 0) exitWith {(_override max _minimum) min _maximum};
private _words = _text splitString " \t\r\n" select {_x != ""};
private _characters = toArray _text;
private _commas = {_x in [44, 59, 58]} count _characters;
private _terminal = {_x in [46, 33, 63]} count _characters;
private _seconds = (count _words) * (missionNamespace getVariable ["Waldo_Dialogue_SecondsPerWord", 0.5]);
_seconds = _seconds + (_commas * (missionNamespace getVariable ["Waldo_Dialogue_CommaPause", 0.12]));
_seconds = _seconds + (_terminal * (missionNamespace getVariable ["Waldo_Dialogue_TerminalPause", 0.25]));
(_seconds max _minimum) min _maximum
