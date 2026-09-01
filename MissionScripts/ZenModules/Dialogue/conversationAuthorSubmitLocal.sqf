/*
 * Author: WaldoTheWarfighter
 * Submits one validated, code-free Conversation Author draft to the authenticated server endpoint
 * for register-only, direct-target, or direct-group assignment.
 * Locality/authority: curator interface request; server owns validation, registry and assignment.
 * Repeat/JIP behaviour: request IDs identify acknowledgements; replacement requires its checkbox.
 * Arguments: editor DISPLAY, assignment mode STRING NONE/TARGET/GROUP. Return Value: BOOL.
 * Current callers: Conversation Author action buttons.
 * Example: [_display,"NONE"] call Waldo_fnc_ConversationAuthorSubmitLocal;
 */
params [["_display", displayNull, [displayNull]], ["_assignmentMode", "NONE", [""]]];
if (isNull _display) exitWith {false};
private _validation = [_display, false] call Waldo_fnc_ConversationAuthorValidateLocal;
if !(_validation select 0) exitWith {
    ["CONVERSATION", "Fix the highlighted validation errors before registering.", "WARNING", "CONVERSATION_AUTHOR", 7] call Waldo_fnc_FeatureNotifyLocal;
    false
};
private _drafts = _display getVariable ["WaldoConvAuthor_Drafts", []];
private _definition = _drafts select (_display getVariable ["WaldoConvAuthor_DraftIndex", 0]);
private _requestId = format ["AUTHOR_%1_%2", clientOwner, floor (diag_tickTime * 1000)];
private _rows = [
    ["requestId", _requestId],
    ["definition", _definition],
    ["assignmentMode", toUpperANSI _assignmentMode],
    ["target", _display getVariable ["WaldoConvAuthor_Target", objNull]],
    ["removeAfterUse", cbChecked (_display getVariable ["WaldoConvAuthor_RemoveAfter", controlNull])],
    ["replaceExisting", cbChecked (_display getVariable ["WaldoConvAuthor_Replace", controlNull])]
];
missionNamespace setVariable ["Waldo_Conversation_AuthorLastRequest", _requestId];
[_rows, player] remoteExecCall ["Waldo_fnc_ZenConversationAuthorServer", 2];
true
