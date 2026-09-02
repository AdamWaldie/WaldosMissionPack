/*
 * Author: WaldoTheWarfighter
 * Opens the persistent three-pane ZEN Conversation Author for code-free branching definitions.
 * Drafts, nodes, ordered lines and ordered choices are edited in one modal theme-aware display;
 * registration remains server-authoritative and export remains client-local.
 * Locality/authority: curator interface presentation only. It may retain an optional living NPC
 * target for later authenticated direct assignment.
 * Repeat/JIP behaviour: drafts live in missionNamespace and survive editor closure during this
 * mission session; reopening replaces the prior owned prompt and restores the last draft.
 * Arguments: optional target OBJECT. Return Value: DISPLAY or displayNull.
 * Current caller: ZEN Conversation: Author module.
 * Example: [cursorObject] call Waldo_fnc_ConversationAuthorOpenLocal;
 */
params [["_target", objNull, [objNull]]];
if (!hasInterface) exitWith {displayNull};
if (!isNull _target && {!(_target isKindOf "CAManBase")}) then {_target = objNull};
private _display = ["  WMP  //  CONVERSATION AUTHOR", true] call Waldo_fnc_EcoCore_createZeusPromptDisplay;
if (isNull _display) exitWith {displayNull};
private _theme = _display getVariable ["WaldoEcoCore_PromptTheme", [] call Waldo_fnc_UiTheme];
private _drafts = missionNamespace getVariable ["Waldo_Conversation_AuthorDrafts", []];
if !(_drafts isEqualType [] && {count _drafts > 0}) then {
    _drafts = [["MY_CONVERSATION", [
        ["START", [["Hello. What would you like to know?", "", -1, -1, ""]], [
            ["Tell me about this place.", "ABOUT", "ASK_ABOUT"],
            ["Goodbye.", "", "GOODBYE"]
        ], ""],
        ["ABOUT", [["This is an example second part. Replace this text with your own.", "", -1, -1, ""]], [], ""]
    ], "START"]];
};
_display setVariable ["WaldoConvAuthor_Drafts", _drafts];
_display setVariable ["WaldoConvAuthor_DraftIndex", (missionNamespace getVariable ["Waldo_Conversation_AuthorDraftIndex", 0]) min (count _drafts - 1)];
_display setVariable ["WaldoConvAuthor_NodeIndex", 0];
_display setVariable ["WaldoConvAuthor_LineIndex", 0];
_display setVariable ["WaldoConvAuthor_ChoiceIndex", 0];
_display setVariable ["WaldoConvAuthor_Target", _target];
_display setVariable ["WaldoConvAuthor_Refreshing", false];
private _makeText = {
    params ["_class", "_position", "_text", ["_background", [0,0,0,0]]];
    private _control = _display ctrlCreate [_class, -1];
    _control ctrlSetPosition _position;
    if (_class == "RscStructuredText") then {_control ctrlSetStructuredText parseText _text} else {_control ctrlSetText _text};
    _control ctrlSetTextColor (_theme getOrDefault ["text", [0.9,0.96,1,1]]);
    _control ctrlSetBackgroundColor _background;
    _control ctrlCommit 0;
    _control
};
private _nextButtonIdc = 9100;
private _makeButton = {
    params ["_position", "_text"];
    private _control = _display ctrlCreate ["RscButton", _nextButtonIdc];
    _nextButtonIdc = _nextButtonIdc + 1;
    _control ctrlSetPosition _position; _control ctrlSetText _text; _control ctrlCommit 0; _control
};
// Pane backgrounds precede every interactive control.
{["RscText", _x, "", _theme getOrDefault ["panelAlt", [0.035,0.065,0.095,0.99]]] call _makeText} forEach [
    [0.045,0.255,0.275,0.475], [0.33,0.255,0.31,0.475], [0.65,0.255,0.305,0.475]
];
[
    "RscStructuredText",
    [0.05,0.125,0.90,0.055],
    "<t size='0.76' color='#79C7FF'>BUILD A CONVERSATION IN FOUR STEPS</t><br/><t size='0.66'>1. Add conversation parts.  2. Write what the NPC says.  3. Add the player's answers and choose where each answer goes.  4. Check it, then give it to the NPC.</t>"
] call _makeText;
private _targetText = if (isNull _target) then {"AUTHOR-ONLY MODE — place on a living NPC to enable direct assignment"} else {format ["DIRECT TARGET: %1", toUpperANSI name _target]};
["RscText", [0.05,0.181,0.90,0.023], _targetText] call _makeText;

