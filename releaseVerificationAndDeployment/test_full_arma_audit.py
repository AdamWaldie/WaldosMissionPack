import importlib.util
import json
import re
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PARSER_PATH = ROOT / "releaseVerificationAndDeployment" / "parse_full_arma_audit.py"
SPEC = importlib.util.spec_from_file_location("full_audit_parser", PARSER_PATH)
PARSER = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(PARSER)

RELEASE_FILTER_PATH = ROOT / "releaseVerificationAndDeployment" / "release_file_list.py"
RELEASE_FILTER_SPEC = importlib.util.spec_from_file_location("release_file_list", RELEASE_FILTER_PATH)
RELEASE_FILTER = importlib.util.module_from_spec(RELEASE_FILTER_SPEC)
assert RELEASE_FILTER_SPEC and RELEASE_FILTER_SPEC.loader
RELEASE_FILTER_SPEC.loader.exec_module(RELEASE_FILTER)

AUDIT_BUILDER_PATH = ROOT / "releaseVerificationAndDeployment" / "build_full_arma_audit.py"
AUDIT_BUILDER_SPEC = importlib.util.spec_from_file_location("build_full_arma_audit", AUDIT_BUILDER_PATH)
AUDIT_BUILDER = importlib.util.module_from_spec(AUDIT_BUILDER_SPEC)
assert AUDIT_BUILDER_SPEC and AUDIT_BUILDER_SPEC.loader
AUDIT_BUILDER_SPEC.loader.exec_module(AUDIT_BUILDER)

SQF_VALIDATOR_PATH = ROOT / "releaseVerificationAndDeployment" / "sqf_validator.py"
SQF_VALIDATOR_SPEC = importlib.util.spec_from_file_location("sqf_validator", SQF_VALIDATOR_PATH)
SQF_VALIDATOR = importlib.util.module_from_spec(SQF_VALIDATOR_SPEC)
assert SQF_VALIDATOR_SPEC and SQF_VALIDATOR_SPEC.loader
SQF_VALIDATOR_SPEC.loader.exec_module(SQF_VALIDATOR)


