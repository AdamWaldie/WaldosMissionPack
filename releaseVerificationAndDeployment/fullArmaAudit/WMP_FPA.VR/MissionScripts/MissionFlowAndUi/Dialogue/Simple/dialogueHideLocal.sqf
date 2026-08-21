/*
 * Author: WaldoTheWarfighter
 * Hides the local dialogue subtitle and releases its shared UI reservation.
 * Locality/authority: interface-local; server calls are accepted, arbitrary clients are rejected.
 * Repeat/JIP behaviour: token-aware and repeat-safe. Arguments: 0 token/session prefix STRING.
 * Return Value: BOOL. Current callers: subtitle timer and dialogue workers.
 * Example: ["session"] call Waldo_fnc_DialogueHideLocal;
 */
params [["_token", "", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface) exitWith {false};
private _current = uiNamespace getVariable ["Waldo_Dialogue_SubtitleToken", ""];
if (_token != "" && {_current find _token != 0}) exitWith {false};
{if (!isNull _x) then {_x ctrlShow false}} forEach [uiNamespace getVariable ["Waldo_Dialogue_SubtitleFrame", controlNull], uiNamespace getVariable ["Waldo_Dialogue_SubtitleText", controlNull]];
uiNamespace setVariable ["Waldo_Dialogue_SubtitleToken", ""];
["DIALOGUE_SUBTITLE"] call Waldo_fnc_UnregisterUiReservationLocal;
true