["RscText", [0.05,0.205,0.28,0.019], "SAVED CONVERSATIONS"] call _makeText;
["RscText", [0.65,0.205,0.20,0.019], "EDIT CONVERSATION NAME"] call _makeText;
["RscText", [0.855,0.205,0.10,0.019], "BEGINS AT"] call _makeText;

private _draftCombo = _display ctrlCreate ["RscCombo", -1]; _draftCombo ctrlSetPosition [0.05,0.225,0.23,0.032]; _draftCombo ctrlSetTooltip "Switch between conversations saved during this mission."; _draftCombo ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_DraftCombo", _draftCombo];
private _draftNew = [[0.285,0.225,0.11,0.032], "NEW CONVERSATION"] call _makeButton; _draftNew ctrlSetTooltip "Start another conversation with an example branch.";
private _draftDuplicate = [[0.40,0.225,0.12,0.032], "COPY CONVERSATION"] call _makeButton; _draftDuplicate ctrlSetTooltip "Copy this whole conversation and select the new copy.";
private _draftDelete = [[0.525,0.225,0.11,0.032], "DELETE CONVERSATION"] call _makeButton; _draftDelete ctrlSetTooltip "Delete this saved conversation. At least one must remain.";
_display setVariable ["WaldoConvAuthor_DraftButtons", [_draftNew, _draftDuplicate, _draftDelete]];
private _idEdit = _display ctrlCreate ["RscEdit", -1]; _idEdit ctrlSetPosition [0.65,0.225,0.20,0.032]; _idEdit ctrlSetTooltip "Type a new conversation name, then click elsewhere to apply it."; _idEdit ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_Id", _idEdit];
private _startCombo = _display ctrlCreate ["RscCombo", -1]; _startCombo ctrlSetPosition [0.855,0.225,0.10,0.032]; _startCombo ctrlSetTooltip "The first conversation part the player sees."; _startCombo ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_StartNode", _startCombo];

["RscText", [0.055,0.275,0.25,0.025], "1  CONVERSATION PARTS"] call _makeText;
private _nodeList = _display ctrlCreate ["RscListbox", -1]; _nodeList ctrlSetPosition [0.055,0.302,0.255,0.205]; _nodeList ctrlSetTooltip "A part is one moment in the conversation. Answers can jump to another part."; _nodeList ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_NodeList", _nodeList];
private _nodeButtons = [];
{
    _x params ["_position", "_label", "_help"];
    private _button = [_position, _label] call _makeButton;
    _button ctrlSetTooltip _help;
    _nodeButtons pushBack _button;
} forEach [
    [[0.055,0.518,0.080,0.031], "ADD PART", "Add a new conversation part."],
    [[0.139,0.518,0.080,0.031], "COPY PART", "Copy the selected part and select the new copy."],
    [[0.223,0.518,0.087,0.031], "DELETE PART", "Delete the selected part. At least one must remain."],
    [[0.055,0.553,0.125,0.031], "MOVE EARLIER", "Move the selected part one place earlier."],
    [[0.185,0.553,0.125,0.031], "MOVE LATER", "Move the selected part one place later."]
];
_display setVariable ["WaldoConvAuthor_NodeButtons", _nodeButtons];
["RscText", [0.055,0.594,0.13,0.023], "SELECTED PART NAME"] call _makeText;
private _nodeId = _display ctrlCreate ["RscEdit", -1]; _nodeId ctrlSetPosition [0.185,0.589,0.125,0.032]; _nodeId ctrlSetTooltip "Type a new part name, then click elsewhere. Every route to the old name is updated automatically."; _nodeId ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_NodeId", _nodeId];
["RscText", [0.055,0.631,0.11,0.023], "IF NO ANSWERS"] call _makeText;
private _autoNext = _display ctrlCreate ["RscCombo", -1]; _autoNext ctrlSetPosition [0.165,0.626,0.145,0.032]; _autoNext ctrlSetTooltip "Used only when this part has no player answers. Choose END to finish."; _autoNext ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_AutoNext", _autoNext];
private _routeHelp = ["RscStructuredText", [0.055,0.664,0.255,0.048], "<t size='0.64'>Select a part to see where its answers lead.</t>"] call _makeText;
_display setVariable ["WaldoConvAuthor_RouteHelp", _routeHelp];

