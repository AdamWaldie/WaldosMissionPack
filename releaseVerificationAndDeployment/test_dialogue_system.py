"""Static regression contracts for Simple Dialogue and Advanced Conversations."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SIMPLE = ROOT / "MissionScripts" / "MissionFlowAndUi" / "Dialogue" / "Simple"
ADVANCED = ROOT / "MissionScripts" / "MissionFlowAndUi" / "Dialogue" / "Advanced"


class DialogueSystemTests(unittest.TestCase):
    def test_components_are_separate_and_registered(self):
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        self.assertIn("class SimpleDialogue", functions)
        self.assertIn("class AdvancedConversations", functions)
        for name in (
            "SimpleDialogue", "SimpleDialogueClear", "DialogueEstimateDuration", "DialogueGetDiagnostics",
            "ConversationCreate", "ConversationRegister", "ConversationAssign",
            "ConversationStart", "ConversationCancel", "ConversationClear",
        ):
            self.assertRegex(functions, rf"class\s+{name}\b")
        self.assertTrue(SIMPLE.is_dir())
        self.assertTrue(ADVANCED.is_dir())

    def test_simple_api_keeps_beginner_and_legacy_forms(self):
        source = (SIMPLE / "simpleDialogue.sqf").read_text(encoding="utf-8")
        self.assertIn('if (_second isEqualType [])', source)
        self.assertIn('if (_upper == "SPECIFIC")', source)
        self.assertIn('if (_upper in keys _catalogue)', source)
        self.assertIn('if ((_upper find "MODERN_") == 0)', source)
        self.assertIn('if ((_upper find "DORNOW_") == 0)', source)
        self.assertIn('count _lines > 32', source)
        self.assertIn('count _x > 500', source)
        self.assertIn('if (!isServer) exitWith {false}', source)
        self.assertNotIn("remoteExecCall [\"call\"", source)

    def test_timing_is_word_based_bounded_and_punctuation_aware(self):
        source = (SIMPLE / "dialogueEstimateDuration.sqf").read_text(encoding="utf-8")
        for token in (
            "Waldo_Dialogue_SecondsPerWord", "Waldo_Dialogue_MinimumLineSeconds",
            "Waldo_Dialogue_MaximumLineSeconds", "Waldo_Dialogue_CommaPause",
            "Waldo_Dialogue_TerminalPause", 'splitString " \\t\\r\\n"',
            "toArray _text", "[44, 59, 58]", "[46, 33, 63]",
        ):
            self.assertIn(token, source)

    def test_server_sessions_enforce_identity_range_lock_and_dynamic_audience(self):
        request = (SIMPLE / "dialogueRequestStartServer.sqf").read_text(encoding="utf-8")
        worker = (SIMPLE / "dialogueRunSimpleServer.sqf").read_text(encoding="utf-8")
        self.assertIn("owner _caller != remoteExecutedOwner", request)
        self.assertIn('activeSession", ""', request)
        self.assertIn("Waldo_Dialogue_InteractionDistance", request)
        self.assertIn("Waldo_Dialogue_RejectedRequestCounts", request)
        self.assertIn("Start rejected reason=", request)
        self.assertIn("Waldo_Dialogue_CancelDistance", worker)
        self.assertIn("Waldo_Dialogue_AudienceRadius", worker)
        self.assertIn("allPlayers select", worker)
        self.assertIn('remoteExecCall ["Waldo_fnc_DialogueAnimateLocal", 0]', worker)
        self.assertIn("isMultiplayer && {!isPlayer _caller}", worker)

    def test_snapshot_and_local_actions_are_jip_repeat_safe(self):
        publish = (SIMPLE / "dialoguePublishState.sqf").read_text(encoding="utf-8")
        receive = (SIMPLE / "dialogueReceiveStateLocal.sqf").read_text(encoding="utf-8")
        install = (SIMPLE / "dialogueApplyActionLocal.sqf").read_text(encoding="utf-8")
        remove = (SIMPLE / "dialogueRemoveActionLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("_keys sort true", publish)
        self.assertIn("Waldo_Dialogue_StateVersion", publish)
        self.assertIn("_version < _currentVersion", receive)
        self.assertIn("Waldo_Dialogue_StateReady", receive)
        self.assertIn("BIS_fnc_holdActionAdd", install)
        self.assertIn("BIS_fnc_filterString", install)
        self.assertNotIn("abs hashValue", install)
        self.assertIn("holdAction_connect_ca.paa", install)
        animate = (SIMPLE / "dialogueAnimateLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("enableMimics true", animate)
        self.assertIn("setRandomLip true", animate)
        self.assertIn("Waldo_Dialogue_RandomLipActiveLocal", animate)
        self.assertIn("if (local _speaker) then", animate)
        self.assertIn("_speaker lookAt _caller", animate)
        self.assertIn("Waldo_Dialogue_LookTargetNetId", animate)
        self.assertIn("Waldo_Dialogue_LastLookRequestLocal", animate)
        self.assertIn("Waldo_Dialogue_PresentationOwner", animate)
        self.assertNotIn("setFormDir", animate)
        self.assertNotIn("setDir", animate)
        self.assertNotIn("doWatch", animate)
        self.assertNotIn("!local _speaker}) exitWith", animate)
        subtitle = (SIMPLE / "dialogueShowLineLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("ctrlTextWidth _control", subtitle)
        self.assertIn("Waldo_Dialogue_SubtitleMaximumWidth", subtitle)
        self.assertIn("Waldo_Dialogue_SubtitleMaximumHeight", subtitle)
        self.assertIn("Waldo_Dialogue_SubtitleTextScale", subtitle)
        self.assertNotIn("safeZoneW * 0.62", subtitle)
        self.assertIn("BIS_fnc_holdActionRemove", remove)
        self.assertNotIn("remoteExec", remove)

    def test_dialogue_diagnostics_cover_authority_jip_actions_and_ui_cleanup(self):
        diagnostics = (SIMPLE / "dialogueGetDiagnostics.sqf").read_text(encoding="utf-8")
        server = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnostics.sqf").read_text(encoding="utf-8")
        client = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnosticsClient.sqf").read_text(encoding="utf-8")
        for token in (
            "server-registry", "advanced-definitions", "presentation-locality", "request-rejections", "responsive-ui-config", "snapshot-authority",
            "ordered-client-snapshot", "local-actions", "choice-ui-cleanup",
        ):
            self.assertIn(token, diagnostics)
        self.assertIn("local _speaker", diagnostics)
        self.assertIn("remoteOwned", diagnostics)
        self.assertIn("Waldo_fnc_DialogueGetDiagnostics", server)
        self.assertIn("Waldo_fnc_DialogueGetDiagnostics", client)

    def test_dialogue_remote_endpoints_and_mutations_enforce_locality(self):
        server_mutations = (
            SIMPLE / "simpleDialogue.sqf",
            SIMPLE / "simpleDialogueClear.sqf",
            ADVANCED / "conversationCreate.sqf",
            ADVANCED / "conversationRegister.sqf",
            ADVANCED / "conversationAssign.sqf",
            ADVANCED / "conversationStart.sqf",
            ADVANCED / "conversationClear.sqf",
        )
        for path in server_mutations:
            with self.subTest(path=path.name):
                source = path.read_text(encoding="utf-8")
                self.assertRegex(source, r"if \(!isServer(?:\)|\s*\|\|)")

        authenticated_endpoints = (
            SIMPLE / "dialogueRequestStateServer.sqf",
            SIMPLE / "dialogueRequestStartServer.sqf",
            ADVANCED / "conversationChooseServer.sqf",
            ADVANCED / "conversationCancel.sqf",
        )
        for path in authenticated_endpoints:
            with self.subTest(path=path.name):
                source = path.read_text(encoding="utf-8")
                self.assertIn("remoteExecutedOwner", source)
                self.assertIn("owner _", source)

        server_only_local_presenters = (
            SIMPLE / "dialogueAnimateLocal.sqf",
            SIMPLE / "dialogueShowLineLocal.sqf",
            SIMPLE / "dialogueHideLocal.sqf",
            ADVANCED / "conversationShowChoicesLocal.sqf",
            ADVANCED / "conversationHideChoicesLocal.sqf",
            ADVANCED / "conversationPlaySoundLocal.sqf",
        )
        for path in server_only_local_presenters:
            with self.subTest(path=path.name):
                self.assertIn(
                    "remoteExecutedOwner != 2", path.read_text(encoding="utf-8")
                )

    def test_feature_notifications_reject_malformed_payloads_before_params(self):
        notify = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "featureNotifyLocal.sqf").read_text(encoding="utf-8")
        self.assertLess(notify.index("private _payloadValid"), notify.index("params ["))
        self.assertIn("Waldo_FeatureNotify_InvalidPayloadCount", notify)
        self.assertIn("FeatureNotifyLocal rejected malformed payload", notify)
        diagnostics = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnosticsClient.sqf").read_text(encoding="utf-8")
        self.assertIn("feature-notification-payloads", diagnostics)

    def test_advanced_bounds_and_client_payloads(self):
        validate = (ADVANCED / "conversationValidateDefinition.sqf").read_text(encoding="utf-8")
        worker = (ADVANCED / "conversationRunServer.sqf").read_text(encoding="utf-8")
        choose = (ADVANCED / "conversationChooseServer.sqf").read_text(encoding="utf-8")
        for token in ("128", "16", "8", "500"):
            self.assertIn(token, validate)
        self.assertIn("_transition < 256", worker)
        self.assertIn("offeredChoiceIds", worker)
        self.assertIn("isClass (missionConfigFile >> \"CfgSounds\" >> _sound)", worker)
        self.assertIn("calculated text timing used", worker)
        self.assertIn("_choiceDescriptors pushBack", worker)
        self.assertIn("_branchesToChoices", worker)
        choices = (ADVANCED / "conversationShowChoicesLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("ctrlEnable _enabled", choices)
        self.assertIn('setVariable ["Waldo_Conversation_ChoiceId"', choices)
        self.assertIn('getVariable ["Waldo_Conversation_ChoiceId"', choices)
        self.assertIn("private _panelX", choices)
        self.assertIn("private _panelY", choices)
        self.assertNotRegex(choices, r"private\s+_x\s*=")
        self.assertNotRegex(choices, r"private\s+_y\s*=")
        self.assertNotIn("ctrlSetData", choices)
        self.assertNotIn("ctrlData", choices)
        self.assertIn("ctrlTextWidth _button", choices)
        self.assertIn("Waldo_Dialogue_ChoiceMaximumWidth", choices)
        self.assertIn("Waldo_Dialogue_ChoiceMaximumHeight", choices)
        self.assertIn("Waldo_Dialogue_ChoiceMinimumRowHeight", choices)
        self.assertIn("RscControlsGroup", choices)
        self.assertIn("ctrlTextHeight _x", choices)
        self.assertNotIn("safeZoneW * 0.48", choices)
        self.assertIn('createDisplay "RscDisplayEmpty"', choices)
        self.assertIn("Waldo_Conversation_ChoicePendingSession", choices)
        self.assertIn("CBA_fnc_waitAndExecute", choices)
        self.assertIn("DISPLAY_UNAVAILABLE", choices)
        self.assertIn("successHex", choices)
        self.assertIn("continues to another response selection", choices)
        self.assertIn("Cancel conversation</t>", choices)
        self.assertNotIn('displayAddEventHandler ["KeyDown"', choices)
        self.assertNotIn('format ["%1. %2"', choices)
        for token in (
            "DISPLAY_LOST", "SPEAKER_DELETED", "CALLER_REPLACED",
            "SPEAKER_UNAVAILABLE", "CALLER_UNAVAILABLE", "SESSION_LOST",
            "OUT_OF_RANGE", "fail-open cleanup",
        ):
            self.assertIn(token, choices)
        self.assertIn('count _entry == 0', worker)
        self.assertIn('lifeState _rootSpeaker', worker)
        self.assertIn('remoteExecCall ["Waldo_fnc_DialogueAnimateLocal", 0]', worker)
        self.assertIn("owner _caller != remoteExecutedOwner", choose)
        self.assertNotRegex(worker, r"remoteExec(?:Call)?\s*\[\s*\"(?:call|spawn)\"")

    def test_completion_and_cancellation_hooks_are_separate(self):
        simple_worker = (SIMPLE / "dialogueRunSimpleServer.sqf").read_text(encoding="utf-8")
        advanced_worker = (ADVANCED / "conversationRunServer.sqf").read_text(encoding="utf-8")
        self.assertEqual(simple_worker.count("] call _callback;"), 1)
        self.assertIn('if (_completed) then {_definition getOrDefault ["onComplete", {}]} else {_definition getOrDefault ["onCancel", {}]}', advanced_worker)
        self.assertEqual(advanced_worker.count("] call _hook"), 1)

    def test_presets_are_opt_in_and_modern_pack_is_complete(self):
        modern = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "Dialogue" / "Presets" / "modernCivilians.sqf").read_text(encoding="utf-8")
        medieval = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "Dialogue" / "Presets" / "medievalDornow.sqf").read_text(encoding="utf-8")
        for archetype in (
            "MODERN_CIVILIAN", "MODERN_CIVILIAN_FRIENDLY", "MODERN_CIVILIAN_WARY",
            "MODERN_CIVILIAN_DISPLACED", "MODERN_SHOPKEEPER", "MODERN_RURAL_RESIDENT",
            "MODERN_AID_WORKER", "MODERN_LOCAL_OFFICIAL",
        ):
            self.assertIn(f'["{archetype}"', modern)
        for archetype in ("DORNOW_CIVILIAN", "DORNOW_GUARD", "DORNOW_SHOPKEEPER", "DORNOW_FARMER"):
            self.assertIn(f'["{archetype}"', medieval)

    def test_zen_manifest_contains_authoring_and_assignment_controls(self):
        records = json.loads((ROOT / "releaseVerificationAndDeployment" / "zeus_script_parity.json").read_text(encoding="utf-8"))
        names = {record["module"] for record in records}
        expected = {
            "Dialogue - Apply Simple Archetype", "Dialogue - Assign Simple Lines",
            "Dialogue - Clear", "Conversation: Assign",
        }
        self.assertTrue(expected <= names)
        self.assertNotIn("Conversation: Author", names)
        self.assertNotIn("Conversation - Start or Cancel", names)

    def test_broken_zen_conversation_author_is_fully_removed(self):
        server = (ROOT / "MissionScripts" / "ZenModules" / "Dialogue" / "zenDialogueServer.sqf").read_text(encoding="utf-8")
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        modules = (ROOT / "MissionScripts" / "ZenModules" / "Zen_initModules.sqf").read_text(encoding="utf-8")
        self.assertNotIn('ZenConversationAuthor', functions)
        self.assertNotIn('"Conversation: Author"', modules)
        self.assertNotIn('"Conversation - Start or Cancel"', modules)
        self.assertIn('["WMP Persistence", "Persistence - Control"', modules)
        self.assertIn('["WMP Persistence", "Persistence - Register Object"', modules)
        self.assertIn('["WMP Persistence", "Persistence - Save Now"', modules)
        self.assertNotIn('ADVANCED_AUTHOR', server)
        for path in (ROOT / "MissionScripts" / "ZenModules" / "Dialogue").glob("zenConversationAuthor*.sqf"):
            self.fail(f"Removed author helper still exists: {path.name}")

    def test_documentation_starts_with_eden_examples(self):
        guide = (ROOT / "wiki" / "Dialogue-And-Conversations.md").read_text(encoding="utf-8")
        self.assertLess(guide.index('[this, "CIVILIAN"]'), guide.index("## Advanced Conversations"))
        self.assertIn("Do not add anything to `init.sqf` or", guide)
        self.assertIn('[this, "MODERN_CIVILIAN"]', guide)
        self.assertIn("loads that example pack on demand", guide)
        self.assertNotIn("Conversation: Author", guide)
        self.assertIn("authored in mission scripts", guide)


if __name__ == "__main__":
    unittest.main()
