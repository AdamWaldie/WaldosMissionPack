/*
 * Author: WaldoTheWarfighter
 * Exports the selected valid Conversation Author draft either as one dialogueConfig definition row
 * or as a standalone Waldo_fnc_ConversationCreate call. Generated text is copied exactly and no
 * user-authored string is compiled.
 * Locality/authority: interface-local clipboard operation only.
 * Repeat/JIP behaviour: deterministic and does not mutate the draft or server.
 * Arguments: editor DISPLAY, format STRING CONFIG or SCRIPT. Return Value: BOOL.
 * Current callers: Conversation Author export buttons.
 * Example: [_display,"CONFIG"] call Waldo_fnc_ConversationAuthorExportLocal;
 */
params [["_display", displayNull, [displayNull]], ["_format", "CONFIG", [""]]];
if (isNull _display) exitWith {false};
private _validation = [_display, false] call Waldo_fnc_ConversationAuthorValidateLocal;
if !(_validation select 0) exitWith {["CONVERSATION", "Only a valid complete definition can be exported.", "WARNING", "CONVERSATION_AUTHOR_EXPORT", 7] call Waldo_fnc_FeatureNotifyLocal; false};
private _drafts = _display getVariable ["WaldoConvAuthor_Drafts", []];
private _definition = _drafts select (_display getVariable ["WaldoConvAuthor_DraftIndex", 0]);
private _text = str _definition;
if (toUpperANSI _format == "SCRIPT") then {
    _definition params ["_id", "_nodes", "_start"];
    private _nodeTexts = _nodes apply {
        _x params ["_nodeId", "_lines", "_choices", "_next"];
        private _lineTexts = _lines apply {
            _x params ["_lineText", "_sound", "_soundDuration", "_duration", "_gesture"];
            if (_sound == "" && {_soundDuration == -1} && {_duration == -1} && {_gesture == ""}) then {str _lineText} else {
                format ["[objNull, %1, %2, %3, %4, %5]", str _lineText, str _sound, _soundDuration, _duration, str _gesture]
            }
        };
        private _choiceTexts = _choices apply {
            format ["[%1, %2, {true}, {}, %3]", str (_x param [0, ""]), str (_x param [1, ""]), str (_x param [2, ""])]
        };
        format ["[%1, [%2], [%3], {}, %4]", str _nodeId, _lineTexts joinString ", ", _choiceTexts joinString ", ", str _next]
    };
    _text = format ["[%1, [%2], %3] call Waldo_fnc_ConversationCreate;", str _id, _nodeTexts joinString ("," + endl + "    "), str _start];
};
copyToClipboard _text;
diag_log format ["[WMP CONVERSATION EXPORT] format=%1 code=%2", toUpperANSI _format, _text];
["CONVERSATION", if (toUpperANSI _format == "SCRIPT") then {"Standalone ConversationCreate call copied to the clipboard."} else {"dialogueConfig definition row copied to the clipboard."}, "SUCCESS", "CONVERSATION_AUTHOR_EXPORT", 7]
    call Waldo_fnc_FeatureNotifyLocal;
true