["RscText", [0.34,0.275,0.285,0.025], "2  WHAT THIS NPC SAYS"] call _makeText;
private _lineList = _display ctrlCreate ["RscListbox", -1]; _lineList ctrlSetPosition [0.34,0.302,0.29,0.118]; _lineList ctrlSetTooltip "Select a line to edit it below. The highlighted line is the one changed by the buttons."; _lineList ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_LineList", _lineList];
private _lineButtons = [];
{
    _x params ["_position", "_label", "_help"];
    private _button = [_position, _label] call _makeButton;
    _button ctrlSetTooltip _help;
    _lineButtons pushBack _button;
} forEach [
    [[0.340,0.426,0.090,0.031], "ADD LINE", "Add another NPC line to this part."],
    [[0.434,0.426,0.090,0.031], "COPY LINE", "Copy the highlighted NPC line and select the new copy."],
    [[0.528,0.426,0.102,0.031], "DELETE LINE", "Delete the highlighted NPC line."],
    [[0.340,0.462,0.143,0.031], "MOVE EARLIER", "Move the highlighted line one place earlier."],
    [[0.487,0.462,0.143,0.031], "MOVE LATER", "Move the highlighted line one place later."]
];
_display setVariable ["WaldoConvAuthor_LineButtons", _lineButtons];
["RscText", [0.34,0.501,0.18,0.023], "EDIT HIGHLIGHTED NPC LINE"] call _makeText;
private _lineText = _display ctrlCreate ["RscEditMulti", -1]; _lineText ctrlSetPosition [0.34,0.525,0.29,0.068]; _lineText ctrlSetTooltip "The subtitle spoken by the NPC in the highlighted row."; _lineText ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_LineText", _lineText];
["RscText", [0.34,0.601,0.08,0.023], "SOUND"] call _makeText;
private _soundCombo = _display ctrlCreate ["RscCombo", -1]; _soundCombo ctrlSetPosition [0.42,0.597,0.21,0.032]; _soundCombo ctrlSetTooltip "Optional mission sound. Leave as None for subtitles only."; _soundCombo ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_SoundCombo", _soundCombo];
private _noneSound = _soundCombo lbAdd "None — text timing"; _soundCombo lbSetData [_noneSound, ""];
{
    private _class = configName _x;
    private _label = getText (_x >> "name"); if (_label == "") then {_label = _class};
    private _row = _soundCombo lbAdd format ["%1  [%2]", _label, _class]; _soundCombo lbSetData [_row, _class];
} forEach (configProperties [missionConfigFile >> "CfgSounds", "isClass _x", true]);
_soundCombo lbSetCurSel 0;
["RscText", [0.34,0.637,0.12,0.023], "SOUND LENGTH"] call _makeText;
private _soundDuration = _display ctrlCreate ["RscEdit", -1]; _soundDuration ctrlSetPosition [0.46,0.633,0.055,0.031]; _soundDuration ctrlSetText "AUTO"; _soundDuration ctrlSetTooltip "Sound length in seconds. Leave AUTO to use the sound's normal length."; _soundDuration ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_SoundDuration", _soundDuration];
["RscText", [0.52,0.637,0.07,0.023], "TEXT TIME"] call _makeText;
private _textDuration = _display ctrlCreate ["RscEdit", -1]; _textDuration ctrlSetPosition [0.575,0.633,0.055,0.031]; _textDuration ctrlSetText "AUTO"; _textDuration ctrlSetTooltip "Subtitle time in seconds. Leave AUTO to calculate it from the text."; _textDuration ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_TextDuration", _textDuration];
["RscText", [0.34,0.67,0.08,0.023], "GESTURE"] call _makeText;
private _gestureCombo = _display ctrlCreate ["RscCombo", -1]; _gestureCombo ctrlSetPosition [0.42,0.666,0.21,0.032]; _gestureCombo ctrlSetTooltip "Optional gesture played while this line is spoken."; _gestureCombo ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_GestureCombo", _gestureCombo];
{private _row = _gestureCombo lbAdd (_x select 0); _gestureCombo lbSetData [_row, _x select 1]} forEach [["None",""],["Nod","GestureNod"],["Disagree","GestureNo"],["Point","GesturePoint"],["Wave","GestureHi"],["Move on","GestureGo"]];
_gestureCombo lbSetCurSel 0;

