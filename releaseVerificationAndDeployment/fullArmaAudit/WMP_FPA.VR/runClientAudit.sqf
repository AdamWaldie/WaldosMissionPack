/*
 * Author: WaldoTheWarfighter
 * Runs the full-pack audit cases that require a local player interface and real interaction context.
 *
 * Arguments: None.
 * Return Value: Nothing; records assertions through Waldo_QA_fnc_assert and publishes client completion.
 *
 * Example: [] execVM "runClientAudit.sqf";
 * Current caller: auditInitPlayerLocal.sqf when automated audit mode is enabled.
 */

private _suite = missionNamespace getVariable ["Waldo_QA_Suite", "all"];
waitUntil {uiSleep 0.1; missionNamespace getVariable ["Waldo_QA_FeatureRangeClientReady", false]};
["client/mods/required-loaded", {
    private _missing = missionNamespace getVariable ["Waldo_QA_MissingPatches", []];
    ["client/mods/required-loaded", _missing isEqualTo [], _missing] call Waldo_QA_fnc_assert;
}] call Waldo_QA_fnc_case;

["client/runtime", {
    ["client/runtime", hasInterface && {!isNull player}, [clientOwner, profileName]] call Waldo_QA_fnc_assert;
}] call Waldo_QA_fnc_case;

["client/startup/full-pack-init", {
    private _complete = missionNamespace getVariable ["WALDO_INIT_COMPLETE", false];
    private _observed = missionNamespace getVariable ["Waldo_QA_FullPackInitObserved", false];
    ["client/startup/full-pack-init", _complete && {_observed}, [_complete, _observed, diag_tickTime]] call Waldo_QA_fnc_assert;
}] call Waldo_QA_fnc_case;