class FullAuditTests(unittest.TestCase):
    @staticmethod
    def sqf_without_comments(path: Path) -> str:
        text = path.read_text(encoding="utf-8")
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
        return re.sub(r"//[^\r\n]*", "", text)

    def test_repository_and_release_use_mit_license(self):
        license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
        release_config = json.loads((ROOT / "releaseVerificationAndDeployment" / "config.json").read_text(encoding="utf-8"))
        self.assertTrue(license_text.startswith("MIT License"))
        self.assertIn("LICENSE", release_config["build"]["include"])

    def test_sqf_validator_rejects_known_engine_invalid_commands(self):
        with tempfile.TemporaryDirectory() as directory:
            bad = Path(directory) / "bad.sqf"
            bad.write_text("_control ctrlSetStyle 1;\n", encoding="utf-8")
            self.assertGreater(SQF_VALIDATOR.check_sqf_syntax(str(bad)), 0)
            comment_only = Path(directory) / "comment.sqf"
            comment_only.write_text("// ctrlSetStyle is invalid\n", encoding="utf-8")
            self.assertEqual(SQF_VALIDATOR.check_sqf_syntax(str(comment_only)), 0)

    def test_standard_release_is_explicit_and_excludes_qa_tooling(self):
        config_path = ROOT / "releaseVerificationAndDeployment" / "config.json"
        config = json.loads(config_path.read_text(encoding="utf-8"))
        included = set(config["build"]["include"])
        self.assertIn("MissionScripts", included)
        self.assertIn("description.ext", included)
        self.assertNotIn("releaseVerificationAndDeployment", included)
        self.assertNotIn(".qa", included)
        self.assertNotIn("wiki", included)
        self.assertNotIn("WMP_Compositions", included)
        self.assertNotIn("UnitInsignias", included)

    def test_wiki_sync_publishes_assets_not_only_markdown(self):
        workflow = (ROOT / ".github" / "workflows" / "wiki-sync.yml").read_text(encoding="utf-8")
        self.assertIn("rsync -a --delete", workflow)
        self.assertIn("check_wiki_assets.py", workflow)
        self.assertIn("wiki_style_checker.py", workflow)
        self.assertNotIn("cp wiki/*.md", workflow)

    def test_wiki_structure_is_validated_in_ci(self):
        workflow = (ROOT / ".github" / "workflows" / "testing.yml").read_text(encoding="utf-8")
        self.assertIn("wiki_style_checker.py", workflow)
        checker = ROOT / "releaseVerificationAndDeployment" / "wiki_style_checker.py"
        self.assertTrue(checker.is_file())

    def test_patch_filter_uses_standard_release_allowlist(self):
        allowed = {"MissionScripts", "Pictures", "description.ext"}
        self.assertTrue(RELEASE_FILTER.releasable("MissionScripts/Test.sqf", allowed))
        self.assertTrue(RELEASE_FILTER.releasable("description.ext", allowed))
        self.assertFalse(RELEASE_FILTER.releasable("releaseVerificationAndDeployment/audit.rpt", allowed))
        self.assertFalse(RELEASE_FILTER.releasable("wiki/Home.md", allowed))
        self.assertFalse(RELEASE_FILTER.releasable("WMP_Compositions/Table/header.sqe", allowed))

    def test_checked_in_mission_is_self_contained_and_populated(self):
        mission = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"
        sqm = (mission / "mission.sqm").read_text(encoding="utf-8")
        self.assertGreaterEqual(sqm.count('side="Empty"'), 90)
        self.assertTrue(sqm.startswith("version=54;"))
        self.assertIn("binarizationWanted=0;", sqm)
        self.assertIn("class Entities", sqm)
        self.assertEqual(5, sqm.count("class Inventory"))
        self.assertEqual(1, sqm.count("isPlayer=1;"))
        self.assertEqual(4, sqm.count("isPlayable=1;"))
        self.assertIn("position[]={-105,5.32,48}", sqm)
        self.assertIn("position[]={0,6.14,2}", sqm)
        for fixture in (
            "qa_control_console",
            "qa_party_table_1",
            "qa_interaction_wirecut_easy",
            "qa_interaction_commandinput_expert",
            "qa_economy_research",
            "qa_mhq",
            "qa_mhq_antenna",
            "qa_ew_jammer",
            "qa_hazard_emitter",
            "qa_breach_wall",
            "qa_tactical_console",
            "qa_recovery_vehicle",
            "qa_loadout_arsenal",
        ):
            self.assertIn(fixture, sqm)
        self.assertNotIn("qa_station_", sqm)
        self.assertIn('type="ModuleCurator_F"', sqm)
        self.assertIn('name="qa_curator"', sqm)
        for station_id in (
            "persistence", "treatment-feedback", "hazards", "tree-felling",
            "emergency-dismount", "accessibility", "breaching", "object-transforms",
            "ai-rebalance", "field-resupply", "tactical-display", "dynamic-aa",
            "gunship", "vehicle-recovery", "rally", "nested-loadouts",
        ):
            self.assertIn(f'qa_sign_{station_id.replace("-", "_")}', sqm)
        self.assertTrue((mission / "MissionScripts" / "WaldosFunctions.sqf").is_file())
        self.assertTrue((mission / "Pictures" / "loading.jpg").is_file())
        self.assertTrue((mission / "economyConfig.sqf").is_file())
        self.assertTrue((mission / "auditBootstrap.sqf").is_file())
        self.assertTrue(sqm.lstrip().startswith("version="))
        self.assertFalse(any(mission.glob("*.pbo")))
        self.assertNotIn("Land_Radio_F", sqm)
        self.assertIn('type="Land_PortableServer_01_sand_F"', sqm)
        self.assertEqual(sqm.count('side="Empty"'), sqm.count("this enableSimulationGlobal false;"))
        for release_root in ("description.ext", "init.sqf", "initPlayerLocal.sqf", "initServer.sqf", "economyConfig.sqf", "LICENSE", "README.md"):
            self.assertTrue((mission / "WMPPackSource" / release_root).is_file())
        init_player = (mission / "initPlayerLocal.sqf").read_text(encoding="utf-8")
        client_audit = (mission / "runClientAudit.sqf").read_text(encoding="utf-8")
        self.assertIn('auditPreInitPlayerLocal.sqf', init_player)
        self.assertIn('auditInitPlayerLocal.sqf', init_player)
        self.assertIn("core/markers/client-renderer", client_audit)

    def test_checked_in_mission_scripts_match_release_sources(self):
        source = ROOT / "MissionScripts"
        packaged = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "MissionScripts"
        source_files = {path.relative_to(source) for path in source.rglob("*") if path.is_file()}
        packaged_files = {path.relative_to(packaged) for path in packaged.rglob("*") if path.is_file()}
        self.assertEqual(source_files, packaged_files)
        changed = [relative for relative in source_files if (source / relative).read_bytes() != (packaged / relative).read_bytes()]
        self.assertEqual([], changed)

    def test_loadout_scraper_recurses_into_nested_eden_folders(self):
        source = (
            ROOT
            / "MissionScripts"
            / "Logistics"
            / "LogiHelpers"
            / "missionFileLookup.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn('getText (_entity >> "dataType") == "Object"', source)
        self.assertIn("_isPlayer == 1 || _isPlayable == 1", source)
        self.assertIn('private _children = _entity >> "Entities"', source)
        self.assertIn("[_x] call _visitEntity", source)
        self.assertIn('missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities"', source)

    def test_generated_mission_runs_current_pack_before_audit_hooks(self):
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / "WMP_FPA.VR"
            AUDIT_BUILDER.build(destination, "all", "acre")
            generated_init = (destination / "init.sqf").read_text(encoding="utf-8")
            generated_server = (destination / "initServer.sqf").read_text(encoding="utf-8")
            generated_player = (destination / "initPlayerLocal.sqf").read_text(encoding="utf-8")
            self.assertIn('["",""] call Waldo_fnc_InfoText', generated_init)
            self.assertIn("sleep 10", generated_init)
            self.assertTrue(generated_init.rstrip().endswith('call compile preprocessFileLineNumbers "auditInit.sqf";'))
            self.assertTrue(generated_server.rstrip().endswith('call compile preprocessFileLineNumbers "auditInitServer.sqf";'))
            self.assertTrue(generated_player.rstrip().endswith('call compile preprocessFileLineNumbers "auditInitPlayerLocal.sqf";'))
            source_description = AUDIT_BUILDER.audit_description(
                (ROOT / "description.ext").read_text(encoding="utf-8")
            )
            self.assertEqual(
                source_description,
                (destination / "description.ext").read_text(encoding="utf-8"),
            )
            self.assertIn('#include "mission.sqm"', source_description)
            self.assertFalse((destination / "auditLoadoutSQM.hpp").exists())
            self.assertIn("Waldo_QA_RunAutomation = false;", (destination / "auditBootstrap.sqf").read_text(encoding="utf-8"))
            self.assertIn("maxPlayers = 5", (destination / "description.ext").read_text(encoding="utf-8"))

    def test_manual_audit_does_not_start_live_convoy_during_load(self):
        server = (
            ROOT
            / "releaseVerificationAndDeployment"
            / "fullArmaAudit"
            / "WMP_FPA.VR"
            / "featureRangeServer.sqf"
        ).read_text(encoding="utf-8")
        client = (
            ROOT
            / "releaseVerificationAndDeployment"
            / "fullArmaAudit"
            / "WMP_FPA.VR"
            / "featureRangeClient.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn("Waldo_QA_fnc_startConvoyServer =", server)
        self.assertEqual(1, server.count("spawn Waldo_fnc_SimpleAiConvoy"))
        self.assertIn('["qa_convoy_1", [28, 54, 0]], ["qa_convoy_2", [28, 70, 0]]', server)
        self.assertIn('[_variableName, "B_MRAP_01_F", _position, 0, false]', server)
        self.assertIn("START / RESET CONVOY TEST", client)
        self.assertIn('["qa_drop_aircraft", "B_Heli_Transport_01_F", [-30, 55, 55], 180, false]', server)
        self.assertIn("ACTIVATE PARADROP AIRCRAFT", client)

    def test_pack_init_cannot_deadlock_on_dedicated_server(self):
        init = (ROOT / "init.sqf").read_text(encoding="utf-8")
        acre_init = (
            ROOT / "MissionScripts" / "MissionInit" / "ACRE2" / "ACRE2Init.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn("isDedicated ||", init)
        self.assertNotIn("waitUntil {!isNull player && player == player};", init)
        self.assertIn("[_RadioSetups] spawn Waldo_fnc_ACRE2Init;", init)
        self.assertIn("if (isServer) then {", acre_init)
        self.assertIn("[_SquadCallsigns] call Waldo_fnc_SquadLevelRadios;", acre_init)
        self.assertIn("if (!hasInterface) exitWith", acre_init)
        self.assertIn("private _readyDeadline = diag_tickTime + 30;", acre_init)
        self.assertIn('if (hasInterface) then {["",""] call Waldo_fnc_InfoText};', init)
        self.assertIn("if (hasInterface) then {call Waldo_fnc_AddDocs};", init)
        self.assertIn("if (hasInterface) then {call Waldo_fnc_SetTeamColour};", init)

    def test_entry_points_preserve_server_authority_and_jip_state(self):
        init = (ROOT / "init.sqf").read_text(encoding="utf-8")
        init_server = (ROOT / "initServer.sqf").read_text(encoding="utf-8")
        init_player = (ROOT / "initPlayerLocal.sqf").read_text(encoding="utf-8")

        self.assertNotIn('missionNamespace setVariable ["Waldo_Jamming_Notify", true, true]', init)
        self.assertNotIn('missionNamespace setVariable ["Waldo_Jamming_Enable", true, true]', init)
        self.assertIn('if (isNil "Waldo_MiniGames_Enable") then', init)
        self.assertIn('if (isNil "Waldo_CorpseTraps_Enable") then', init)
        self.assertIn('missionNamespace setVariable ["WALDO_INIT_COMPLETE", true];', init)
        self.assertNotIn('missionNamespace setVariable ["WALDO_INIT_COMPLETE", true, true]', init)

        self.assertIn('["Waldo_Jamming_Enable", true]', init_server)
        self.assertIn('missionNamespace setVariable ["Waldo_Jamming_ConfigReady", true, true]', init_server)
        self.assertIn('[] call Waldo_fnc_JammingInit;', init_server)

        self.assertIn('missionNamespace getVariable ["Waldo_Jamming_ConfigReady", false]', init_player)
        self.assertIn('missionNamespace getVariable ["Waldo_Jamming_Enable", false]', init_player)
        self.assertIn('[] call Waldo_fnc_JammingInit;', init_player)

    def test_generated_mission_maps_every_registered_function_to_one_station(self):
        manifest_path = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "function_station_manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        registrations = AUDIT_BUILDER.FUNCTION.findall(
            (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        )
        self.assertEqual(len(registrations), manifest["registeredFunctionCount"])
        names = [entry["name"] for entry in manifest["functions"]]
        self.assertEqual(len(names), len(set(names)))
        station_ids = {entry["id"] for entry in manifest["stations"]}
        self.assertEqual(set(), {entry["station"] for entry in manifest["functions"]} - station_ids)
        for entry in manifest["functions"]:
            self.assertTrue((ROOT / entry["file"]).is_file(), entry["name"])
        runtime_names = [entry["name"] for entry in manifest["runtimeFunctions"]]
        self.assertEqual(manifest["runtimeFunctionCount"], len(runtime_names))
        self.assertEqual(len(runtime_names), len(set(runtime_names)))
        self.assertEqual(
            manifest["functionCount"],
            manifest["registeredFunctionCount"] + manifest["runtimeFunctionCount"],
        )
        self.assertEqual(set(), {entry["station"] for entry in manifest["runtimeFunctions"]} - station_ids)

    def test_registered_function_paths_use_exact_on_disk_case(self):
        registrations = AUDIT_BUILDER.FUNCTION.findall(
            (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        )
        for name, relative in registrations:
            self.assertTrue(
                AUDIT_BUILDER.GENERATOR.has_exact_path_case(ROOT, relative),
                f"Waldo_fnc_{name}: {relative}",
            )

    def test_manual_audit_never_starts_destructive_cases(self):
        mission = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"
        for script_name in ("auditInitServer.sqf", "auditInitPlayerLocal.sqf"):
            script = (mission / script_name).read_text(encoding="utf-8")
            self.assertIn("Waldo_QA_RunAutomation", script)
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / "WMP_FPA.VR"
            AUDIT_BUILDER.build(destination, "all", "acre", "automated")
            self.assertIn("Waldo_QA_RunAutomation = true;", (destination / "auditBootstrap.sqf").read_text(encoding="utf-8"))

    def test_audit_preconfig_precedes_real_pack_and_transient_ui_is_cleaned(self):
        mission = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"
        generated_server = (mission / "initServer.sqf").read_text(encoding="utf-8")
        self.assertLess(generated_server.index('auditPreInitServer.sqf'), generated_server.index('WALDO_STATIC_STATICCHUTE'))
        pre_server = (mission / "auditPreInitServer.sqf").read_text(encoding="utf-8")
        self.assertIn('"B_Parachute"', pre_server)
        self.assertIn('"Waldo_SafeStart_AutoStart", false', pre_server)
        self.assertIn('["Waldo_Economy_Preset", "MEDIUM", true]', pre_server)
        for side_catalog in ('["WEST", "NATO"]', '["EAST", "CSAT"]', '["GUER", "AAF"]'):
            self.assertIn(side_catalog, pre_server)
        shared_init = (ROOT / "init.sqf").read_text(encoding="utf-8")
        server_init = (ROOT / "initServer.sqf").read_text(encoding="utf-8")
        player_init = (ROOT / "initPlayerLocal.sqf").read_text(encoding="utf-8")
        self.assertNotIn("spawn Waldo_fnc_EcoInit", shared_init)
        self.assertIn("[] call Waldo_fnc_EcoInit", server_init)
        self.assertIn("[] call Waldo_fnc_EcoInit", player_init)
        self.assertLess(server_init.index("[] call Waldo_fnc_EcoInit"), server_init.index('Waldo_FeatureRuntimeStateReady", true'))
        cleanup = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "cleanupTransientUi.sqf").read_text(encoding="utf-8")
        for idc in (5299, 5300, 5309, 5310, 5330, 5331, 5340, 5341):
            self.assertIn(str(idc), cleanup)
        self.assertIn('["Ended"', player_init)
        self.assertIn('["EntityKilled"', player_init)

    def test_economy_prompts_preserve_zeus_and_capture_gameplay_input(self):
        core = ROOT / "MissionScripts" / "EconomySystems" / "Core"
        creator = (core / "createZeusPromptDisplay.sqf").read_text(encoding="utf-8")
        fitter = (core / "fitPromptDisplay.sqf").read_text(encoding="utf-8")
        closer = (core / "closePromptDisplayIfDedicated.sqf").read_text(encoding="utf-8")
        self.assertIn('private _disp = _parent createDisplay "RscDisplayEmpty"', creator)
        self.assertIn('WaldoEcoCore_PromptParentDisplay', creator)
        self.assertIn('WaldoEcoCore_PromptOpenedFromZeus', creator)
        self.assertNotIn('else {_parent}', creator)
        self.assertIn("WaldoEcoCore_PromptBaselineControls", creator)
        self.assertIn("!(_x in _baseline)", fitter)
        self.assertIn("min 1.35", fitter)
        self.assertNotIn("private _scaleX", fitter)
        self.assertNotIn("private _scaleY", fitter)
        self.assertIn("BUTTON HEIGHT EXCESSIVE", fitter)
        self.assertIn("NAVIGATION BUTTON WIDTH EXCESSIVE", fitter)
        self.assertIn("WaldoEcoCore_PromptMaxCardBounds", creator)
        self.assertIn("WaldoEcoCore_PromptCardControl", creator)
        self.assertIn("_layoutW + (2 * _padX)", fitter)
        self.assertIn("_cardControl ctrlSetPosition", fitter)
        self.assertIn("WaldoEcoCore_PromptOwnedControls", closer)
        economy_root = ROOT / "MissionScripts" / "EconomySystems"
        editable_prompts = []
        for path in economy_root.rglob("*.sqf"):
            source = path.read_text(encoding="utf-8")
            if 'ctrlCreate ["RscEdit"' in source or 'ctrlCreate ["RscEditMulti"' in source:
                if "ctrlEnable false" not in source:
                    editable_prompts.append((path, source))
        self.assertGreater(len(editable_prompts), 0)
        for path, source in editable_prompts:
            self.assertIn("setPromptInputTargets", source, path)
        notice_hook = (core / "getTestingNoticeActionArgs.sqf").read_text(encoding="utf-8")
        self.assertNotIn("createDisplay", notice_hook)
        self.assertIn("Waldo_fnc_EcoCore_notifyActorLocal", notice_hook)

    def test_drawn_feature_huds_do_not_duplicate_feedback_through_hints(self):
        sources = [
            ROOT / "MissionScripts" / "MissionFlowAndUi" / "safeStartHud.sqf",
            ROOT / "MissionScripts" / "MissionFlowAndUi" / "safeStartNotice.sqf",
            ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingHud.sqf",
            ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingNotice.sqf",
            ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingUavClient.sqf",
            ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammerScan.sqf",
            ROOT / "MissionScripts" / "EconomySystems" / "Core" / "notifyActorLocal.sqf",
        ]
        for source in sources:
            executable = self.sqf_without_comments(source)
            self.assertIsNone(re.search(r"(?i)\b(?:hint|hintSilent|Waldo_fnc_TimedHint)\b", executable), source)

        economy = ROOT / "MissionScripts" / "EconomySystems"
        for source in economy.rglob("*.sqf"):
            executable = self.sqf_without_comments(source)
            self.assertIsNone(re.search(r"(?i)\b(?:hint|hintSilent)\b", executable), source)

    def test_party_interfaces_keep_feedback_inside_drawn_ui(self):
        engine = ROOT / "MissionScripts" / "MiniGames" / "engine"
        for source in engine.rglob("*.sqf"):
            executable = self.sqf_without_comments(source)
            self.assertIsNone(re.search(r"(?i)\b(?:hint|hintSilent)\b", executable), source)
        core = (engine / "core.sqf").read_text(encoding="utf-8")
        self.assertIn("Waldo_MG_fnc_notifyLocal", core)
        self.assertIn("Waldo_MG_TableGameDisplay", core)

    def test_runtime_sensitive_assertions_reproduce_real_interaction_context(self):
        client_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runClientAudit.sqf").read_text(encoding="utf-8")
        self.assertIn("player setPosATL ((getPosATL _x) vectorAdd", client_audit)
        self.assertIn("player setPosATL ((getPosATL _table) vectorAdd", client_audit)

    def test_visual_services_wait_for_pack_startup_and_use_owned_regions(self):
        jamming = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingInit.sqf").read_text(encoding="utf-8")
        safestart = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "safeStartHud.sqf").read_text(encoding="utf-8")
        ew = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingHud.sqf").read_text(encoding="utf-8")
        self.assertIn('missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]', jamming)
        self.assertIn("safeZoneX + ((safeZoneW - _panelW) / 2)", safestart)
        self.assertIn("_visibleBottom - _reservedRadioH", ew)

    def test_manifest_covers_every_pr(self):
        manifest_path = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "audit_manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        covered = {pr for suite in manifest["suites"] for pr in suite["prs"]}
        self.assertEqual(covered, set(range(21, 33)))

    def test_manifest_case_ids_are_unique(self):
        manifest_path = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "audit_manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        cases = [case for suite in manifest["suites"] for case in suite["cases"]]
        self.assertEqual(len(cases), len(set(cases)))

    def test_audit_defaults_to_required_mod_profile(self):
        hosted = (ROOT / "releaseVerificationAndDeployment" / "launch_full_arma_hosted_audit.ps1").read_text(encoding="utf-8")
        dedicated = (ROOT / "releaseVerificationAndDeployment" / "launch_full_arma_dedicated_audit.ps1").read_text(encoding="utf-8")
        bootstrap = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "auditBootstrap.sqf").read_text(encoding="utf-8")
        self.assertIn('[string]$ModProfile = "acre"', hosted)
        self.assertIn('[string]$ModProfile = "acre"', dedicated)
        for patch in ("cba_main", "ace_main", "zen_main", "acre_main"):
            self.assertIn(patch, bootstrap)
        self.assertIn('"launch_pr_review_audit.ps1"', hosted)
        self.assertIn("canonical version-12 full-pack audit mission", hosted)
        self.assertNotIn('"-host"', hosted)
        self.assertIn("Close all Arma audit clients and servers before staging", dedicated)
        self.assertNotIn("-filePatching", hosted)
        self.assertNotIn("-filePatching", dedicated)

    def test_built_audit_has_distinct_mission_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / "WMP_FPA.VR"
            AUDIT_BUILDER.build(destination, "all", "acre")
            description = (destination / "description.ext").read_text(encoding="utf-8")
            self.assertIn('onLoadName = "WMP FULL PACK AUDIT"', description)
            self.assertIn('onLoadMission = "Ongoing full-pack pull request audit"', description)

    def test_audit_exposes_curator_and_full_mhq_fixture(self):
        feature_range = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeServer.sqf").read_text(encoding="utf-8")
        self.assertIn("qa_curator", feature_range)
        self.assertIn("assignCurator", feature_range)
        self.assertIn("getAssignedCuratorUnit", (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runServerAudit.sqf").read_text(encoding="utf-8"))
        self.assertIn("qa_mhq_antenna", feature_range)
        self.assertIn("qa_mhq_light", feature_range)
        self.assertIn("[_mhq, true, true, 180, 5] call Waldo_fnc_MHQSetup", feature_range)
        self.assertIn("Waldo_QA_fnc_resetEconomyFixturesServer", feature_range)
        self.assertIn("Waldo_QA_fnc_spawnConstructionVehicleServer", feature_range)

    def test_generated_mission_declares_resolvable_character_dependencies(self):
        generator = (ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py").read_text(encoding="utf-8")
        self.assertIn('addOns[]={{"A3_Characters_F_BLUFOR","A3_Characters_F_OPFOR"', generator)
        self.assertIn('addOnsAuto[]={{"A3_Characters_F_BLUFOR","A3_Map_VR"', generator)
        self.assertNotIn('addOns[]={{"A3_Characters_F",', generator)
        self.assertNotIn('addOnsAuto[]={{"A3_Characters_F",', generator)
        dedicated = (ROOT / "releaseVerificationAndDeployment" / "launch_full_arma_dedicated_audit.ps1").read_text(encoding="utf-8")
        self.assertIn("You cannot play/edit this mission", dedicated)
        preflight = (ROOT / "releaseVerificationAndDeployment" / "test_full_arma_mission_load.ps1").read_text(encoding="utf-8")
        self.assertIn('template = "WMP_Full_Arma_Audit.VR"', preflight)
        self.assertIn('"-noBattlEye"', preflight)
        self.assertIn("Mission world: VR", preflight)
        self.assertIn("You cannot play/edit this mission", preflight)
        self.assertNotIn('a3_characters_f\\s*$', preflight)

    def test_runtime_actions_and_feedback_are_unambiguous(self):
        interaction = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteraction.sqf").read_text(encoding="utf-8")
        setup = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteractionSetup.sqf").read_text(encoding="utf-8")
        resolver = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteractionResolveServer.sqf").read_text(encoding="utf-8")
        bomb = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "bombDefuseSetup.sqf").read_text(encoding="utf-8")
        resource = (ROOT / "MissionScripts" / "EconomySystems" / "Resource" / "ensureCrateActionLocal.sqf").read_text(encoding="utf-8")
        build = (ROOT / "MissionScripts" / "EconomySystems" / "Build" / "getOfficialConstructionModeActionArgs.sqf").read_text(encoding="utf-8")
        self.assertIn("ace_interact_menu_fnc_createAction", interaction)
        self.assertIn("addAction", interaction)
        self.assertIn("same server acquisition handshake", interaction)
        self.assertIn("Waldo_MG_FieldEquipment", interaction)
        self.assertIn('"ACE+VANILLA"', interaction)
        self.assertIn("isServer && {isNil", interaction)
        self.assertIn("private _publishPreset = isServer", setup)
        self.assertIn("MiniGameInteractionNotifyClient", resolver)
        self.assertIn('isNil "CBA_fnc_globalEvent"', resolver)
        self.assertIn("_boom setDamage 1", bomb)
        self.assertIn("Waldo_fnc_MiniGameInteractionSetup", bomb)
        self.assertIn('["difficulty", ["difficulty", "standard"] call _opt]', bomb)
        self.assertIn('private _successVariable = ["successVariable", _legacyDefusedVariable] call _opt', bomb)
        self.assertIn('private _challengeId = toLower (["challengeId"', bomb)
        self.assertIn('[_object, _challengeId, _setup] call Waldo_fnc_MiniGameInteractionSetup', bomb)
        self.assertNotIn('[_object, "wirecut", _setup] call Waldo_fnc_MiniGameInteractionSetup', bomb)
        self.assertIn('["oneShot", _oneShot]', setup)
        self.assertIn("Waldo_fnc_EcoCore_canRunAuthority", resource)
        self.assertIn("WaldoEcoResource_CollectRequest", resource)
        self.assertIn("Deploy + Consume", build)
        self.assertIn("WaldoEcoBuild_ConsumesConstructionSource", build)
        self.assertIn("ctrlShow _consumesSource", build)
        self.assertIn("ONE USE: SOURCE IS CONSUMED", build)

    def test_shared_drawn_ui_uses_safe_zone_fitters(self):
        party = (ROOT / "MissionScripts" / "MiniGames" / "engine" / "core.sqf").read_text(encoding="utf-8")
        economy = (ROOT / "MissionScripts" / "EconomySystems" / "Core" / "fitPromptDisplay.sqf").read_text(encoding="utf-8")
        interaction = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Core" / "challengeUi.sqf").read_text(encoding="utf-8")
        picker = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "equipmentPicker.sqf").read_text(encoding="utf-8")
        self.assertIn("Waldo_MG_fnc_fitTableDisplaySafeLocal", party)
        self.assertIn("_visibleW * 0.95", party)
        self.assertIn("safeZoneX - safeZoneW", party)
        self.assertIn("WaldoEcoCore_PromptContentBounds", economy)
        self.assertIn("WaldoEcoCore_PromptCardBounds", economy)
        self.assertIn("PROMPT CONTENT VIOLATES CARD PADDING", economy)
        self.assertIn("private _visibleX = safeZoneX", party)
        self.assertIn("private _visibleRight = safeZoneX + safeZoneW", party)
        self.assertIn("private _viewportX = safeZoneX", interaction)
        self.assertIn("private _viewportRight = safeZoneX + safeZoneW", interaction)
        self.assertIn("_viewportW * 0.92", interaction)
        self.assertIn("_viewportH * 0.90", interaction)
        self.assertNotIn("_gridAspect", interaction)
        self.assertIn("Waldo_MG_SafeFitFindings", party)
        self.assertIn("WaldoEcoCore_FitFindings", economy)
        self.assertIn("private _visibleX = safezoneX", picker)
        self.assertIn("private _visibleBottom = safezoneY + safezoneH", picker)
        self.assertNotIn("(0.62 * safezoneW) min (0.92 * safezoneH)", picker)

    def test_every_dynamic_party_and_economy_display_uses_shared_safe_fit(self):
        party_games = ROOT / "MissionScripts" / "MiniGames" / "engine" / "games"
        for path in party_games.glob("*.sqf"):
            source = path.read_text(encoding="utf-8")
            if "createDisplay" in source:
                self.assertIn("Waldo_MG_fnc_installEscapeGuardLocal", source, path)
        economy_root = ROOT / "MissionScripts" / "EconomySystems"
        for path in economy_root.rglob("*.sqf"):
            source = path.read_text(encoding="utf-8")
            if "createDisplay" in source:
                self.assertIn("Waldo_fnc_EcoCore_fitPromptDisplay", source, path)

    def test_cross_pack_drawn_ui_checker_is_clean(self):
        checker_path = ROOT / "releaseVerificationAndDeployment" / "drawn_ui_checker.py"
        namespace = {"__file__": str(checker_path)}
        exec(compile(checker_path.read_text(encoding="utf-8"), str(checker_path), "exec"), namespace)
        findings, inventory = namespace["audit"](ROOT)
        self.assertGreaterEqual(len(inventory), 45)
        self.assertEqual([], findings)

    def test_zeus_and_script_api_parity_manifest_is_complete(self):
        checker_path = ROOT / "releaseVerificationAndDeployment" / "zeus_script_parity_checker.py"
        namespace = {"__file__": str(checker_path)}
        exec(compile(checker_path.read_text(encoding="utf-8"), str(checker_path), "exec"), namespace)
        findings = namespace["audit"](ROOT)
        self.assertEqual([], findings)

    def test_interaction_shared_overlays_and_dense_legends_fit_text(self):
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        self.assertIn("MiniGameEquipmentFitStructuredText", functions)
        for relative in (
            "Core/challengeHelp.sqf",
            "Integration/equipmentPicker.sqf",
            "Integration/miniGameInteractionNotifyClient.sqf",
            "Challenges/challengeMinesweeper.sqf",
            "Challenges/challengeKeypad.sqf",
            "Challenges/challengeRepair.sqf",
            "Challenges/challengeSequence.sqf",
        ):
            source = (ROOT / "MissionScripts" / "InteractionsMinigames" / relative).read_text(encoding="utf-8")
            self.assertIn("MiniGameEquipmentFitStructuredText", source, relative)

    def test_zeus_economy_export_can_emit_paste_ready_world_setup(self):
        exporter = (ROOT / "MissionScripts" / "EconomySystems" / "Core" / "buildMissionSetupScript.sqf").read_text(encoding="utf-8")
        prompt = (ROOT / "MissionScripts" / "EconomySystems" / "Core" / "promptUnifiedSaveSystem.sqf").read_text(encoding="utf-8")
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        builders = "\n".join(
            (ROOT / "MissionScripts" / "EconomySystems" / section / "buildSetupCalls.sqf").read_text(encoding="utf-8")
            for section in ("Resource", "Research", "Build", "Buy")
        )
        for function_name in (
            "EcoResource_addResourceType",
            "EcoResource_setSideResourceAmount",
            "EcoResource_setResourceMarkerVisibility",
            "EcoResearch_setResearchCatalog",
            "EcoBuild_setBuildCatalog",
            "EcoBuy_setPurchaseCatalog",
            "EcoResource_createResourceZone",
            "EcoResource_spawnResourceCrate",
            "EcoResearch_spawnResearchCenter",
            "EcoBuild_spawnConstructionVehicle",
            "EcoBuild_spawnConfiguredBuilding",
            "EcoBuy_createDropPoint",
            "EcoBuy_spawnPurchaseLaptop",
        ):
            self.assertIn(function_name, builders)
        for builder_name in (
            "EcoResource_buildSetupCalls",
            "EcoResearch_buildSetupCalls",
            "EcoBuild_buildSetupCalls",
            "EcoBuy_buildSetupCalls",
        ):
            self.assertIn(builder_name, exporter)
            self.assertIn(f"class {builder_name}", functions)
        self.assertIn("economyConfig.sqf", exporter)
        self.assertNotIn("EcoCore_importUnifiedSavePayload", exporter)
        self.assertNotIn("WaldoEcoCore_SAVE_V1", exporter)
        self.assertIn('ctrlSetText "BUILD + COPY"', prompt)
        self.assertIn("copyToClipboard", prompt)
        self.assertIn("Paste the generated calls into economyConfig.sqf", prompt)
        self.assertIn('ctrlSetText "CONFIG COPY"', prompt)
        self.assertNotIn("WaldoEcoCore_SaveMissionSetupCheck", prompt)
        self.assertIn("EcoCore_buildMissionSetupScript", prompt)
        self.assertIn("EcoCore_buildUnifiedSaveExportPayload", prompt)
        self.assertIn("class EcoCore_buildMissionSetupScript", functions)

    def test_diagnostics_distinguish_loaded_disabled_and_unavailable(self):
        diagnostics = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnostics.sqf").read_text(encoding="utf-8")
        client = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnosticsClient.sqf").read_text(encoding="utf-8")
        receiver = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "diagnosticsReceiveClient.sqf").read_text(encoding="utf-8")
        logger = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "diagnosticLog.sqf").read_text(encoding="utf-8")
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        documentation = (ROOT / "wiki" / "Mission-Diagnostics.md").read_text(encoding="utf-8")
        for state in ("LOADED", "ACTIVE", "DISABLED", "UNCONFIGURED", "UNAVAILABLE", "ERROR"):
            self.assertIn(f'"{state}"', diagnostics)
        self.assertIn("Waldo_Diagnostics_LastReport", diagnostics)
        for field in ("[run=%1]", "[node=%2]", "[area=%3]", "[feature=%4]", "[level=%5]", "[event=%6]"):
            self.assertIn(field, logger)
        self.assertIn('format ["CLIENT:%1", clientOwner]', client)
        self.assertIn('"CHECK"', client)
        self.assertIn("reason=stale", receiver)
        self.assertIn("reason=owner-mismatch", receiver)
        self.assertIn("reason=malformed", receiver)
        self.assertIn("Waldo_Diagnostics_Running", diagnostics)
        for function_name in ("DiagnosticLog", "RunDiagnosticsClient", "DiagnosticsReceiveClient"):
            self.assertIn(f"class {function_name}", functions)
        for area in ("LOGISTICS", "ELECTRONIC-WARFARE", "INTERACTIONS"):
            self.assertIn(area, documentation)

    def test_vvd_fixture_is_isolated(self):
        generator = (ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py").read_text(encoding="utf-8")
        server = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeServer.sqf").read_text(encoding="utf-8")
        self.assertIn('fixture("qa_vvd_pad", "Land_JumpTarget_F", -105, 48)', generator)
        self.assertIn("Waldo_QA_VVD_ClearanceObjects", server)
        self.assertIn("call Waldo_fnc_VVDInit", server)

    def test_mhq_and_vvd_integrations_are_repeat_safe_and_complete(self):
        mhq = (ROOT / "MissionScripts" / "Logistics" / "MHQ" / "MHQSetup.sqf").read_text(encoding="utf-8")
        mhq_local = (ROOT / "MissionScripts" / "Logistics" / "MHQ" / "MHQSetupLocal.sqf").read_text(encoding="utf-8")
        mhq_audio = (ROOT / "MissionScripts" / "Logistics" / "MHQ" / "MHQPlayAudioLocal.sqf").read_text(encoding="utf-8")
        mhq_server = (ROOT / "MissionScripts" / "Logistics" / "MHQ" / "MHQRequestServer.sqf").read_text(encoding="utf-8")
        vvd = (ROOT / "MissionScripts" / "Logistics" / "VirtualVehicleDepot" / "VVDInit.sqf").read_text(encoding="utf-8")
        vvd_open = (ROOT / "MissionScripts" / "Logistics" / "VirtualVehicleDepot" / "VVDOpen.sqf").read_text(encoding="utf-8")
        vvd_request = (ROOT / "MissionScripts" / "Logistics" / "VirtualVehicleDepot" / "VVDRequestOpenServer.sqf").read_text(encoding="utf-8")
        vvd_release = (ROOT / "MissionScripts" / "Logistics" / "VirtualVehicleDepot" / "VVDReleaseOpenServer.sqf").read_text(encoding="utf-8")
        audit_description = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "description.ext").read_text(encoding="utf-8")
        self.assertIn("Waldo_fnc_MHQSetupLocal", mhq)
        self.assertIn('remoteExecCall ["Waldo_fnc_MHQSetupLocal", 0, _target]', mhq)
        self.assertIn("Waldo_MHQ_LocalActionsInstalled", mhq_local)
        self.assertIn("Waldo_MHQ_ACEActionsInstalled", mhq_local)
        self.assertIn("Re-evaluate components", mhq_local)
        self.assertIn("Waldo_fnc_SetupQuarterMaster", mhq_local)
        self.assertIn("if (_aceLoaded) exitWith", mhq_local)
        self.assertIn("Waldo_MHQ_ServerConfigured", mhq)
        self.assertIn("Waldo_fnc_MHQRequestServer", mhq_local)
        self.assertIn("remoteExecutedOwner", mhq_server)
        self.assertIn('remoteExecCall ["Waldo_fnc_MHQPlayAudioLocal", 0]', mhq_server)
        self.assertIn("playSound3D", mhq_audio)
        self.assertIn("Waldo_VVD_LocalActionsInstalled", vvd)
        self.assertIn("Waldo_VVD_ClientSetupPublished", vvd)
        self.assertIn('remoteExecCall ["Waldo_fnc_VVDInit", -2, _depotSpawnerObject]', vvd)
        self.assertIn("ace_interact_menu_fnc_createAction", vvd)
        self.assertIn("addAction", vvd)
        self.assertIn("Waldo_fnc_VVDRequestOpenServer", vvd)
        self.assertIn('remoteExecCall ["Waldo_fnc_VVDRequestOpenServer", 2]', vvd_request)
        self.assertIn("remoteExecutedOwner", vvd_request)
        self.assertIn("Waldo_VVD_OpenToken", vvd_request)
        self.assertIn("Waldo_fnc_VVDReleaseOpenServer", vvd_open)
        self.assertIn('missionNamespace getVariable ["Garage_Loadout_Controls", []]', vvd_open)
        self.assertIn("INITIALISE_FAILED", vvd_open)
        self.assertIn("Waldo_VVD_OpenToken", vvd_release)
        self.assertIn("GarageDisplayDefine.hpp", audit_description)
        client_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runClientAudit.sqf").read_text(encoding="utf-8")
        server_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runServerAudit.sqf").read_text(encoding="utf-8")
        self.assertIn("core/logistics/mhq-vvd-actions", client_audit)
        self.assertIn("core/logistics/mhq-vvd-authority", server_audit)
        self.assertIn("core/logistics/vvd-lock-token", server_audit)

    def test_interaction_acquisition_rechecks_server_condition(self):
        acquire = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteractionAcquireServer.sqf").read_text(encoding="utf-8")
        server_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runServerAudit.sqf").read_text(encoding="utf-8")
        self.assertIn("if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor}", acquire)
        self.assertIn('Waldo_MG_Int_Condition', acquire)
        self.assertIn("interactions/authority/server-condition-rejection", server_audit)

    def test_remote_owner_validation_uses_execution_context(self):
        findings = []
        for source in (ROOT / "MissionScripts").rglob("*.sqf"):
            text = source.read_text(encoding="utf-8")
            if 'isNil "remoteExecutedOwner"' in text:
                findings.append(str(source.relative_to(ROOT)))
        self.assertEqual([], findings)

    def test_fortify_budget_dialog_default_is_within_slider_range(self):
        module = (ROOT / "MissionScripts" / "ZenModules" / "Zen_fortifyBudgetModule.sqf").read_text(encoding="utf-8")
        self.assertIn('[0, 500, 100, 0]', module)
        self.assertNotIn('[0, 500, 1000, 0]', module)

    def test_audit_checks_core_zen_icon_assets(self):
        client_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runClientAudit.sqf").read_text(encoding="utf-8")
        self.assertIn("core/zen/icons-present", client_audit)
        self.assertIn("fileExists _x", client_audit)

    def test_config_style_checker_scans_this_repository(self):
        checker = (ROOT / "releaseVerificationAndDeployment" / "config_style_checker.py").read_text(encoding="utf-8")
        self.assertIn("Path(__file__).resolve().parents[1]", checker)
        self.assertIn('{".cpp", ".hpp", ".ext", ".sqm"}', checker)
        self.assertNotIn('rootDir = "../cScripts"', checker)

    def test_player_facing_multiline_text_uses_arma_line_breaks(self):
        sources = [
            ROOT / "MissionScripts" / "EconomySystems" / "Core" / "applyPresetSelections.sqf",
            ROOT / "MissionScripts" / "EconomySystems" / "Core" / "setCommitmentModeEnabled.sqf",
            ROOT / "MissionScripts" / "EconomySystems" / "Core" / "setTestingNoticeEnabled.sqf",
            ROOT / "MissionScripts" / "EconomySystems" / "Resource" / "getZoneInfoText.sqf",
            ROOT / "MissionScripts" / "EconomySystems" / "Resource" / "startPubZeusZoneActionBridge.sqf",
            ROOT / "MissionScripts" / "MissionMakerResourceScripts" / "vehicleDamageMonitor.sqf",
        ]
        findings = [str(source.relative_to(ROOT)) for source in sources if "\\n" in source.read_text(encoding="utf-8")]
        self.assertEqual([], findings)

    def test_party_leave_dispatches_only_to_active_game(self):
        core = (ROOT / "MissionScripts" / "MiniGames" / "engine" / "core.sqf").read_text(encoding="utf-8")
        server_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runServerAudit.sqf").read_text(encoding="utf-8")
        release_start = core.index("Waldo_MG_fnc_releaseUnitSeatServer")
        release_end = core.index("Waldo_MG_fnc_initializePlayerServer", release_start)
        release_body = core[release_start:release_end]
        self.assertIn("switch ([_table] call Waldo_MG_fnc_getTableActiveGameId)", release_body)
        self.assertIn('case "drawpoker"', release_body)
        self.assertIn('case "liarsdice"', release_body)
        self.assertIn('case "connectfour"', release_body)
        self.assertIn("party/authority/leave-active-new-games", server_audit)

    def test_party_recurring_work_and_publication_are_change_driven(self):
        core = (ROOT / "MissionScripts" / "MiniGames" / "engine" / "core.sqf").read_text(encoding="utf-8")
        reconcile_start = core.index("Waldo_MG_fnc_reconcileOneTableServer")
        reconcile_end = core.index("Waldo_MG_fnc_reconcileRegisteredTablesServer", reconcile_start)
        reconcile_body = core[reconcile_start:reconcile_end]
        consensus_start = core.index("Waldo_MG_fnc_refreshTableConsensusServer")
        consensus_end = core.index("Waldo_MG_fnc_markTableServer", consensus_start)
        consensus_body = core[consensus_start:consensus_end]
        self.assertIn("switch ([_table] call Waldo_MG_fnc_getTableActiveGameId)", reconcile_body)
        self.assertIn('case "drawpoker"', reconcile_body)
        self.assertIn('case "liarsdice"', reconcile_body)
        self.assertIn('case "connectfour"', reconcile_body)
        self.assertIn("if (_changed) then", consensus_body)
        self.assertIn('"Waldo_MG_TableRevision"', consensus_body)

    def test_party_actions_are_ace_first_with_vanilla_fallback(self):
        core = (ROOT / "MissionScripts" / "MiniGames" / "engine" / "core.sqf").read_text(encoding="utf-8")
        action_start = core.index("Waldo_MG_fnc_ensureTableActionsLocal")
        action_end = core.index("Waldo_MG_fnc_isValidGameViewerLocal", action_start)
        action_body = core[action_start:action_end]
        client_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runClientAudit.sqf").read_text(encoding="utf-8")
        self.assertIn("Waldo_MG_TableACEActions", action_body)
        self.assertIn("Waldo_MG_PlayerACEActionsLocal", action_body)
        self.assertIn('Waldo_MG_TableInteractionMode", if (_aceReady) then {"ACE+VANILLA"}', action_body)
        self.assertIn('Waldo_MG_PlayerInteractionModeLocal', action_body)
        self.assertIn("addAction", action_body)
        self.assertIn("party/integration/linked-ace-vanilla-actions", client_audit)

    def test_first_party_action_installers_never_clear_foreign_actions(self):
        mission_scripts = ROOT / "MissionScripts"
        offenders = []
        for source in mission_scripts.rglob("*.sqf"):
            if "ThirdPartyScripts" in source.parts:
                continue
            executable = self.sqf_without_comments(source)
            if re.search(r"(?i)\bremoveAllActions\b", executable):
                offenders.append(str(source.relative_to(ROOT)))
        self.assertEqual([], offenders)

        client_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runClientAudit.sqf").read_text(encoding="utf-8")
        self.assertIn("party/integration/preserves-foreign-actions", client_audit)
        self.assertIn("actionIDs _table", client_audit)
        self.assertIn("actionIDs player", client_audit)

    def test_ui_commands_parenthesize_conditional_operands(self):
        invalid = re.compile(
            r"\b(?:ctrlSetText|ctrlSetStructuredText|ctrlSetBackgroundColor|ctrlSetTextColor|"
            r"ctrlSetPosition|ctrlEnable|ctrlShow|progressSetPosition|lbSetCurSel)\s+if\s*\("
        )
        findings = []
        for source in (ROOT / "MissionScripts").rglob("*.sqf"):
            for line_number, line in enumerate(source.read_text(encoding="utf-8").splitlines(), 1):
                if invalid.search(line):
                    findings.append(f"{source.relative_to(ROOT)}:{line_number}")
        self.assertEqual([], findings)

    def test_core_zen_modules_use_valid_configured_crate_classes(self):
        medical = (ROOT / "MissionScripts" / "ZenModules" / "Zen_medicalCrateModule.sqf").read_text(encoding="utf-8")
        supply = (ROOT / "MissionScripts" / "ZenModules" / "Zen_supplyCrateModule.sqf").read_text(encoding="utf-8")
        crate_server = (ROOT / "MissionScripts" / "ZenModules" / "ZenSpawnCrateServer.sqf").read_text(encoding="utf-8")
        convoy = (ROOT / "MissionScripts" / "ZenModules" / "Zen_convoyModule.sqf").read_text(encoding="utf-8")
        self.assertIn('remoteExecCall ["Waldo_fnc_ZenSpawnCrateServer", 2]', medical)
        self.assertIn('remoteExecCall ["Waldo_fnc_ZenSpawnCrateServer", 2]', supply)
        self.assertIn("if (!isServer) exitWith", crate_server)
        self.assertIn("remoteExecutedOwner", crate_server)
        self.assertIn("getAssignedCuratorLogic", crate_server)
        self.assertIn("lineIntersectsSurfaces", crate_server)
        self.assertIn("boundingBoxReal _crate", crate_server)
        self.assertNotIn("private _groundPosition", crate_server)
        for variable in ("Logi_MedicalBoxClass", "Logi_SupplyBoxClass"):
            self.assertIn(f'missionNamespace getVariable ["{variable}"', crate_server)
        self.assertIn('remoteExec ["Waldo_fnc_SimpleAiConvoy", _owner]', convoy)

    def test_jamming_uses_one_combined_panel_and_server_zen_mutation(self):
        hud = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingHud.sqf").read_text(encoding="utf-8")
        toggle = (ROOT / "MissionScripts" / "ZenModules" / "Zen_jammerToggleModule.sqf").read_text(encoding="utf-8")
        remove = (ROOT / "MissionScripts" / "ZenModules" / "Zen_jammerRemoveModule.sqf").read_text(encoding="utf-8")
        self.assertIn("Waldo_JammingHudChannels", hud)
        self.assertIn('displayCtrl 5310', hud)
        self.assertNotIn('ctrlCreate ["RscStructuredText", _idc]', hud)
        for source, function_name in ((toggle, "Waldo_fnc_ZenJammerToggle"), (remove, "Waldo_fnc_ZenJammerRemove")):
            self.assertIn("if (!isServer) exitWith", source)
            self.assertIn(f'remoteExecCall ["{function_name}", 2]', source)
            self.assertIn("remoteExecutedOwner", source)
        create_server = (ROOT / "MissionScripts" / "ZenModules" / "ZenCreateJammerServer.sqf").read_text(encoding="utf-8")
        self.assertIn("getAssignedCuratorLogic", create_server)
        self.assertIn("createVehicle", create_server)

    def test_jammer_disable_challenge_uses_server_authority_and_actor_gate(self):
        create = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammerCreate.sqf").read_text(encoding="utf-8")
        interaction = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammerInteraction.sqf").read_text(encoding="utf-8")
        disable = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammerDisableServer.sqf").read_text(encoding="utf-8")
        generic = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteraction.sqf").read_text(encoding="utf-8")
        acquire = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteractionAcquireServer.sqf").read_text(encoding="utf-8")
        zen = (ROOT / "MissionScripts" / "ZenModules" / "Zen_jammerPlaceModule.sqf").read_text(encoding="utf-8")
        fixture = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeServer.sqf").read_text(encoding="utf-8")
        self.assertIn('remoteExec ["Waldo_fnc_JammerInteraction", 0, _object]', create)
        self.assertIn('call Waldo_fnc_MiniGameInteractionSetup', interaction)
        self.assertIn('"actorCondition"', interaction)
        self.assertIn('call Waldo_fnc_JammerDisableServer', interaction)
        self.assertIn('["actionTitle", "Disable Jammer"]', interaction)
        self.assertIn('["directAceAction", true]', interaction)
        self.assertIn('if (!isServer', disable)
        self.assertIn('remoteExecutedOwner', disable)
        self.assertIn('Waldo_MG_InteractionState', disable)
        self.assertIn('Waldo_MG_InteractionResult', disable)
        self.assertIn('Waldo_MG_Int_ActorCondition', generic)
        self.assertNotIn('ace_common_fnc_canInteractWith', generic)
        self.assertIn('_distance\n    ] call ace_interact_menu_fnc_createAction', generic)
        self.assertIn('Waldo_MG_Int_ActorCondition', acquire)
        for label in ("Require Field Disable Procedure", "Disable Procedure", "Procedure Difficulty"):
            self.assertIn(label, zen)
        for advanced_label in ("Engineers Only", "Successful Disable Result", "Allow Direct Player Toggle"):
            self.assertNotIn(advanced_label, zen)
        self.assertIn('["disableChallenge", true]', fixture)
        self.assertIn('["engineerOnly", false]', fixture)

    def test_feature_zen_interaction_options_are_simplified_and_authoritative(self):
        aa_zen = (ROOT / "MissionScripts" / "CombatSystems" / "DynamicAA" / "dynamicAAZen.sqf").read_text(encoding="utf-8")
        aa_create = (ROOT / "MissionScripts" / "CombatSystems" / "DynamicAA" / "dynamicAACreate.sqf").read_text(encoding="utf-8")
        aa_interaction = (ROOT / "MissionScripts" / "CombatSystems" / "DynamicAA" / "dynamicAAInteractionSetup.sqf").read_text(encoding="utf-8")
        runtime_zen = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeZen.sqf").read_text(encoding="utf-8")
        tactical = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "TacticalDisplay" / "tacticalDisplayRegister.sqf").read_text(encoding="utf-8")
        tactical_interaction = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "TacticalDisplay" / "tacticalDisplayInteractionSetup.sqf").read_text(encoding="utf-8")
        recovery = (ROOT / "MissionScripts" / "Logistics" / "VehicleRecovery" / "recoveryRegisterVehicle.sqf").read_text(encoding="utf-8")
        recovery_interaction = (ROOT / "MissionScripts" / "Logistics" / "VehicleRecovery" / "recoveryInteractionSetup.sqf").read_text(encoding="utf-8")
        recovery_restore = (ROOT / "MissionScripts" / "Logistics" / "VehicleRecovery" / "recoveryRestoreServer.sqf").read_text(encoding="utf-8")
        for label in ("Require Radar Shutdown Procedure", "Shutdown Procedure", "Procedure Difficulty"):
            self.assertIn(label, aa_zen)
        for label in ("Require Recovery Preparation", "Preparation Procedure", "Require Display Authentication", "Authentication Procedure"):
            self.assertIn(label, runtime_zen)
        self.assertIn('remoteExecCall ["Waldo_fnc_DynamicAAInteractionSetup", 0, _radar]', aa_create)
        self.assertIn('call Waldo_fnc_DynamicAADestroy', aa_interaction)
        self.assertIn('["actionTitle", "Disable AA System"]', aa_interaction)
        self.assertIn('["directAceAction", true]', aa_interaction)
        self.assertIn('Waldo_TacticalDisplay_Unlocked', tactical)
        self.assertIn('remoteExecCall ["Waldo_fnc_TacticalDisplayInteractionSetup", 0, _object]', tactical)
        self.assertIn('["actionTitle", "Access Tactical Display"]', tactical_interaction)
        self.assertIn('["directAceAction", true]', tactical_interaction)
        self.assertIn('Waldo_Recovery_InteractionEnabled', recovery)
        self.assertIn('call Waldo_fnc_RecoveryRequestServer', recovery_interaction)
        self.assertIn('["actionTitle", "Package Vehicle for Recovery"]', recovery_interaction)
        self.assertIn('["directAceAction", true]', recovery_interaction)
        self.assertIn('createHashMapFromArray', recovery_restore)
        self.assertIn('call Waldo_fnc_RecoveryRegisterVehicle', recovery_restore)
        self.assertNotIn('"onSuccess"', aa_zen)
        self.assertNotIn('"onSuccess"', runtime_zen)

    def test_ace_actions_are_nested_and_linked_vanilla_is_configurable(self):
        economy_actions = (ROOT / "MissionScripts" / "EconomySystems" / "Core" / "ensureLocalObjectAction.sqf").read_text(encoding="utf-8")
        economy_zen = (ROOT / "MissionScripts" / "EconomySystems" / "Core" / "registerZenModules.sqf").read_text(encoding="utf-8")
        audit_init = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "init.sqf").read_text(encoding="utf-8")
        self.assertIn("WaldoEco_Operations", economy_actions)
        self.assertIn("Waldo_Interactions_LinkVanillaWithACE", economy_actions)
        self.assertIn("addAction", economy_actions)
        self.assertEqual(19, economy_zen.count("call Waldo_fnc_EcoCore_logZenModule"))
        self.assertIn("WaldoEcoCore_ZenModuleCount", economy_zen)
        self.assertIn('auditPreInit.sqf', audit_init)
        self.assertIn('Waldo_Economy_Enable = missionNamespace getVariable', audit_init)
        self.assertIn('auditInit.sqf', audit_init)

    def test_interaction_surface_policy_matches_feature_complexity(self):
        loadout = (ROOT / "MissionScripts" / "ZenModules" / "Zen_loadoutSaveSetup.sqf").read_text(encoding="utf-8")
        interaction = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteraction.sqf").read_text(encoding="utf-8")
        mhq = (ROOT / "MissionScripts" / "Logistics" / "MHQ" / "MHQSetupLocal.sqf").read_text(encoding="utf-8")
        vvd = (ROOT / "MissionScripts" / "Logistics" / "VirtualVehicleDepot" / "VVDInit.sqf").read_text(encoding="utf-8")
        quartermaster = (ROOT / "MissionScripts" / "Logistics" / "Crates" / "initQuartermaster.sqf").read_text(encoding="utf-8")
        self.assertIn('"ACE+VANILLA"', loadout)
        self.assertIn('"ACE+VANILLA"', interaction)
        self.assertIn('if (_aceReady) then {"ACE"} else {"VANILLA"}', mhq)
        self.assertNotIn('"ACE+VANILLA"', vvd)
        self.assertIn("Waldo_QM_VanillaActionIds", quartermaster)
        self.assertIn("Waldo_QM_Category", quartermaster)

    def test_resource_collection_reports_partial_and_deletes_full_crates(self):
        collect = (ROOT / "MissionScripts" / "EconomySystems" / "Resource" / "collectCrate.sqf").read_text(encoding="utf-8")
        server_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runServerAudit.sqf").read_text(encoding="utf-8")
        fixture = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeServer.sqf").read_text(encoding="utf-8")
        self.assertIn("Container remains because storage is full", collect)
        self.assertIn("deleteVehicle _crate", collect)
        self.assertIn("economy/resource/full-crate-consumed", server_audit)
        self.assertIn('[["Money", 100], ["Parts", 5]]', fixture)

    def test_safestart_countdown_has_runtime_completion_gate(self):
        timer = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "safeStartTimer.sqf").read_text(encoding="utf-8")
        server_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runServerAudit.sqf").read_text(encoding="utf-8")
        self.assertIn("countdown completed", timer)
        self.assertIn("countdown stopped before completion", timer)
        self.assertIn("core/safestart/countdown-auto-lift", server_audit)

    def test_safestart_timer_is_configured_in_seconds_and_displayed_as_mmss(self):
        module = (ROOT / "MissionScripts" / "ZenModules" / "Zen_safeStartTimer.sqf").read_text(encoding="utf-8")
        apply = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "safeStartApply.sqf").read_text(encoding="utf-8")
        self.assertIn('["Seconds"', module)
        self.assertNotIn("_minutes * 60", module)
        self.assertIn("floor (_rem / 60)", apply)
        self.assertIn("_rem % 60", apply)

    def test_briefing_structured_text_escapes_ampersands(self):
        briefing = ROOT / "MissionScripts" / "MissionInit" / "BriefingDocuments"
        raw_entity = re.compile(r"&(?!amp;|lt;|gt;|quot;|apos;|#\d+;|#x[0-9A-Fa-f]+;)")
        findings = []
        for path in briefing.glob("*.sqf"):
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if any(tag in line for tag in ("<br", "<t", "<font")) and raw_entity.search(line):
                    findings.append(f"{path.name}:{line_number}")
        self.assertEqual([], findings)

    def test_feature_diagnostics_use_one_public_normal_form(self):
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        expected = {
            "DiagnosticFeatureReport": ROOT / "MissionScripts" / "MissionFlowAndUi" / "diagnosticFeatureReport.sqf",
            "SafeStartGetDiagnostics": ROOT / "MissionScripts" / "MissionFlowAndUi" / "safeStartGetDiagnostics.sqf",
            "ENDEXGetDiagnostics": ROOT / "MissionScripts" / "MissionFlowAndUi" / "endexGetDiagnostics.sqf",
            "EcoCore_getDiagnostics": ROOT / "MissionScripts" / "EconomySystems" / "Core" / "getDiagnostics.sqf",
            "MiniGameInteractionGetDiagnostics": ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteractionGetDiagnostics.sqf",
        }
        for function_name, path in expected.items():
            self.assertIn(f"class {function_name}", functions)
            self.assertTrue(path.is_file())
        normal = expected["DiagnosticFeatureReport"].read_text(encoding="utf-8")
        for field in ("schema", "feature", "state", "checks", "errorCount", "generatedAt", "locality", "clientOwner"):
            self.assertIn(f'["{field}"', normal)
        server = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnostics.sqf").read_text(encoding="utf-8")
        client = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnosticsClient.sqf").read_text(encoding="utf-8")
        for function_name in ("SafeStartGetDiagnostics", "ENDEXGetDiagnostics", "EcoCore_getDiagnostics", "MiniGameInteractionGetDiagnostics"):
            self.assertIn(f"Waldo_fnc_{function_name}", server)
            self.assertIn(f"Waldo_fnc_{function_name}", client)

    def test_safestart_and_endex_own_their_protection_state(self):
        flow = ROOT / "MissionScripts" / "MissionFlowAndUi"
        safestart = (flow / "safeStartApply.sqf").read_text(encoding="utf-8")
        endex = (flow / "ENDEX.sqf").read_text(encoding="utf-8")
        reset = (flow / "ENDEXReset.sqf").read_text(encoding="utf-8")
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        acquire = (flow / "protectionAcquireSafety.sqf").read_text(encoding="utf-8")
        release = (flow / "protectionReleaseSafety.sqf").read_text(encoding="utf-8")
        for token in ("Waldo_SafeStart_FiredEH", "Waldo_SafeStart_PlayerDamageWasAllowed"):
            self.assertIn(token, safestart)
        for token in ("Waldo_ENDEX_Active", "Waldo_PreventWeaponsFireEventHandler", "Waldo_ENDEX_PlayerDamageWasAllowed"):
            self.assertIn(token, endex)
            self.assertIn(token, reset)
        self.assertIn("class ENDEXReset", functions)
        self.assertIn("class ProtectionAcquireSafety", functions)
        self.assertIn("class ProtectionReleaseSafety", functions)
        self.assertIn('missionNamespace getVariable ["Waldo_ENDEX_Active", false]', safestart)
        self.assertIn('missionNamespace getVariable ["Waldo_SafeStart_Active", false]', reset)
        for source in (safestart, endex, reset):
            self.assertIn("Waldo_WMPProtection_DamageBaseline", source)
        self.assertIn('["SAFESTART"] call Waldo_fnc_ProtectionAcquireSafety', safestart)
        self.assertIn('["SAFESTART"] call Waldo_fnc_ProtectionReleaseSafety', safestart)
        self.assertIn('["ENDEX"] call Waldo_fnc_ProtectionAcquireSafety', endex)
        self.assertIn('["ENDEX"] call Waldo_fnc_ProtectionReleaseSafety', reset)
        self.assertIn("Waldo_WMPProtection_SafetyClaims", acquire)
        self.assertIn("Waldo_WMPProtection_OwnedSafety", release)
        self.assertIn("_muzzle in _safedMuzzles", release)
        self.assertNotIn("currentWeapon player", release)

    def test_economy_buildables_never_use_visual_fallback_objects(self):
        build = ROOT / "MissionScripts" / "EconomySystems" / "Build"
        resolver = (build / "getBuildSpawnClass.sqf").read_text(encoding="utf-8")
        validator = (build / "hasBuildEntryError.sqf").read_text(encoding="utf-8")
        spawner = (build / "spawnConfiguredBuilding.sqf").read_text(encoding="utf-8")
        placement = (build / "beginPlayerConstructionPlacement.sqf").read_text(encoding="utf-8")
        construction_ui = (build / "getOfficialConstructionModeActionArgs.sqf").read_text(encoding="utf-8")
        economy = (ROOT / "MissionScripts" / "EconomySystems" / "economyInit.sqf").read_text(encoding="utf-8")
        self.assertIn('isClass (configFile >> "CfgVehicles" >> _className)', validator)
        self.assertIn('if (_spawnClass isEqualTo "") exitWith', spawner)
        self.assertIn("INVALID_CFGVEHICLES_CLASS", spawner)
        self.assertIn('if (_previewClass isEqualTo "") exitWith', placement)
        self.assertNotIn('"PortableHelipadLight_01_red_F"', resolver)
        self.assertNotIn('"PortableHelipadLight_01_red_F"', construction_ui)
        for path in build.rglob("*.sqf"):
            self.assertNotIn("PortableHelipadLight_01_red_F", path.read_text(encoding="utf-8"), path)
        self.assertNotIn("Land_WindTurbine_01_F", economy)
        self.assertIn("Land_wpp_Turbine_V2_F", economy)
        zone_anchor = (ROOT / "MissionScripts" / "EconomySystems" / "Resource" / "createZoneAnchor.sqf").read_text(encoding="utf-8")
        self.assertIn("PortableHelipadLight_01_red_F", zone_anchor)
        diagnostics = (ROOT / "MissionScripts" / "EconomySystems" / "Core" / "getDiagnostics.sqf").read_text(encoding="utf-8")
        self.assertIn('"economy-build-classes"', diagnostics)
        self.assertIn('isClass (configFile >> "CfgVehicles" >> _className)', diagnostics)

    def test_emp_feedback_and_loadout_save_inventory_policy(self):
        emp_module = (ROOT / "MissionScripts" / "ZenModules" / "Zen_empModule.sqf").read_text(encoding="utf-8")
        emp_apply = (ROOT / "MissionScripts" / "MissionInit" / "ElectronicWarfare" / "empApply.sqf").read_text(encoding="utf-8")
        loadout = (ROOT / "MissionScripts" / "ZenModules" / "Zen_loadoutSaveModule.sqf").read_text(encoding="utf-8")
        self.assertNotIn("systemChat", emp_module)
        self.assertIn("Waldo_EMP_NotifyAffectedPlayers", emp_apply)
        self.assertNotIn("systemChat", emp_apply)
        target_policy = loadout[loadout.index("if (!isNull _objectPos)"):]
        existing_branch, created_branch = target_policy.split("} else {", 1)
        self.assertNotIn("clearWeaponCargoGlobal", existing_branch)
        for command in ("clearWeaponCargoGlobal", "clearMagazineCargoGlobal", "clearItemCargoGlobal", "clearBackpackCargoGlobal"):
            self.assertIn(command, created_branch)

    def test_custom_3d_marker_api_is_registered(self):
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        for function_name in ("Create3DMarker", "Remove3DMarker", "Init3DMarkers"):
            self.assertIn(f"class {function_name}", functions)

    def test_jamming_indicator_uses_non_ground_los_endpoint(self):
        factor = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingFactor.sqf").read_text(encoding="utf-8")
        init = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingInit.sqf").read_text(encoding="utf-8")
        client_audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "runClientAudit.sqf").read_text(encoding="utf-8")
        self.assertIn("ASLToAGL _losTo", factor)
        self.assertIn("_losTo set [2", factor)
        self.assertIn("Local player state=%1", init)
        self.assertIn("ew/client/jamming-factor-near-emitter", client_audit)

    def test_transient_huds_use_padded_safe_viewport(self):
        safestart_sources = [
            ROOT / "MissionScripts" / "MissionFlowAndUi" / "safeStartHud.sqf",
            ROOT / "MissionScripts" / "MissionFlowAndUi" / "safeStartNotice.sqf",
        ]
        for source in safestart_sources:
            text = source.read_text(encoding="utf-8")
            self.assertIn("safeZoneX + ((safeZoneW - _panelW) / 2)", text, source)
            self.assertIn("_maximumContentH", text, source)
            self.assertNotIn("parseText str _content", text, source)

    def test_public_ui_notifications_and_local_cleanup_are_owned_and_repeat_safe(self):
        flow = ROOT / "MissionScripts" / "MissionFlowAndUi"
        show = (flow / "showUiNotification.sqf").read_text(encoding="utf-8")
        reflow = (flow / "reflowUiPanels.sqf").read_text(encoding="utf-8")
        drain = (flow / "drainUiNotificationQueue.sqf").read_text(encoding="utf-8")
        placement = (flow / "setUiPanelPlacement.sqf").read_text(encoding="utf-8")
        local_placement = (flow / "setLocalUiPanelPlacement.sqf").read_text(encoding="utf-8")
        cleanup = (flow / "cleanupTransientUi.sqf").read_text(encoding="utf-8")
        clear = (flow / "clearUiPanels.sqf").read_text(encoding="utf-8")
        setup = (flow / "setupUiCleanupAction.sqf").read_text(encoding="utf-8")
        init_player = (ROOT / "initPlayerLocal.sqf").read_text(encoding="utf-8")
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        economy = (ROOT / "MissionScripts" / "EconomySystems" / "Core" / "notifyActorLocal.sqf").read_text(encoding="utf-8")
        for function_name in ("ShowUiNotification", "ClearUiPanels", "SetupUiCleanupAction", "SetUiPanelsSuppressed", "SetupUiAcePriority", "SetUiPanelPlacement", "SetLocalUiPanelPlacement", "ReflowUiPanels", "DrainUiNotificationQueue"):
            self.assertIn(f"class {function_name}", functions)
        for token in ("safeZoneX", "safeZoneY", "safeZoneW", "safeZoneH", "ctrlTextHeight", "_padX", "_padY"):
            self.assertIn(token, show + reflow)
        for symbol in ('"[OK]"', '"[!]"', '"[X]"', '"[i]"'):
            self.assertIn(symbol, show)
        self.assertIn("Waldo_UiPanelRegistry", show)
        self.assertIn("Waldo_UiPanelRegistry", cleanup)
        self.assertIn("Waldo_UiPanelQueue", show)
        self.assertIn("Waldo_UiPanelQueue", drain)
        self.assertIn("Waldo_UiNotification_MaximumQueued", show)
        self.assertIn("Waldo_UiNotification_QueueLifetime", show)
        self.assertIn("Waldo_UiNotification_AllowPlacementOverflow", show)
        self.assertIn("Waldo_UiNotification_OverflowPlacements", drain)
        self.assertIn("Waldo_UI_PanelsSuppressed", show)
        self.assertIn("Waldo_UI_PanelsSuppressed", drain)
        self.assertIn('["BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"]', show)
        self.assertIn('["BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"]', drain)
        self.assertNotIn('["TOP", "BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"]', show)
        self.assertNotIn('["TOP", "BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"]', drain)
        self.assertIn("Waldo_UiNotification_DisplayWaitQueue", show)
        self.assertIn("_sameChannel", show)
        self.assertIn("_queue select", show)
        self.assertIn('"FIFO"', show)
        self.assertIn('"REPLACE"', show)
        self.assertIn("Waldo_UI_PanelPlacements", placement)
        self.assertIn("Waldo_UI_PanelPlacements", init_player)
        self.assertIn('["TREATMENT_FEEDBACK", "BOTTOM_CENTER", true]', init_player)
        self.assertIn("Waldo_TreatmentFeedback_Duration", init_player)
        self.assertIn('case "BOTTOM_CENTER"', show + reflow)
        self.assertIn('["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"]', reflow)
        self.assertIn("Waldo_UI_LocalPanelPlacements", local_placement)
        self.assertIn("ctrlDelete", cleanup)
        self.assertIn("hasInterface", clear)
        self.assertNotIn("remoteExec", clear)
        self.assertIn("ace_interact_menu_fnc_addActionToObject", setup)
        self.assertIn("} else {", setup)
        self.assertIn("player addAction", setup)
        self.assertIn("Waldo_UI_CleanupActionInstalled", setup)
        self.assertGreaterEqual(init_player.count("Waldo_fnc_SetupUiCleanupAction"), 2)
        self.assertIn("Waldo_fnc_SetupUiAcePriority", init_player)
        ace_priority = (flow / "setupUiAcePriority.sqf").read_text(encoding="utf-8")
        suppression = (flow / "setUiPanelsSuppressed.sqf").read_text(encoding="utf-8")
        self.assertIn('"ace_interactMenuOpened"', ace_priority)
        self.assertIn('"ace_interactMenuClosed"', ace_priority)
        self.assertIn("ctrlShow !_suppressed", suppression)
        self.assertIn("Waldo_fnc_ShowUiNotification", economy)
        feature_client = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeClient.sqf").read_text(encoding="utf-8")
        self.assertIn("SHOW CUSTOM WMP UI NOTICE", feature_client)
        self.assertIn("SHOW UI OVERFLOW / COALESCE TEST", feature_client)
        self.assertIn('for "_index" from 1 to 25', feature_client)
        self.assertIn("MOVE QA UI CHANNEL BOTTOM LEFT", feature_client)
        self.assertIn("CLEAR ALL WMP UI", feature_client)
        ew_sources = [
            ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingHud.sqf",
            ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingNotice.sqf",
        ]
        for source in ew_sources:
            text = source.read_text(encoding="utf-8")
            self.assertIn("private _visibleX = safeZoneX", text, source)
            self.assertIn("private _visibleRight = safeZoneX + safeZoneW", text, source)

    def test_interaction_shell_and_eod_text_have_runtime_fit_guards(self):
        shell = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Core" / "challengeUi.sqf").read_text(encoding="utf-8")
        validator = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Core" / "equipmentValidateDisplay.sqf").read_text(encoding="utf-8")
        eod = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Challenges" / "challengeWireCut.sqf").read_text(encoding="utf-8")
        self.assertIn("Waldo_MG_UI_ShellControls", shell)
        self.assertIn("_footerHint", shell)
        self.assertIn("_footerAbort", shell)
        self.assertIn("SHELL_OUTSIDE_VISIBLE_AREA", validator)
        self.assertIn("SHELL_TEXT_HEIGHT_CLIPPED", validator)
        self.assertIn("SHELL_TEXT_WIDTH_CLIPPED", validator)
        self.assertIn("_fitInstruction", eod)
        self.assertIn("ctrlTextHeight _control", eod)

    def test_diagnostics_do_not_require_lazy_interaction_registry(self):
        server = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnostics.sqf").read_text(encoding="utf-8")
        client = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnosticsClient.sqf").read_text(encoding="utf-8")
        helper = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteractionGetDiagnostics.sqf").read_text(encoding="utf-8")
        self.assertIn("Waldo_fnc_MiniGameInteractionGetDiagnostics", server)
        self.assertIn("Waldo_fnc_MiniGameInteractionGetDiagnostics", client)
        self.assertIn("locallyRegistered=%3", helper)
        self.assertIn('"UNCONFIGURED"', helper)
        self.assertNotIn("registered procedure(s); expected at least 10", server)

    def test_vehicle_recovery_is_server_owned_jip_safe_and_configurable(self):
        root = ROOT / "MissionScripts" / "Logistics" / "VehicleRecovery"
        register_vehicle = (root / "recoveryRegisterVehicle.sqf").read_text(encoding="utf-8")
        register_workshop = (root / "recoveryRegisterWorkshop.sqf").read_text(encoding="utf-8")
        request = (root / "recoveryRequestServer.sqf").read_text(encoding="utf-8")
        restore = (root / "recoveryRestoreServer.sqf").read_text(encoding="utf-8")
        monitor = (root / "recoveryMonitorServer.sqf").read_text(encoding="utf-8")
        self.assertIn('remoteExecCall ["Waldo_fnc_RecoverySetupVehicleLocal", 0, _vehicle]', register_vehicle)
        self.assertIn("getAssignedCuratorLogic", register_vehicle + register_workshop)
        self.assertIn("remoteExecutedOwner != owner _actor", request)
        self.assertIn('getVariable ["Waldo_Recovery_Side"', request)
        self.assertIn("getObjectTextures", request)
        self.assertIn("getPylonMagazines", request)
        self.assertIn("getWeaponCargo", request)
        self.assertIn("Waldo_fnc_RecoveryRegisterVehicle", restore)
        self.assertIn("Waldo_fnc_RecoveryRegisterCarrier", restore)
        self.assertIn("Waldo_Recovery_ScanInterval", monitor)
        self.assertNotRegex(monitor, r"setVariable\s*\[[^\]]+,\s*true,\s*true\s*\]")

    def test_rally_points_are_group_owned_and_do_not_leak_global_markers(self):
        root = ROOT / "MissionScripts" / "Respawn" / "RallyPoint"
        request = (root / "rallyPointRequestServer.sqf").read_text(encoding="utf-8")
        marker = (root / "rallyPointMarkerLocal.sqf").read_text(encoding="utf-8")
        setup = (root / "rallyPointSetupLocal.sqf").read_text(encoding="utf-8")
        runtime = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeApply.sqf").read_text(encoding="utf-8")
        snapshot = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeRequestState.sqf").read_text(encoding="utf-8")
        for token in ("Waldo_Rally_Active", "Waldo_Rally_CooldownUntil", "Waldo_Rally_ExpiresAt"):
            self.assertIn(token, request)
        self.assertIn("remoteExecutedOwner != owner _actor", request)
        self.assertIn("BIS_fnc_addRespawnPosition", request)
        self.assertIn('remoteExecCall ["Waldo_fnc_RallyPointMarkerLocal", 0, _rally]', request)
        self.assertNotIn("createMarker [", request)
        self.assertIn("createMarkerLocal", marker)
        self.assertIn("group player != _group", marker)
        self.assertIn("BIS_fnc_holdActionAdd", setup)
        self.assertIn('remoteExecCall ["Waldo_fnc_RallyPointInit", -2, "Waldo_Rally_RuntimeInit"]', runtime)
        self.assertIn('remoteExecCall ["", "Waldo_Rally_RuntimeInit"]', runtime)
        self.assertIn('"Waldo_Rally_DeploymentTime"', snapshot)

    def test_pr_feature_feedback_uses_pack_ui_without_hint_output(self):
        feature_paths = [
            ROOT / "MissionScripts" / "CombatSystems" / "AirborneGunship",
            ROOT / "MissionScripts" / "CombatSystems" / "DynamicAA",
            ROOT / "MissionScripts" / "EnvironmentalSystems" / "TreeFelling",
            ROOT / "MissionScripts" / "Logistics" / "FieldResupply",
            ROOT / "MissionScripts" / "Logistics" / "VehicleRecovery",
            ROOT / "MissionScripts" / "MedicalSystems" / "TreatmentFeedback",
            ROOT / "MissionScripts" / "Respawn" / "RallyPoint",
        ]
        source = "\n".join(path.read_text(encoding="utf-8") for root in feature_paths for path in root.glob("*.sqf"))
        self.assertNotRegex(source, r"\bhint(?:Silent|C)?\s")
        self.assertIn("Waldo_fnc_ShowUiNotification", source)
        self.assertIn("Waldo_fnc_FeatureNotifyLocal", source)

    def test_respawn_loadout_feedback_uses_pack_ui_without_hint_output(self):
        source = (
            ROOT
            / "MissionScripts"
            / "Logistics"
            / "LogiHelpers"
            / "saveRespawnLoadout.sqf"
        ).read_text(encoding="utf-8")
        self.assertNotRegex(source, r"\bhint(?:Silent|C)?\s")
        self.assertIn("Waldo_fnc_ShowUiNotification", source)
        self.assertIn('"RESPAWN_LOADOUT"', source)

    def test_runtime_zen_uses_filtered_selectors_and_hides_internal_ids(self):
        runtime = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeZen.sqf").read_text(encoding="utf-8")
        dynamic_aa = (ROOT / "MissionScripts" / "CombatSystems" / "DynamicAA" / "dynamicAAZen.sqf").read_text(encoding="utf-8")
        jammer = (ROOT / "MissionScripts" / "ZenModules" / "Zen_jammerPlaceModule.sqf").read_text(encoding="utf-8")
        self.assertNotIn('ctrlAddEventHandler ["LBSelChanged"', runtime)
        self.assertNotIn('ctrlAddEventHandler ["LBSelChanged"', dynamic_aa)
        self.assertNotIn('getVariable ["zen_dialog_params"', runtime + dynamic_aa)
        self.assertNotIn('controlsGroupCtrl 1003', runtime + dynamic_aa)
        self.assertIn("Waldo_Gunship_SideAircraftPools", runtime)
        self.assertIn('configProperties [configFile >> "CfgVehicles"', runtime)
        self.assertIn("operational side", runtime.lower())
        self.assertIn("does not restrict the physical", runtime)
        self.assertIn("does not restrict the physical AA assets", dynamic_aa)
        self.assertNotIn('["EDIT", ["Aircraft class"', runtime)
        self.assertNotIn('["EDIT", ["System ID"', runtime + dynamic_aa)
        self.assertNotIn('["EDIT", ["Asset faction/pool key"', dynamic_aa)
        self.assertIn('["COMBO", ["Emitter object"', jammer)
        self.assertIn('["COMBO", ["ACRE frequency coverage"', jammer)

    def test_ai_profiles_have_wmp_names_and_nvg_aware_low_light_tuning(self):
        profile_init = (ROOT / "MissionScripts" / "AiScripting" / "aiRebalanceInit.sqf").read_text(encoding="utf-8")
        apply_profile = (ROOT / "MissionScripts" / "AiScripting" / "aiApplyProfile.sqf").read_text(encoding="utf-8")
        runtime = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeZen.sqf").read_text(encoding="utf-8")
        mission_init = (ROOT / "init.sqf").read_text(encoding="utf-8")
        for key in ("MILITIA", "LINE", "VETERAN", "ELITE"):
            self.assertIn(f'["{key}", createHashMapFromArray', profile_init)
        for label in ("WMP Militia", "WMP Line", "WMP Veteran", "WMP Elite"):
            self.assertIn(label, mission_init + runtime)
        self.assertIn("Waldo_AI_ProfileDisplayNames", mission_init + runtime)
        self.assertIn("Waldo_AI_NightNVGMultipliers", apply_profile)
        self.assertIn("Waldo_AI_NightUnaidedMultipliers", apply_profile)
        self.assertIn('if (hmd _unit != "")', apply_profile)
        self.assertIn("(_unit skill _x) *", apply_profile)

    def test_tactical_display_and_audit_economy_use_real_supported_paths(self):
        tactical = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "TacticalDisplay" / "tacticalDisplaySetupLocal.sqf").read_text(encoding="utf-8")
        feature_range = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeServer.sqf").read_text(encoding="utf-8")
        self.assertIn("[player, 'VIEW', _target] checkVisibility", tactical)
        self.assertNotIn("[player, 'VIEW'] checkVisibility", tactical)
        self.assertIn("Waldo_QA_fnc_configureEconomyServer", feature_range)
        self.assertNotIn('["Money", "#7BC86A"', feature_range)
        self.assertNotIn("Waldo_fnc_EcoResearch_setResearchCatalog", feature_range)
        self.assertNotIn("Waldo_fnc_EcoBuild_setBuildCatalog", feature_range)
        self.assertNotIn("Waldo_fnc_EcoBuy_setPurchaseCatalog", feature_range)
        self.assertIn("Waldo_fnc_EcoResource_getResourceTypes", feature_range)
        self.assertIn("_qaZoneResource", feature_range)

    def test_parser_extracts_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            rpt = Path(directory) / "test.rpt"
            rpt.write_text('12:00 "WMP FULL AUDIT FAIL: [\'FAIL\',\'case/id\',\'bad\',1,2,true,false]"\n', encoding="utf-8")
            records = PARSER.parse(rpt)
            self.assertEqual(records[0]["kind"], "FAIL")


if __name__ == "__main__":
    unittest.main()