["RscText", [0.66,0.275,0.28,0.025], "3  WHAT THE PLAYER CAN SAY"] call _makeText;
private _choiceList = _display ctrlCreate ["RscListbox", -1]; _choiceList ctrlSetPosition [0.66,0.302,0.285,0.118]; _choiceList ctrlSetTooltip "Select an answer to edit it below. The highlighted answer is the one changed by the buttons."; _choiceList ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_ChoiceList", _choiceList];
private _choiceButtons = [];
{
    _x params ["_position", "_label", "_help"];
    private _button = [_position, _label] call _makeButton;
    _button ctrlSetTooltip _help;
    _choiceButtons pushBack _button;
} forEach [
    [[0.660,0.426,0.088,0.031], "ADD ANSWER", "Add a player answer to this part."],
    [[0.752,0.426,0.088,0.031], "COPY ANSWER", "Copy the highlighted answer and select the new copy."],
    [[0.844,0.426,0.101,0.031], "DELETE ANSWER", "Delete the highlighted answer."],
    [[0.660,0.462,0.140,0.031], "MOVE EARLIER", "Move the highlighted answer one place earlier."],
    [[0.805,0.462,0.140,0.031], "MOVE LATER", "Move the highlighted answer one place later."]
];
_display setVariable ["WaldoConvAuthor_ChoiceButtons", _choiceButtons];
["RscText", [0.66,0.501,0.20,0.023], "EDIT HIGHLIGHTED PLAYER ANSWER"] call _makeText;
private _choiceLabel = _display ctrlCreate ["RscEditMulti", -1]; _choiceLabel ctrlSetPosition [0.66,0.525,0.285,0.068]; _choiceLabel ctrlSetTooltip "The player answer shown in the highlighted row."; _choiceLabel ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_ChoiceLabel", _choiceLabel];
["RscText", [0.66,0.601,0.11,0.023], "ANSWER NAME (AUTO)"] call _makeText;
private _choiceId = _display ctrlCreate ["RscEdit", -1]; _choiceId ctrlSetPosition [0.77,0.597,0.175,0.032]; _choiceId ctrlSetTooltip "A stable internal name for this answer. The generated name is safe to keep."; _choiceId ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_ChoiceId", _choiceId];
["RscText", [0.66,0.637,0.10,0.023], "THEN GO TO"] call _makeText;
private _choiceDestination = _display ctrlCreate ["RscCombo", -1]; _choiceDestination ctrlSetPosition [0.755,0.633,0.19,0.032]; _choiceDestination ctrlSetTooltip "Choose the next conversation part, or END to finish."; _choiceDestination ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_ChoiceDestination", _choiceDestination];
["RscStructuredText", [0.66,0.67,0.285,0.04], "<t size='0.64'>Choose another part to continue, or END to finish.</t>"] call _makeText;

