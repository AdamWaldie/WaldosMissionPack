/*
 * Author: WaldoTheWarfighter
 * Saves and validates the selected Conversation Author draft, then renders errors and non-blocking
 * graph warnings in the editor's shared validation region.
 * Locality/authority: interface-local preview; the server repeats the same validation on submit.
 * Repeat/JIP behaviour: deterministic local feedback with no persistent or world state.
 * Arguments: editor DISPLAY, notify BOOL default false. Return Value: validation ARRAY.
 * Current callers: Conversation Author Validate, submit and export controls.
 * Example: private _result = [_display,true] call Waldo_fnc_ConversationAuthorValidateLocal;
 */
params [["_display", displayNull, [displayNull]], ["_notify", false, [true]]];
if (isNull _display) exitWith {[false, ["editor display is unavailable"], []]};
[_display] call Waldo_fnc_ConversationAuthorSaveLocal;
private _drafts = _display getVariable ["WaldoConvAuthor_Drafts", []];
private _definition = _drafts param [_display getVariable ["WaldoConvAuthor_DraftIndex", 0], []];
private _result = [_definition] call Waldo_fnc_ConversationValidateData;
private _status = _display getVariable ["WaldoConvAuthor_Status", controlNull];
private _theme = _display getVariable ["WaldoEcoCore_PromptTheme", [] call Waldo_fnc_UiTheme];
private _text = if (_result select 0) then {
    if (count (_result select 2) == 0) then {
        format ["<t color='%1'>LOOKS GOOD</t>  This conversation has %2 part(s) and is ready to save or copy.", _theme getOrDefault ["successHex", "#6CE5A8"], count (_definition param [1, []])]
    } else {
        format ["<t color='%1'>WORKS, BUT CHECK THIS</t>  %2", _theme getOrDefault ["warningHex", "#FFD166"], (_result select 2) joinString "; "]
    }
} else {
    format ["<t color='%1'>NEEDS FIXING</t>  %2", _theme getOrDefault ["dangerHex", "#F26B8A"], (_result select 1) joinString "; "]
};
_status ctrlSetStructuredText parseText _text;
_status ctrlCommit 0;
if (_notify) then {
    ["CONVERSATION", if (_result select 0) then {"Conversation definition is valid."} else {format ["Definition invalid: %1", (_result select 1) joinString "; "]}, if (_result select 0) then {"SUCCESS"} else {"WARNING"}, "CONVERSATION_AUTHOR_VALIDATE", 7]
        call Waldo_fnc_FeatureNotifyLocal;
};
_result
