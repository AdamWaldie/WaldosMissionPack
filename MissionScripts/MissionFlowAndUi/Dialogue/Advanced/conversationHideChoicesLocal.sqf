/*
 * Author: WaldoTheWarfighter
 * Closes the local Advanced Conversation modal response panel and deletes its controls.
 * Locality/authority: interface-local and accepts server remote execution only.
 * Repeat/JIP behaviour: session-aware and idempotent. Arguments: optional session ID STRING.
 * Return Value: BOOL. Current callers: choice selection, cancel button and server cleanup.
 * Example: ["sessionId"] call Waldo_fnc_ConversationHideChoicesLocal;
 */
params [["_sessionId", "", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface) exitWith {false};
private _current = uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""];
private _pending = uiNamespace getVariable ["Waldo_Conversation_ChoicePendingSession", ""];
private _effective = if (_current != "") then {_current} else {_pending};
if (_sessionId != "" && {_effective != ""} && {_sessionId != _effective}) exitWith {false};
{if (!isNull _x) then {ctrlDelete _x}} forEach (uiNamespace getVariable ["Waldo_Conversation_ChoiceControls", []]);
["CONVERSATION_CHOICES", false] call Waldo_fnc_UnregisterUiReservationLocal;
uiNamespace setVariable ["Waldo_Conversation_ChoiceSession", ""];
uiNamespace setVariable ["Waldo_Conversation_ChoicePendingSession", ""];
uiNamespace setVariable ["Waldo_Conversation_ChoiceSpeaker", objNull];
uiNamespace setVariable ["Waldo_Conversation_ChoiceControls", []];
uiNamespace setVariable ["Waldo_Conversation_ChoiceButtons", []];
uiNamespace setVariable ["Waldo_Conversation_ChoiceKeyHandler", -1];
private _display = uiNamespace getVariable ["Waldo_Conversation_ChoiceDisplay", displayNull];
uiNamespace setVariable ["Waldo_Conversation_ChoiceDisplay", displayNull];
if (!isNull _display) then {_display closeDisplay 1};
true