private _status = ["RscStructuredText", [0.05,0.742,0.90,0.055], "Not yet validated."] call _makeText;
_display setVariable ["WaldoConvAuthor_Status", _status];
private _removeCheck = _display ctrlCreate ["RscCheckBox", -1]; _removeCheck ctrlSetPosition [0.05,0.802,0.026,0.026]; _removeCheck cbSetChecked false; _removeCheck ctrlSetTooltip "Remove the assignment after the NPC completes it once."; _removeCheck ctrlCommit 0;
_display setVariable ["WaldoConvAuthor_RemoveAfter", _removeCheck];
["RscText", [0.078,0.802,0.12,0.026], "ONE USE ONLY"] call _makeText;
private _validate = [[0.36,0.798,0.10,0.033], "4  CHECK"] call _makeButton; _validate ctrlSetTooltip "Check names and links without saving to the server.";
private _register = [[0.465,0.798,0.12,0.033], "SAVE FOR LATER"] call _makeButton; _register ctrlSetTooltip "Save on the server so this name appears in Conversation: Assign. This does not assign an NPC now.";
private _assign = [[0.59,0.798,0.15,0.033], "APPLY TO THIS NPC"] call _makeButton; _assign ctrlSetTooltip "Save the current draft and make this selected NPC use it immediately.";
private _assignGroup = [[0.745,0.798,0.17,0.033], "APPLY TO THIS GROUP"] call _makeButton; _assignGroup ctrlSetTooltip "Save the current draft and make every NPC in the selected NPC's group use it immediately.";
_assign ctrlEnable (!isNull _target && {alive _target}); _assignGroup ctrlEnable (!isNull _target && {alive _target});
private _exportConfig = [[0.05,0.84,0.18,0.035], "EXPORT CONFIG (CODE ONLY)"] call _makeButton; _exportConfig ctrlSetTooltip "Generate config code only. This does not save or update any live NPC.";
private _exportScript = [[0.235,0.84,0.18,0.035], "EXPORT SCRIPT (CODE ONLY)"] call _makeButton; _exportScript ctrlSetTooltip "Generate server-script code only. This does not save or update any live NPC.";
private _close = [[0.82,0.84,0.13,0.035], "SAVE + CLOSE"] call _makeButton;
_close ctrlSetTooltip "Keep this conversation in the current mission session and close the editor.";
_display setVariable ["WaldoConvAuthor_ActionButtons", [_validate, _register, _assign, _assignGroup, _exportConfig, _exportScript, _close]];