if (_suite in ["all", "core"]) then {
    ["core/markers/client-renderer", {
        private _handler = missionNamespace getVariable ["Waldo_3DMarker_DrawHandler", -1];
        ["core/markers/client-renderer", _handler >= 0, _handler] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/loading/version-artwork", {
        private _version = missionNamespace getVariable ["Waldo_QA_ExpectedVersion", ""];
        private _screen = (missionNamespace getVariable ["Waldo_QA_Root", ""]) + "Pictures\loading.jpg";
        ["core/loading/version-artwork", _version != "" && {fileExists _screen}, [_version, _screen]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/logistics/mhq-vvd-actions", {
        private _mhq = missionNamespace getVariable ["Waldo_QA_MHQ", objNull];
        (missionNamespace getVariable ["Waldo_QA_VVD", []]) params [["_terminal", objNull], ["_pad", objNull]];
        private _mhqTitles = if (isNull _mhq) then {[]} else {(actionIDs _mhq) apply {(_mhq actionParams _x) param [0, ""]}};
        private _vvdTitles = if (isNull _terminal) then {[]} else {(actionIDs _terminal) apply {(_terminal actionParams _x) param [0, ""]}};
        private _mhqDeployCount = {_x find "Deploy Command Post" >= 0} count _mhqTitles;
        private _mhqTearCount = {_x find "Tear Down Command Post" >= 0} count _mhqTitles;
        private _vvdOpenCount = {_x find "Open Vehicle Garage" >= 0} count _vvdTitles;
        private _vvdClearCount = {_x find "Clear Depot Spawn Area" >= 0} count _vvdTitles;
        private _displayDefined = isClass (missionConfigFile >> "GarageLoadDisplay");
        private _installed = !isNull _mhq && {!isNull _terminal}
            && {_mhq getVariable ["Waldo_MHQ_LocalActionsInstalled", false]}
            && {_terminal getVariable ["Waldo_VVD_LocalActionsInstalled", false]};
        private _aceOnly = (_mhq getVariable ["Waldo_MHQ_InteractionMode", ""]) == "ACE"
            && {_mhq getVariable ["Waldo_MHQ_ACEActionsInstalled", false]}
            && {(count (_mhq getVariable ["Waldo_MHQ_ACEActionPaths", []])) == 3}
            && {_mhqDeployCount == 0 && {_mhqTearCount == 0} && {_vvdOpenCount == 0} && {_vvdClearCount == 0}};
        ["core/logistics/mhq-vvd-actions", _installed && {_displayDefined} && {_aceOnly}, [_mhqTitles, _vvdTitles, _displayDefined, _mhq getVariable ["Waldo_MHQ_InteractionMode", "NONE"], count (_mhq getVariable ["Waldo_MHQ_ACEActionPaths", []])]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/zen/all-module-families", {
        private _coreCount = missionNamespace getVariable ["Waldo_ZenModuleCount", 0];
        private _economyCount = missionNamespace getVariable ["WaldoEcoCore_ZenModuleCount", 0];
        ["core/zen/all-module-families", _coreCount == 52 && {_economyCount == 19}, [_coreCount, _economyCount]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/zen/icons-present", {
        private _icons = [
            "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa",
            "\a3\modules_f\data\portraitmodule_ca.paa",
            "\a3\Missions_F_Orange\Data\Img\Showcase_LawsOfWar\action_end_sim_CA.paa",
            "\z\ACE\addons\medical_gui\ui\cross.paa",
            "\z\ACE\addons\fortify\ui\hammer_ca.paa",
            "\A3\ui_f\data\map\vehicleicons\iconTruck_ca.paa",
            "\A3\ui_f\data\map\vehicleicons\iconMan_ca.paa",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\attack_ca.paa",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa",
            "\a3\ui_f\data\map\markers\military\destroy_ca.paa",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\backpack_ca.paa"
        ];
        private _missing = _icons select {!(fileExists _x)};
        ["core/zen/icons-present", _missing isEqualTo [], _missing] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/dialogue/live-presentation", {
        private _speaker = (missionNamespace getVariable ["Waldo_QA_DialogueUnits", []]) param [4, objNull];
        private _originalPosition = getPosATL player;
        private _lipObserved = false;
        private _lookAtObserved = false;
        private _choicesShown = false;
        private _compact = false;
        private _layoutAdaptive = false;
        private _cleaned = false;
        private _failOpenCleanup = false;
        private _session = "";
        if (!isNull _speaker) then {
            player setPosATL ((getPosATL _speaker) vectorAdd [0, -2, 0]);
            player setVelocity [0, 0, 0];
            uiSleep 0.75;
            [_speaker, player] remoteExecCall ["Waldo_fnc_DialogueRequestStartServer", 2];
            private _lipDeadline = diag_tickTime + 8;
            waitUntil {
                uiSleep 0.05;
                _lipObserved = _speaker getVariable ["Waldo_Dialogue_RandomLipActiveLocal", false];
                _lipObserved || {diag_tickTime >= _lipDeadline}
            };
            private _lookDeadline = diag_tickTime + 3;
            waitUntil {
                uiSleep 0.05;
                _lookAtObserved = (missionNamespace getVariable ["Waldo_Dialogue_LastLookRequestLocal", []])
                    isEqualTo [netId _speaker, netId player, true];
                _lookAtObserved || {diag_tickTime >= _lookDeadline}
            };
            private _choiceDeadline = diag_tickTime + 12;
            waitUntil {
                uiSleep 0.05;
                _session = uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""];
                _choicesShown = _session != ""
                    && {count (uiNamespace getVariable ["Waldo_Conversation_ChoiceButtons", []]) == 3}
                    && {!isNull (uiNamespace getVariable ["Waldo_Conversation_ChoiceDisplay", displayNull])}
                    && {(uiNamespace getVariable ["Waldo_Conversation_ChoiceKeyHandler", -1]) < 0};
                _choicesShown || {diag_tickTime >= _choiceDeadline}
            };
            if (_choicesShown) then {
                private _controls = uiNamespace getVariable ["Waldo_Conversation_ChoiceControls", []];
                private _buttons = uiNamespace getVariable ["Waldo_Conversation_ChoiceButtons", []];
                private _panelWidth = if (count _controls > 0) then {(ctrlPosition (_controls select 0)) select 2} else {safeZoneW};
                _compact = _panelWidth <= (safeZoneW * 0.34 + pixelW)
                    && {_panelWidth < safeZoneW * 0.48}
                    && {_buttons findIf {((ctrlPosition _x) select 2) > _panelWidth} < 0};
            };
            [_speaker, player, _session, "QA_AUDIT_COMPLETE"] remoteExecCall ["Waldo_fnc_ConversationCancel", 2];
            private _cleanupDeadline = diag_tickTime + 5;
            waitUntil {
                uiSleep 0.05;
                _cleaned = (uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""]) == ""
                    && {!(_speaker getVariable ["Waldo_Dialogue_RandomLipActiveLocal", false])};
                _cleaned || {diag_tickTime >= _cleanupDeadline}
            };
            [_speaker, player] remoteExecCall ["Waldo_fnc_DialogueRequestStartServer", 2];
            private _secondPanelDeadline = diag_tickTime + 12;
            waitUntil {
                uiSleep 0.05;
                (uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""]) != ""
                    || {diag_tickTime >= _secondPanelDeadline}
            };
            player setPosATL ((getPosATL _speaker) vectorAdd [0, -10, 0]);
            private _failOpenDeadline = diag_tickTime + 3;
            waitUntil {
                uiSleep 0.05;
                _failOpenCleanup = (uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""]) == ""
                    && {isNull (uiNamespace getVariable ["Waldo_Conversation_ChoiceDisplay", displayNull])};
                _failOpenCleanup || {diag_tickTime >= _failOpenDeadline}
            };
            player setPosATL _originalPosition;
            private _layoutChoices = [];
            for "_index" from 1 to 8 do {
                _layoutChoices pushBack [format ["QA_LAYOUT_%1", _index], format ["Option %1 is deliberately long enough to wrap cleanly while preserving every word and making the response list scroll when the available screen height is exhausted.", _index], true, _index == 1];
            };
            [_speaker, "QA_LAYOUT_LOCAL", _layoutChoices] call Waldo_fnc_ConversationShowChoicesLocal;
            private _layoutDeadline = diag_tickTime + 4;
            waitUntil {
                uiSleep 0.05;
                count (uiNamespace getVariable ["Waldo_Conversation_ChoiceButtons", []]) == 8
                    || {diag_tickTime >= _layoutDeadline}
            };
            private _layoutControls = uiNamespace getVariable ["Waldo_Conversation_ChoiceControls", []];
            private _layoutButtons = uiNamespace getVariable ["Waldo_Conversation_ChoiceButtons", []];
            if (count _layoutControls >= 3 && {count _layoutButtons == 8}) then {
                private _layoutFrame = _layoutControls select 0;
                private _layoutGroup = _layoutControls select 2;
                private _lastPosition = ctrlPosition (_layoutButtons select 7);
                _layoutAdaptive = ((ctrlPosition _layoutFrame) select 2) <= (safeZoneW * 0.34 + pixelW)
                    && {((ctrlPosition _layoutFrame) select 3) <= (safeZoneH * 0.42 + safeZoneH * 0.02)}
                    && {_layoutButtons findIf {ctrlTextHeight _x > ((ctrlPosition _x) select 3) + pixelH} < 0}
                    && {(_lastPosition select 1) + (_lastPosition select 3) > ((ctrlPosition _layoutGroup) select 3)};
            };
            ["QA_LAYOUT_LOCAL"] call Waldo_fnc_ConversationHideChoicesLocal;
        };
        ["core/dialogue/live-presentation", !isNull _speaker && {_lipObserved} && {_lookAtObserved} && {_choicesShown} && {_compact} && {_layoutAdaptive} && {_cleaned} && {_failOpenCleanup}, [!isNull _speaker, _lipObserved, _lookAtObserved, _choicesShown, _compact, _layoutAdaptive, _cleaned, _failOpenCleanup, missionNamespace getVariable ["Waldo_Dialogue_LastLookRequestLocal", []]]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/dialogue/conversation-author-interactions", {
        private _checks = [];
        private _check = {_checks pushBack _this};
        // The full=true syntax fires ButtonClick handlers; unary ctrlActivate only runs a control's
        // engine action and would silently skip every scripted editor button handler.
        private _press = {_this ctrlActivate true; uiSleep 0.08};
        private _definition = {
            private _display = _this;
            private _drafts = _display getVariable ["WaldoConvAuthor_Drafts", []];
            _drafts param [_display getVariable ["WaldoConvAuthor_DraftIndex", 0], []]
        };
        private _waitForAuthorResult = {
            private _deadline = diag_tickTime + 8;
            waitUntil {
                uiSleep 0.05;
                count (missionNamespace getVariable ["Waldo_Conversation_AuthorLastResult", []]) == 4
                || {diag_tickTime >= _deadline}
            };
            missionNamespace getVariable ["Waldo_Conversation_AuthorLastResult", []]
        };
        missionNamespace setVariable ["Waldo_Conversation_AuthorDrafts", []];
        missionNamespace setVariable ["Waldo_Conversation_AuthorDraftIndex", 0];
        private _display = [objNull] call Waldo_fnc_ConversationAuthorOpenLocal;
        uiSleep 0.15;
        ["open-author-only", !isNull _display] call _check;
        if (!isNull _display) then {
            private _draftButtons = _display getVariable ["WaldoConvAuthor_DraftButtons", []];
            private _nodeButtons = _display getVariable ["WaldoConvAuthor_NodeButtons", []];
            private _lineButtons = _display getVariable ["WaldoConvAuthor_LineButtons", []];
            private _choiceButtons = _display getVariable ["WaldoConvAuthor_ChoiceButtons", []];
            private _actionButtons = _display getVariable ["WaldoConvAuthor_ActionButtons", []];
            private _allMutationButtons = _draftButtons + _nodeButtons + _lineButtons + _choiceButtons;
            private _expectedOperations = [
                "DRAFT_NEW", "DRAFT_DUPLICATE", "DRAFT_DELETE",
                "NODE_ADD", "NODE_DUPLICATE", "NODE_DELETE", "NODE_UP", "NODE_DOWN",
                "LINE_ADD", "LINE_DUPLICATE", "LINE_DELETE", "LINE_UP", "LINE_DOWN",
                "CHOICE_ADD", "CHOICE_DUPLICATE", "CHOICE_DELETE", "CHOICE_UP", "CHOICE_DOWN"
            ];
            private _operationMap = _display getVariable ["WaldoConvAuthor_OperationMap", createHashMap];
            private _buttonIds = _allMutationButtons apply {ctrlIDC _x};
            private _mappedOperations = _allMutationButtons apply {_operationMap getOrDefault [str (ctrlIDC _x), ""]};
            ["one-button-one-action", count (_buttonIds arrayIntersect _buttonIds) == 18 && {_mappedOperations isEqualTo _expectedOperations}, [_buttonIds, _mappedOperations]] call _check;
            ["author-only-assignment-disabled", count _actionButtons == 7 && {!ctrlEnabled (_actionButtons select 2)} && {!ctrlEnabled (_actionButtons select 3)}] call _check;
            ["initial-disabled-boundaries", !ctrlEnabled (_draftButtons select 2) && {!ctrlEnabled (_nodeButtons select 3)} && {!ctrlEnabled (_lineButtons select 3)} && {!ctrlEnabled (_lineButtons select 4)} && {!ctrlEnabled (_choiceButtons select 3)}] call _check;

            (_draftButtons select 0) call _press;
            ["draft-add", count (_display getVariable ["WaldoConvAuthor_Drafts", []]) == 2] call _check;
            (_draftButtons select 1) call _press;
            ["draft-copy", count (_display getVariable ["WaldoConvAuthor_Drafts", []]) == 3 && {(_display getVariable ["WaldoConvAuthor_LastActionFeedback", ""]) find "Conversation copied" >= 0}] call _check;
            (_draftButtons select 2) call _press;
            ["draft-remove", count (_display getVariable ["WaldoConvAuthor_Drafts", []]) == 2] call _check;

            private _nodesBefore = count (((_display call _definition) param [1, []]));
            (_nodeButtons select 0) call _press;
            ["part-add", count (((_display call _definition) param [1, []])) == _nodesBefore + 1] call _check;
            private _addedPartId = (((( _display call _definition) param [1, []]) select (_display getVariable ["WaldoConvAuthor_NodeIndex", 0])) param [0, ""]);
            (_nodeButtons select 1) call _press;
            private _copiedPartId = (((( _display call _definition) param [1, []]) select (_display getVariable ["WaldoConvAuthor_NodeIndex", 0])) param [0, ""]);
            ["part-copy", count (((_display call _definition) param [1, []])) == _nodesBefore + 2 && {_copiedPartId != _addedPartId} && {(_display getVariable ["WaldoConvAuthor_LastActionFeedback", ""]) find "part copied" >= 0}] call _check;
            (_nodeButtons select 3) call _press;
            ["part-up", (((( _display call _definition) param [1, []]) select (_display getVariable ["WaldoConvAuthor_NodeIndex", 0])) param [0, ""]) == _copiedPartId] call _check;
            (_nodeButtons select 4) call _press;
            ["part-down", (((( _display call _definition) param [1, []]) select (_display getVariable ["WaldoConvAuthor_NodeIndex", 0])) param [0, ""]) == _copiedPartId] call _check;
            (_nodeButtons select 2) call _press;
            ["part-remove", count (((_display call _definition) param [1, []])) == _nodesBefore + 1 && {((( _display call _definition) param [1, []]) findIf {(_x param [0, ""]) == _copiedPartId}) < 0}] call _check;

            private _linesBefore = count (((((_display call _definition) param [1, []]) select (_display getVariable ["WaldoConvAuthor_NodeIndex", 0])) param [1, []]));
            (_lineButtons select 0) call _press;
            ["line-add", count (((((_display call _definition) param [1, []]) select (_display getVariable ["WaldoConvAuthor_NodeIndex", 0])) param [1, []])) == _linesBefore + 1] call _check;
            (_lineButtons select 1) call _press;
            private _lineListText = (_display getVariable ["WaldoConvAuthor_LineList", controlNull]) lbText (_display getVariable ["WaldoConvAuthor_LineIndex", 0]);
            ["line-copy", count (((((_display call _definition) param [1, []]) select (_display getVariable ["WaldoConvAuthor_NodeIndex", 0])) param [1, []])) == _linesBefore + 2 && {_lineListText find "LINE " == 0} && {_lineListText find "NPC " < 0} && {(_display getVariable ["WaldoConvAuthor_LastActionFeedback", ""]) find "NPC line copied" >= 0}] call _check;
            (_lineButtons select 3) call _press;
            ["line-up", (_display getVariable ["WaldoConvAuthor_LineIndex", -1]) == _linesBefore] call _check;
            (_lineButtons select 4) call _press;
            ["line-down", (_display getVariable ["WaldoConvAuthor_LineIndex", -1]) == _linesBefore + 1] call _check;
            (_lineButtons select 2) call _press;
            ["line-remove", count (((((_display call _definition) param [1, []]) select (_display getVariable ["WaldoConvAuthor_NodeIndex", 0])) param [1, []])) == _linesBefore + 1] call _check;

            _display setVariable ["WaldoConvAuthor_NodeIndex", 0];
            _display setVariable ["WaldoConvAuthor_ChoiceIndex", 0];
            [_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
            private _choicesBefore = count (((((_display call _definition) param [1, []]) select 0) param [2, []]));
            (_choiceButtons select 0) call _press;
            ["answer-add", count (((((_display call _definition) param [1, []]) select 0) param [2, []])) == _choicesBefore + 1] call _check;
            (_choiceButtons select 1) call _press;
            ["answer-copy", count (((((_display call _definition) param [1, []]) select 0) param [2, []])) == _choicesBefore + 2 && {(_display getVariable ["WaldoConvAuthor_LastActionFeedback", ""]) find "answer copied" >= 0}] call _check;
            (_choiceButtons select 3) call _press;
            ["answer-up", (_display getVariable ["WaldoConvAuthor_ChoiceIndex", -1]) == _choicesBefore] call _check;
            (_choiceButtons select 4) call _press;
            ["answer-down", (_display getVariable ["WaldoConvAuthor_ChoiceIndex", -1]) == _choicesBefore + 1] call _check;
            (_choiceButtons select 2) call _press;
            ["answer-remove", count (((((_display call _definition) param [1, []]) select 0) param [2, []])) == _choicesBefore + 1] call _check;

            _display setVariable ["WaldoConvAuthor_NodeIndex", 1];
            [_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
            private _partName = _display getVariable ["WaldoConvAuthor_NodeId", controlNull];
            ctrlSetFocus _partName;
            _partName ctrlSetText "DETAILS";
            ctrlSetFocus (_display getVariable ["WaldoConvAuthor_NodeList", controlNull]);
            uiSleep 0.1;
            private _renamedDefinition = _display call _definition;
            private _renamedNodes = _renamedDefinition param [1, []];
            private _inboundUpdated = (((_renamedNodes select 0) param [2, []]) findIf {(_x param [1, ""]) == "DETAILS"}) >= 0;
            ["part-rename-updates-routes", ((_renamedNodes select 1) param [0, ""]) == "DETAILS" && {_inboundUpdated}] call _check;
            ctrlSetFocus _partName;
            _partName ctrlSetText "BAD NAME!";
            ctrlSetFocus (_display getVariable ["WaldoConvAuthor_NodeList", controlNull]);
            uiSleep 0.1;
            ["invalid-part-name-explained", ((((_display call _definition) param [1, []]) select 1) param [0, ""]) == "DETAILS" && {(_display getVariable ["WaldoConvAuthor_NameIssue", ""]) != ""}] call _check;

            private _conversationName = _display getVariable ["WaldoConvAuthor_Id", controlNull];
            ctrlSetFocus _conversationName;
            _conversationName ctrlSetText "QA_AUTHOR_UI";
            ctrlSetFocus (_display getVariable ["WaldoConvAuthor_NodeList", controlNull]);
            uiSleep 0.1;
            ["conversation-rename", ((_display call _definition) param [0, ""]) == "QA_AUTHOR_UI"] call _check;

            _display setVariable ["WaldoConvAuthor_NodeIndex", 0];
            _display setVariable ["WaldoConvAuthor_LineIndex", 0];
            _display setVariable ["WaldoConvAuthor_ChoiceIndex", 0];
            [_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
            private _soundSeconds = _display getVariable ["WaldoConvAuthor_SoundDuration", controlNull];
            private _textSeconds = _display getVariable ["WaldoConvAuthor_TextDuration", controlNull];
            ["automatic-timing-readable", ctrlText _soundSeconds == "AUTO" && {ctrlText _textSeconds == "AUTO"}] call _check;
            _soundSeconds ctrlSetText "2.5";
            _textSeconds ctrlSetText "3";
            (_display getVariable ["WaldoConvAuthor_LineText", controlNull]) ctrlSetText "Edited NPC dialogue.";
            private _gesture = _display getVariable ["WaldoConvAuthor_GestureCombo", controlNull];
            _gesture lbSetCurSel 1;
            [_display] call Waldo_fnc_ConversationAuthorSaveLocal;
            private _editedLine = ((((_display call _definition) param [1, []]) select 0) param [1, []]) select 0;
            ["line-fields-save", (_editedLine param [0, ""]) == "Edited NPC dialogue." && {(_editedLine param [2, -1]) == 2.5} && {(_editedLine param [3, -1]) == 3} && {(_editedLine param [4, ""]) == "GestureNod"}] call _check;
            _soundSeconds ctrlSetText "AUTO";
            _textSeconds ctrlSetText "AUTO";
            [_display] call Waldo_fnc_ConversationAuthorSaveLocal;
            _editedLine = ((((_display call _definition) param [1, []]) select 0) param [1, []]) select 0;
            ["automatic-timing-saves", (_editedLine param [2, 0]) == -1 && {(_editedLine param [3, 0]) == -1}] call _check;

            (_display getVariable ["WaldoConvAuthor_ChoiceLabel", controlNull]) ctrlSetText "Show me the details.";
            (_display getVariable ["WaldoConvAuthor_ChoiceId", controlNull]) ctrlSetText "SHOW_DETAILS";
            private _destination = _display getVariable ["WaldoConvAuthor_ChoiceDestination", controlNull];
            for "_row" from 0 to (lbSize _destination - 1) do {if (_destination lbData _row == "DETAILS") exitWith {_destination lbSetCurSel _row}};
            [_display] call Waldo_fnc_ConversationAuthorSaveLocal;
            private _editedChoice = ((((_display call _definition) param [1, []]) select 0) param [2, []]) select 0;
            ["answer-fields-and-route-save", _editedChoice isEqualTo ["Show me the details.", "DETAILS", "SHOW_DETAILS"]] call _check;

            private _cleanDefinition = ["QA_AUTHOR_REGISTER", [
                ["START", [["Hello.", "", -1, -1, ""]], [["Continue.", "DETAILS", "CONTINUE"]], ""],
                ["DETAILS", [["Done.", "", -1, -1, ""]], [], ""]
            ], "START"];
            _display setVariable ["WaldoConvAuthor_Drafts", [_cleanDefinition]];
            _display setVariable ["WaldoConvAuthor_DraftIndex", 0];
            _display setVariable ["WaldoConvAuthor_NodeIndex", 0];
            _display setVariable ["WaldoConvAuthor_LineIndex", 0];
            _display setVariable ["WaldoConvAuthor_ChoiceIndex", 0];
            [_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
            (_actionButtons select 0) call _press;
            private _validation = [_display, false] call Waldo_fnc_ConversationAuthorValidateLocal;
            ["check-valid-definition", _validation select 0] call _check;
            (_actionButtons select 4) call _press;
            private _configExport = missionNamespace getVariable ["Waldo_Conversation_AuthorLastExport", []];
            private _configPreview = _display getVariable ["WaldoConvAuthor_ExportPreviewControls", []];
            private _configPreviewButtons = _display getVariable ["WaldoConvAuthor_ExportPreviewButtons", []];
            ["config-export-visible-fallback", count _configPreview == 7 && {count _configPreviewButtons == 2} && {ctrlText (_configPreview select 4) find "QA_AUTHOR_REGISTER" >= 0}] call _check;
            (_configPreviewButtons select 0) call _press;
            (_configPreviewButtons select 1) call _press;
            ["config-export-back-to-editor", (_display getVariable ["WaldoConvAuthor_ExportPreviewControls", []]) isEqualTo []] call _check;
            (_actionButtons select 5) call _press;
            private _scriptExport = missionNamespace getVariable ["Waldo_Conversation_AuthorLastExport", []];
            private _scriptPreview = _display getVariable ["WaldoConvAuthor_ExportPreviewControls", []];
            private _scriptPreviewButtons = _display getVariable ["WaldoConvAuthor_ExportPreviewButtons", []];
            ["script-export-visible-fallback", count _scriptPreview == 7 && {count _scriptPreviewButtons == 2} && {ctrlText (_scriptPreview select 4) find "Waldo_fnc_ConversationCreate" >= 0}] call _check;
            (_scriptPreviewButtons select 1) call _press;
            ["both-export-actions", (_configExport param [0, ""]) == "CONFIG" && {(_configExport param [1, ""]) find "QA_AUTHOR_REGISTER" >= 0} && {(_scriptExport param [0, ""]) == "SCRIPT"} && {(_scriptExport param [1, ""]) find "Waldo_fnc_ConversationCreate" >= 0} && {(_display getVariable ["WaldoConvAuthor_LastWorkflowState", ""]) == "CODE_ONLY"}] call _check;

            missionNamespace setVariable ["Waldo_Conversation_AuthorLastResult", []];
            (_actionButtons select 1) ctrlActivate true;
            private _registerResult = call _waitForAuthorResult;
            ["save-for-later", count _registerResult == 4 && {_registerResult param [1, false]} && {(_display getVariable ["WaldoConvAuthor_LastWorkflowState", ""]) == "SAVED"}] call _check;
            (_display getVariable ["WaldoConvAuthor_LineText", controlNull]) ctrlSetText "Automatically updated existing conversation.";
            [_display] call Waldo_fnc_ConversationAuthorSaveLocal;
            [_display, false] call Waldo_fnc_ConversationAuthorValidateLocal;
            ["existing-edit-marked-unapplied", _display getVariable ["WaldoConvAuthor_Dirty", false]] call _check;
            missionNamespace setVariable ["Waldo_Conversation_AuthorLastResult", []];
            (_actionButtons select 1) ctrlActivate true;
            private _updateResult = call _waitForAuthorResult;
            ["automatic-existing-update", count _updateResult == 4 && {_updateResult param [1, false]} && {(_display getVariable ["WaldoConvAuthor_LastWorkflowState", ""]) == "SAVED"} && {!(_display getVariable ["WaldoConvAuthor_Dirty", true])}] call _check;
            (_display getVariable ["WaldoConvAuthor_LineText", controlNull]) ctrlSetText "Unsaved edit after applying.";
            [_display] call Waldo_fnc_ConversationAuthorSaveLocal;
            [_display, false] call Waldo_fnc_ConversationAuthorValidateLocal;
            ["unapplied-change-state", _display getVariable ["WaldoConvAuthor_Dirty", false] && {(_display getVariable ["WaldoConvAuthor_LastWorkflowState", ""]) == "DIRTY"}] call _check;

            (_actionButtons select 6) call _press;
            private _persistedDraft = (missionNamespace getVariable ["Waldo_Conversation_AuthorDrafts", []]) param [0, []];
            ["close-persists-draft", (_persistedDraft param [0, ""]) == "QA_AUTHOR_REGISTER"] call _check;
            _display = [objNull] call Waldo_fnc_ConversationAuthorOpenLocal;
            uiSleep 0.1;
            ["reopen-restores-draft", !isNull _display && {((_display call _definition) param [0, ""]) == "QA_AUTHOR_REGISTER"}] call _check;
            if (!isNull _display) then {((_display getVariable ["WaldoConvAuthor_ActionButtons", []]) select 6) call _press};

            private _targetDeadline = diag_tickTime + 20;
            waitUntil {uiSleep 0.05; count (missionNamespace getVariable ["Waldo_QA_ConversationAuthorTargets", []]) == 3 || {diag_tickTime >= _targetDeadline}};
            private _targets = missionNamespace getVariable ["Waldo_QA_ConversationAuthorTargets", []];
            if (count _targets == 3) then {
                _display = [_targets select 0] call Waldo_fnc_ConversationAuthorOpenLocal;
                uiSleep 0.1;
                _actionButtons = _display getVariable ["WaldoConvAuthor_ActionButtons", []];
                ["npc-mode-enables-direct-actions", ctrlEnabled (_actionButtons select 2) && {ctrlEnabled (_actionButtons select 3)}] call _check;
                private _targetDefinition = +_cleanDefinition;
                _targetDefinition set [0, "QA_AUTHOR_TARGET"];
                _display setVariable ["WaldoConvAuthor_Drafts", [_targetDefinition]];
                [_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
                (_display getVariable ["WaldoConvAuthor_RemoveAfter", controlNull]) cbSetChecked true;
                missionNamespace setVariable ["Waldo_Conversation_AuthorLastResult", []];
                (_actionButtons select 2) ctrlActivate true;
                private _targetResult = call _waitForAuthorResult;
                ["apply-target-one-use", count _targetResult == 4 && {_targetResult param [1, false]} && {(_display getVariable ["WaldoConvAuthor_LastWorkflowState", ""]) == "LIVE_TARGET"}] call _check;
                (_actionButtons select 6) call _press;

                _display = [_targets select 1] call Waldo_fnc_ConversationAuthorOpenLocal;
                uiSleep 0.1;
                _actionButtons = _display getVariable ["WaldoConvAuthor_ActionButtons", []];
                private _groupDefinition = +_cleanDefinition;
                _groupDefinition set [0, "QA_AUTHOR_GROUP"];
                _display setVariable ["WaldoConvAuthor_Drafts", [_groupDefinition]];
                [_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
                missionNamespace setVariable ["Waldo_Conversation_AuthorLastResult", []];
                (_actionButtons select 3) ctrlActivate true;
                private _groupResult = call _waitForAuthorResult;
                ["apply-group", count _groupResult == 4 && {_groupResult param [1, false]} && {(_display getVariable ["WaldoConvAuthor_LastWorkflowState", ""]) == "LIVE_GROUP"}] call _check;
                (_actionButtons select 6) call _press;
            } else {
                ["server-target-fixtures", false, count _targets] call _check;
            };

            private _catalogToken = format ["QA_AUTHOR_CATALOG_%1", diag_tickTime];
            missionNamespace setVariable ["Waldo_Conversation_PendingCatalogToken", _catalogToken];
            missionNamespace setVariable ["Waldo_Conversation_CatalogResponse", []];
            [player, _catalogToken] remoteExecCall ["Waldo_fnc_ZenConversationCatalogServer", 2];
            private _catalogDeadline = diag_tickTime + 8;
            waitUntil {uiSleep 0.05; count (missionNamespace getVariable ["Waldo_Conversation_CatalogResponse", []]) == 3 || {diag_tickTime >= _catalogDeadline}};
            private _catalog = missionNamespace getVariable ["Waldo_Conversation_CatalogResponse", []];
            private _catalogIds = _catalog param [2, []];
            ["late-registration-catalogue", ["QA_AUTHOR_REGISTER", "QA_AUTHOR_TARGET", "QA_AUTHOR_GROUP"] findIf {!(_x in _catalogIds)} < 0] call _check;
        };
        player setVariable ["Waldo_QA_ConversationAuthorClientComplete", true, true];
        private _failed = _checks select {!(_x param [1, false])};
        ["core/dialogue/conversation-author-interactions", _failed isEqualTo [], [_checks, _failed]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "interactions"]) then {
    ["interactions/integration/linked-ace-vanilla-actions", {
        private _objects = missionNamespace getVariable ["Waldo_QA_InteractionObjects", []];
        private _missing = _objects select {
            !(_x getVariable ["Waldo_MG_Int_ACEActionInstalled", false])
            || {!(_x getVariable ["Waldo_QA_ResultACEInstalled", false])}
            || {!(_x getVariable ["Waldo_MG_Int_VanillaActionInstalled", false])}
            || {!(_x getVariable ["Waldo_QA_ResultVanillaInstalled", false])}
        };
        ["interactions/integration/linked-ace-vanilla-actions", (count _objects) == 40 && {_missing isEqualTo []}, [count _objects, _missing apply {netId _x}]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["interactions/integration/ace-action-condition", {
        private _objects = missionNamespace getVariable ["Waldo_QA_InteractionObjects", []];
        private _originalPosition = getPosATL player;
        private _failed = _objects select {
            // The real action condition deliberately includes interaction
            // distance. Evaluate it where a player could actually use it.
            player setPosATL ((getPosATL _x) vectorAdd [0, -1.2, 0]);
            private _action = _x getVariable ["Waldo_MG_Int_ACEAction", []];
            private _path = _x getVariable ["Waldo_MG_Int_ACEActionPath", []];
            (count _action) < 7
            || {!([_x, player, _action select 6] call (_action select 4))}
            || {_path isEqualTo []}
        };
        player setPosATL _originalPosition;
        ["interactions/integration/ace-action-condition", (count _objects) == 40 && {_failed isEqualTo []}, [count _objects, _failed apply {netId _x}]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["interactions/catalogue/ten-procedures", {
        missionNamespace setVariable ["Waldo_MG_ChallengeRegistry", []];
        {
            _x params ["_id", "_opener"];
            [_id, _opener, _id] call Waldo_fnc_MiniGameRegisterChallenge;
        } forEach [
            ["wirecut", Waldo_fnc_MiniGameWireCut], ["minesweeper", Waldo_fnc_MiniGameMinesweeper],
            ["keypad", Waldo_fnc_MiniGameKeypad], ["lockpick", Waldo_fnc_MiniGameLockpick],
            ["circuit", Waldo_fnc_MiniGameCircuit], ["repair", Waldo_fnc_MiniGameRepair],
            ["radiotune", Waldo_fnc_MiniGameRadioTune], ["pressure", Waldo_fnc_MiniGamePressure],
            ["sequence", Waldo_fnc_MiniGameSequence], ["commandinput", Waldo_fnc_MiniGameCommandInput]
        ];
        private _registered = (missionNamespace getVariable ["Waldo_MG_ChallengeRegistry", []]) apply {_x select 0};
        ["interactions/catalogue/ten-procedures", count _registered == 10, _registered] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "party"]) then {
    ["party/integration/linked-ace-vanilla-actions", {
        call Waldo_MG_fnc_ensureTableActionsLocal;
        call Waldo_MG_fnc_ensurePlayerActionsLocal;
        private _table = missionNamespace getVariable ["Waldo_QA_PartyTable", objNull];
        private _actions = if (isNull _table) then {[]} else {_table getVariable ["Waldo_MG_TableACEActions", []]};
        private _paths = if (isNull _table) then {[]} else {_table getVariable ["Waldo_MG_TableACEActionPaths", []]};
        private _vanilla = if (isNull _table) then {[]} else {_table getVariable ["Waldo_MG_TableActionIdsLocal", []]};
        private _sitAvailable = false;
        if ((count _actions) >= 2 && {!isNull _table}) then {
            private _originalPosition = getPosATL player;
            player setPosATL ((getPosATL _table) vectorAdd [0, -1.2, 0]);
            private _sit = _actions select 1;
            _sitAvailable = [_table, player, _sit select 6] call (_sit select 4);
            player setPosATL _originalPosition;
        };
        private _playerActions = missionNamespace getVariable ["Waldo_MG_PlayerACEActionsLocal", []];
        private _ok = !isNull _table
            && {(_table getVariable ["Waldo_MG_TableInteractionMode", ""]) == "ACE+VANILLA"}
            && {(count _actions) == 4}
            && {(count _paths) == 4}
            && {(count _vanilla) == 3}
            && {_sitAvailable}
            && {(count _playerActions) == 2}
            && {(count (missionNamespace getVariable ["Waldo_MG_PlayerActionIdsLocal", []])) == 2};
        ["party/integration/linked-ace-vanilla-actions", _ok, [count _actions, count _paths, _vanilla, _sitAvailable, count _playerActions]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["party/integration/preserves-foreign-actions", {
        private _table = missionNamespace getVariable ["Waldo_QA_PartyTable", objNull];
        private _tableSentinel = -1;
        private _playerSentinel = -1;
        if (!isNull _table) then {
            _tableSentinel = _table addAction ["QA FOREIGN TABLE ACTION", {}];
        };
        if (!isNull player) then {
            _playerSentinel = player addAction ["QA FOREIGN PLAYER ACTION", {}];
        };

        call Waldo_MG_fnc_ensureTableActionsLocal;
        call Waldo_MG_fnc_ensurePlayerActionsLocal;

        private _tablePreserved = !isNull _table && {_tableSentinel >= 0} && {_tableSentinel in (actionIDs _table)};
        private _playerPreserved = !isNull player && {_playerSentinel >= 0} && {_playerSentinel in (actionIDs player)};
        ["party/integration/preserves-foreign-actions", _tablePreserved && {_playerPreserved}, [_tablePreserved, _playerPreserved]] call Waldo_QA_fnc_assert;

        if (_tableSentinel >= 0 && {!isNull _table}) then {_table removeAction _tableSentinel;};
        if (_playerSentinel >= 0 && {!isNull player}) then {player removeAction _playerSentinel;};
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "economy"]) then {
    ["economy/integration/local-ace-actions", {
        private _checks = [
            [missionNamespace getVariable ["qa_economy_crate", objNull], "WaldoEcoResource_CollectActionAddedLocal"],
            [missionNamespace getVariable ["qa_economy_research", objNull], "WaldoEcoResearch_DisplayResourcesAddedLocal"],
            [missionNamespace getVariable ["qa_economy_construction", objNull], "WaldoEcoBuild_PlayerConstructionActionAddedLocal"],
            [missionNamespace getVariable ["qa_economy_terminal", objNull], "WaldoEcoBuy_PurchaseActionAddedLocalV2"]
        ];
        private _failed = _checks select {
            _x params ["_object", "_flag"];
            isNull _object
            || {!(_object getVariable [format ["%1_ACE", _flag], false])}
            || {(_object getVariable [format ["%1_ACEPath", _flag], []]) isEqualTo []}
            || {(count (_object getVariable [format ["%1_ACEAction", _flag], []])) < 7}
        };
        ["economy/integration/local-ace-actions", _failed isEqualTo [], _failed apply {if (isNull (_x select 0)) then {"NULL"} else {netId (_x select 0)}}] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["economy/integration/action-adapter-executes", {
        private _probe = "Land_HelipadEmpty_F" createVehicleLocal [0, 0, 0];
        private _flag = "Waldo_QA_EconomyActionProbe";
        missionNamespace setVariable [_flag, false];
        [_probe, _flag, [
            "Audit Action Probe",
            {missionNamespace setVariable ["Waldo_QA_EconomyActionProbe", true];},
            [], 1.5, true, true, "", "true", 3
        ]] call Waldo_fnc_EcoCore_ensureLocalObjectAction;
        private _action = _probe getVariable [format ["%1_ACEAction", _flag], []];
        if ((count _action) >= 7) then {
            [_probe, player, _action select 6] call (_action select 3);
        };
        private _executed = missionNamespace getVariable [_flag, false];
        deleteVehicle _probe;
        ["economy/integration/action-adapter-executes", _executed, [count _action, _executed]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "ew"]) then {
    ["ew/client/jamming-factor-near-emitter", {
        private _jammer = missionNamespace getVariable ["Waldo_QA_Jammer", objNull];
        private _sample = if (isNull _jammer) then {[]} else {(getPosASL _jammer) vectorAdd [0, 0, 1.7]};
        private _factor = if (_sample isEqualTo []) then {0} else {[_sample, west, -1] call Waldo_fnc_JammingFactor};
        private _ready = missionNamespace getVariable ["Waldo_Jamming_UiRunning", false]
            && {missionNamespace getVariable ["Waldo_Jamming_AcreInstalled", false]};
        ["ew/client/jamming-factor-near-emitter", !isNull _jammer && {_factor > 0.7} && {_ready}, [_factor, _ready, count (missionNamespace getVariable ["Waldo_Jamming_Registry", []])]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

private _passed = call Waldo_QA_fnc_complete;
player setVariable ["Waldo_QA_ClientComplete", [_passed, missionNamespace getVariable ["Waldo_QA_LocalResults", []]], true];
