/*
 * Author: WaldoTheWarfighter
 * Receives the authenticated result of a Conversation Author registration/assignment request and
 * presents it through the WMP notification flow.
 * Locality/authority: interface-local and accepts server remote execution only.
 * Repeat/JIP behaviour: request IDs let the open editor ignore stale acknowledgements.
 * Arguments: request ID STRING, success BOOL, message STRING, warnings ARRAY. Return Value: BOOL.
 * Current caller: ZenConversationAuthorServer.
 * Example: server remote execution only.
 */
params [["_requestId", "", [""]], ["_success", false, [true]], ["_message", "", [""]], ["_warnings", [], [[]]]];
if (!hasInterface || {remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}}) exitWith {false};
if (_requestId != missionNamespace getVariable ["Waldo_Conversation_AuthorLastRequest", ""]) exitWith {false};
missionNamespace setVariable ["Waldo_Conversation_AuthorLastResult", [_requestId, _success, _message, +_warnings]];
private _details = if (count _warnings > 0) then {format ["%1 Warning: %2", _message, _warnings joinString "; "]} else {_message};
private _pending = missionNamespace getVariable ["Waldo_Conversation_AuthorPendingRequest", []];
if ((_pending param [0, ""]) == _requestId) then {
    _pending params [["_pendingRequestId", "", [""]], ["_display", displayNull, [displayNull]], ["_mode", "NONE", [""]], ["_definition", [], [[]]]];
    if (!isNull _display) then {
        private _status = _display getVariable ["WaldoConvAuthor_Status", controlNull];
        private _theme = _display getVariable ["WaldoEcoCore_PromptTheme", [] call Waldo_fnc_UiTheme];
        if (_success) then {
            private _id = _definition param [0, ""];
            private _fingerprints = missionNamespace getVariable ["Waldo_Conversation_AuthorLiveFingerprints", createHashMap];
            _fingerprints set [_id, str _definition];
            missionNamespace setVariable ["Waldo_Conversation_AuthorLiveFingerprints", _fingerprints];
            _display setVariable ["WaldoConvAuthor_Dirty", false];
            private _outcome = switch (_mode) do {
                case "TARGET": {"LIVE NOW — saved and applied to this NPC."};
                case "GROUP": {"LIVE NOW — saved and applied to this NPC's group."};
                default {"SAVED FOR LATER — available in Conversation: Assign."};
            };
            _display setVariable ["WaldoConvAuthor_LastWorkflowState", if (_mode == "TARGET") then {"LIVE_TARGET"} else {if (_mode == "GROUP") then {"LIVE_GROUP"} else {"SAVED"}}];
            if (!isNull _status) then {_status ctrlSetStructuredText parseText format ["<t color='%1'>%2</t>", _theme getOrDefault ["successHex", "#6CE5A8"], _outcome]};
        } else {
            _display setVariable ["WaldoConvAuthor_LastWorkflowState", "FAILED"];
            if (!isNull _status) then {
                _status ctrlSetStructuredText parseText format ["<t color='%1'>NOT APPLIED</t>  %2", _theme getOrDefault ["warningHex", "#FFD166"], _details];
            };
        };
        if (!isNull _status) then {_status ctrlCommit 0};
    };
};
["CONVERSATION", _details, if (_success) then {"SUCCESS"} else {"WARNING"}, "CONVERSATION_AUTHOR", 8]
    call Waldo_fnc_FeatureNotifyLocal;
_success