_draftCombo ctrlAddEventHandler ["LBSelChanged", {params ["_control","_index"]; private _display = ctrlParent _control; if !(_display getVariable ["WaldoConvAuthor_Refreshing",false]) then {[_display] call Waldo_fnc_ConversationAuthorSaveLocal; _display setVariable ["WaldoConvAuthor_DraftIndex",_index]; missionNamespace setVariable ["Waldo_Conversation_AuthorDraftIndex",_index]; _display setVariable ["WaldoConvAuthor_NodeIndex",0]; _display setVariable ["WaldoConvAuthor_LineIndex",0]; _display setVariable ["WaldoConvAuthor_ChoiceIndex",0]; [_display] call Waldo_fnc_ConversationAuthorRefreshLocal}}];
_nodeList ctrlAddEventHandler ["LBSelChanged", {params ["_control","_index"]; private _display = ctrlParent _control; if !(_display getVariable ["WaldoConvAuthor_Refreshing",false]) then {[_display] call Waldo_fnc_ConversationAuthorSaveLocal; _display setVariable ["WaldoConvAuthor_NodeIndex",_index]; _display setVariable ["WaldoConvAuthor_LineIndex",0]; _display setVariable ["WaldoConvAuthor_ChoiceIndex",0]; [_display] call Waldo_fnc_ConversationAuthorRefreshLocal}}];
_lineList ctrlAddEventHandler ["LBSelChanged", {params ["_control","_index"]; private _display = ctrlParent _control; if !(_display getVariable ["WaldoConvAuthor_Refreshing",false]) then {[_display] call Waldo_fnc_ConversationAuthorSaveLocal; _display setVariable ["WaldoConvAuthor_LineIndex",_index]; [_display] call Waldo_fnc_ConversationAuthorRefreshLocal}}];
_choiceList ctrlAddEventHandler ["LBSelChanged", {params ["_control","_index"]; private _display = ctrlParent _control; if !(_display getVariable ["WaldoConvAuthor_Refreshing",false]) then {[_display] call Waldo_fnc_ConversationAuthorSaveLocal; _display setVariable ["WaldoConvAuthor_ChoiceIndex",_index]; [_display] call Waldo_fnc_ConversationAuthorRefreshLocal}}];
{
    _x ctrlAddEventHandler ["SetFocus", {
        (ctrlParent (_this select 0)) setVariable ["WaldoConvAuthor_NameIssue", ""];
    }];
    _x ctrlAddEventHandler ["KillFocus", {
        private _display = ctrlParent (_this select 0);
        if !(_display getVariable ["WaldoConvAuthor_Refreshing", false]) then {
            [_display] call Waldo_fnc_ConversationAuthorSaveLocal;
            [_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
            [_display, false] call Waldo_fnc_ConversationAuthorValidateLocal;
        };
    }];
} forEach [_idEdit, _nodeId];
private _operationMap = createHashMap;
{
    _x params ["_button","_operation"];
    _operationMap set [str (ctrlIDC _button), _operation];
    _button ctrlAddEventHandler ["ButtonClick", {
        params ["_control"];
        private _display = ctrlParent _control;
        private _operation = (_display getVariable ["WaldoConvAuthor_OperationMap", createHashMap]) getOrDefault [str (ctrlIDC _control), ""];
        [_display, _operation] call Waldo_fnc_ConversationAuthorMutateLocal
    }];
} forEach [
    [_draftNew, "DRAFT_NEW"],
    [_draftDuplicate, "DRAFT_DUPLICATE"],
    [_draftDelete, "DRAFT_DELETE"],
    [_nodeButtons select 0, "NODE_ADD"],
    [_nodeButtons select 1, "NODE_DUPLICATE"],
    [_nodeButtons select 2, "NODE_DELETE"],
    [_nodeButtons select 3, "NODE_UP"],
    [_nodeButtons select 4, "NODE_DOWN"],
    [_lineButtons select 0, "LINE_ADD"],
    [_lineButtons select 1, "LINE_DUPLICATE"],
    [_lineButtons select 2, "LINE_DELETE"],
    [_lineButtons select 3, "LINE_UP"],
    [_lineButtons select 4, "LINE_DOWN"],
    [_choiceButtons select 0, "CHOICE_ADD"],
    [_choiceButtons select 1, "CHOICE_DUPLICATE"],
    [_choiceButtons select 2, "CHOICE_DELETE"],
    [_choiceButtons select 3, "CHOICE_UP"],
    [_choiceButtons select 4, "CHOICE_DOWN"]
];
_display setVariable ["WaldoConvAuthor_OperationMap", _operationMap];
_validate ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display,true] call Waldo_fnc_ConversationAuthorValidateLocal}];
_register ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display,"NONE"] call Waldo_fnc_ConversationAuthorSubmitLocal}];
_assign ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display,"TARGET"] call Waldo_fnc_ConversationAuthorSubmitLocal}];
_assignGroup ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display,"GROUP"] call Waldo_fnc_ConversationAuthorSubmitLocal}];
_exportConfig ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display,"CONFIG"] call Waldo_fnc_ConversationAuthorExportLocal}];
_exportScript ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display,"SCRIPT"] call Waldo_fnc_ConversationAuthorExportLocal}];
_close ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display] call Waldo_fnc_ConversationAuthorSaveLocal; _display closeDisplay 2}];
_display displayAddEventHandler ["Unload", {params ["_display"]; missionNamespace setVariable ["Waldo_Conversation_AuthorDrafts", _display getVariable ["WaldoConvAuthor_Drafts",[]]]}];

[_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
[_display,false] call Waldo_fnc_ConversationAuthorValidateLocal;
[_display] call Waldo_fnc_EcoCore_fitPromptDisplay;
_display
