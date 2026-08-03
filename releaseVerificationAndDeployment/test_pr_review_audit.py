import importlib.util
import json
import math
import os
import re
import stat
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUILDER_PATH = ROOT / "releaseVerificationAndDeployment" / "build_pr_review_audit.py"
SPEC = importlib.util.spec_from_file_location("build_pr_review_audit", BUILDER_PATH)
BUILDER = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(BUILDER)


class PrReviewAuditTests(unittest.TestCase):
    def test_build_uses_release_contract_and_real_startup(self):
        with tempfile.TemporaryDirectory() as temp:
            destination = Path(temp) / "WMP_PR_Review_Audit.VR"
            BUILDER.build(destination, "all", "manual")
            config = json.loads(
                (ROOT / "releaseVerificationAndDeployment" / "config.json").read_text(encoding="utf-8")
            )
            for entry in config["build"]["include"]:
                self.assertTrue((destination / entry).exists(), entry)
            for entry in ("MissionScripts", "Pictures"):
                source_files = {
                    path.relative_to(ROOT / entry) for path in (ROOT / entry).rglob("*") if path.is_file()
                }
                staged_files = {
                    path.relative_to(destination / entry)
                    for path in (destination / entry).rglob("*") if path.is_file()
                }
                self.assertEqual(source_files, staged_files)
                for relative in source_files:
                    self.assertEqual(
                        (ROOT / entry / relative).read_bytes(),
                        (destination / entry / relative).read_bytes(),
                    )
            self.assertTrue((destination / "mission.sqm").read_text(encoding="utf-8").startswith("version=12;"))
            description = (destination / "description.ext").read_text(encoding="utf-8")
            self.assertIn('onLoadName = "WMP FULL PACK PR AUDIT"', description)
            self.assertIn("respawn = 3", description)
            self.assertIn("respawnDelay = 1", description)
            self.assertIn('call compile preprocessFileLineNumbers "auditPreInit.sqf";', (destination / "init.sqf").read_text(encoding="utf-8"))
            self.assertIn('[] execVM "auditInit.sqf";', (destination / "init.sqf").read_text(encoding="utf-8"))
            self.assertIn('call compile preprocessFileLineNumbers "auditPreInitServer.sqf";', (destination / "initServer.sqf").read_text(encoding="utf-8"))
            self.assertIn('[] execVM "auditInitServer.sqf";', (destination / "initServer.sqf").read_text(encoding="utf-8"))
            self.assertIn('call compile preprocessFileLineNumbers "auditPreInitPlayerLocal.sqf";', (destination / "initPlayerLocal.sqf").read_text(encoding="utf-8"))
            self.assertIn('[] execVM "auditInitPlayerLocal.sqf";', (destination / "initPlayerLocal.sqf").read_text(encoding="utf-8"))
            for name in BUILDER.RANGE_FILES:
                self.assertTrue((destination / name).is_file(), name)
            manifest = json.loads((destination / "audit_build_manifest.json").read_text(encoding="utf-8"))
            self.assertTrue(manifest["physicalRange"])
            self.assertTrue(manifest["physicalRangePreStaged"])
            self.assertTrue(manifest["nestedPlayableLoadoutFixture"])
            self.assertGreaterEqual(manifest["staticFixtureCount"], 90)
            mission_sqm = (destination / "mission.sqm").read_text(encoding="utf-8")
            self.assertIn("class Vehicles", mission_sqm)
            self.assertIn('text="qa_control_console"', mission_sqm)
            self.assertIn('text="qa_interaction_wirecut_easy"', mission_sqm)
            self.assertIn('dataType="Layer";', mission_sqm)
            self.assertIn('name="WMP Audit Loadouts";', mission_sqm)
            self.assertIn('name="Nested Playable Roles";', mission_sqm)
            self.assertIn('name="respawn_west";', mission_sqm)
            self.assertIn('text="Audit Base Respawn";', mission_sqm)
            # Legacy v12 mission positions are X, elevation, Y rather than Eden's X, Y, Z.
            self.assertIn("position[]={0,0,2};", mission_sqm)
            self.assertEqual(5, mission_sqm.count("class Inventory"))
            self.assertEqual(1, mission_sqm.count("isPlayer=1;"))
            self.assertEqual(4, mission_sqm.count("isPlayable=1;"))
            self.assertEqual(
                mission_sqm.count('init="this allowDamage false; this enableSimulation false;";'),
                manifest["staticFixtureCount"],
            )
            fixture_names = re.findall(r'text="(qa_[^"]+)"', mission_sqm)
            self.assertEqual(len(fixture_names), len(set(fixture_names)))

    def test_static_fixture_catalogue_has_no_unsafe_collisions(self):
        fixtures = BUILDER.audit_fixtures()
        allowed_colocations = {
            frozenset(("qa_control_table", "qa_control_console")),
            frozenset(("qa_economy_table", "qa_economy_terminal")),
            frozenset(("qa_vvd_table", "qa_vvd_laptop")),
        }
        unsafe = []
        for index, left in enumerate(fixtures):
            for right in fixtures[index + 1 :]:
                pair = frozenset((left["name"], right["name"]))
                if pair in allowed_colocations:
                    continue
                distance = math.dist(left["pos"][:2], right["pos"][:2])
                if distance < 6:
                    unsafe.append((left["name"], right["name"], round(distance, 2)))
        self.assertEqual(unsafe, [])

    def test_live_physics_fixtures_are_frozen_before_placement_and_spaced(self):
        server = (
            ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeServer.sqf"
        ).read_text(encoding="utf-8")
        create_at = server.index('createVehicle [_class, _position, [], 0, "NONE"]')
        freeze_at = server.index("_object enableSimulationGlobal false;", create_at)
        place_at = server.index("_object setPosATL _position;", freeze_at)
        activate_at = server.index("_object enableSimulationGlobal _simulation;", place_at)
        self.assertLess(create_at, freeze_at)
        self.assertLess(freeze_at, place_at)
        self.assertLess(place_at, activate_at)
        self.assertNotIn('createVehicle [_class, _position, [], 0, "CAN_COLLIDE"]', server)
        self.assertIn(
            '["qa_ew_jammer", "Land_TTowerSmall_1_F", [0, -102, 0], 0, true]',
            server,
        )

        fixtures = {fixture["name"]: fixture for fixture in BUILDER.audit_fixtures()}
        carrier = fixtures["qa_recovery_carrier"]
        for name in ("qa_recovery_workshop", "qa_recovery_vehicle", "qa_sign_vehicle_recovery"):
            self.assertGreaterEqual(math.dist(carrier["pos"][:2], fixtures[name]["pos"][:2]), 25, name)

    def test_builder_rejects_reappending_audit_fixtures(self):
        source = (BUILDER.TEMPLATE / "mission.sqm").read_bytes()
        loadouts = BUILDER.nested_loadout_fixture()
        once = BUILDER.legacy_mission_with_fixtures(source, BUILDER.audit_fixtures(), loadouts)
        with self.assertRaisesRegex(ValueError, "already contains audit fixtures"):
            BUILDER.legacy_mission_with_fixtures(once, BUILDER.audit_fixtures(), loadouts)

    def test_builder_can_restage_over_read_only_windows_directories(self):
        with tempfile.TemporaryDirectory() as temp:
            destination = Path(temp) / "WMP_PR_Review_Audit.VR"
            locked = destination / "MissionScripts" / "ReadOnlyFixture"
            locked.mkdir(parents=True)
            os.chmod(locked, stat.S_IREAD)
            BUILDER.build(destination, "all", "manual")
            self.assertTrue((destination / "audit_build_manifest.json").is_file())

    def test_manual_mode_does_not_run_mutating_automation(self):
        with tempfile.TemporaryDirectory() as temp:
            destination = Path(temp) / "WMP_PR_Review_Audit.VR"
            BUILDER.build(destination, "all", "manual")
            bootstrap = (destination / "auditBootstrap.sqf").read_text(encoding="utf-8")
            self.assertIn("Waldo_QA_RunAutomation = false;", bootstrap)
            self.assertIn(
                'missionNamespace getVariable ["Waldo_QA_RunAutomation", false]',
                (destination / "auditInitServer.sqf").read_text(encoding="utf-8"),
            )
            self.assertIn(
                'missionNamespace getVariable ["Waldo_QA_RunAutomation", false]',
                (destination / "auditInitPlayerLocal.sqf").read_text(encoding="utf-8"),
            )

    def test_direct_launcher_keeps_unfocused_qa_simulation_running(self):
        launcher = (ROOT / "releaseVerificationAndDeployment" / "launch_pr_review_audit.ps1").read_text(encoding="utf-8")
        self.assertIn('"-noPause"', launcher)
        self.assertIn("if ($serverReady) { break }", launcher)

    def test_audit_artifacts_are_not_part_of_release_contract(self):
        entries = set(BUILDER.release_entries())
        self.assertNotIn("releaseVerificationAndDeployment", entries)
        self.assertNotIn("wiki", entries)
        self.assertNotIn(".qa", entries)
        self.assertNotIn("mission.sqm", entries)

    def test_pack_loadout_scraping_does_not_depend_on_live_playable_units(self):
        source = (
            ROOT / "MissionScripts" / "Logistics" / "LogiHelpers" / "missionFileLookup.sqf"
        ).read_text(encoding="utf-8")
        self.assertNotIn("playableUnits", source)
        self.assertNotIn("getUnitLoadout", source)

    def test_starter_crate_keeps_blue_identifier_and_jip_local_actions(self):
        setup = (ROOT / "MissionScripts" / "Logistics" / "Crates" / "starterCrateSetupLocal.sqf").read_text(encoding="utf-8")
        starter = (ROOT / "MissionScripts" / "Logistics" / "Crates" / "doStarterCrate.sqf").read_text(encoding="utf-8")
        self.assertIn("<t color='#79C7FF'>Starter Crate</t>", setup)
        self.assertIn("Waldo_StarterCrateIdentifierInstalled", setup)
        self.assertIn("Waldo_fnc_ZenAddLoadoutSaveAction", setup)
        self.assertIn('remoteExecCall ["Waldo_fnc_StarterCrateSetupLocal", -2', starter)

    def test_pack_scrapes_playable_units_inside_nested_eden_folders(self):
        source = (
            ROOT / "MissionScripts" / "Logistics" / "LogiHelpers" / "missionFileLookup.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn('getText (_entity >> "dataType") == "Object"', source)
        self.assertIn("_isPlayer == 1 || _isPlayable == 1", source)
        self.assertIn('private _children = _entity >> "Entities"', source)
        self.assertIn("[_x] call _visitEntity", source)
        self.assertIn('missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities"', source)

    def test_engine_spawned_playable_slots_have_the_authored_test_loadouts(self):
        source = (BUILDER.TEMPLATE / "mission.sqm").read_bytes()
        mission = BUILDER.legacy_playable_units_with_loadouts(source).decode("utf-8")
        for classname in (
            "arifle_MX_GL_Hamr_pointer_F",
            "arifle_MXC_Black_F",
            "arifle_MX_Black_F",
            "arifle_MX_SW_Black_F",
            "srifle_DMR_03_F",
        ):
            self.assertIn(f'this addWeapon ""{classname}""', mission)
        self.assertIn('vehicle="B_medic_F"', mission)
        self.assertIn('vehicle="B_soldier_AT_F"', mission)
        self.assertIn('""NVGoggles"";"; skill=0.6;', mission)

    def test_range_does_not_duplicate_pack_initializers(self):
        server = (
            ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeServer.sqf"
        ).read_text(encoding="utf-8")
        client = (
            ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeClient.sqf"
        ).read_text(encoding="utf-8")
        self.assertNotIn("[] call Waldo_fnc_MiniGamesInit", server)
        self.assertNotIn("spawn Waldo_fnc_EcoInit", client)
        self.assertIn("Waldo_QA_fnc_addAuditActionLocal", client)

    def test_extended_feature_range_has_physical_workflows(self):
        root = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"
        server = (root / "extendedFeatureStationsServer.sqf").read_text(encoding="utf-8")
        client = (root / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        for token in (
            "Waldo_fnc_PersistenceDependencyAvailable",
            "Waldo_fnc_PersistenceRegisterObject",
            "Waldo_fnc_PersistenceLoadObject",
            "Waldo_fnc_FeatureRuntimeApply",
            '"HAZARD_SET"',
            "Waldo_fnc_BreachingServerHandle",
            "Waldo_fnc_FieldResupplyRegisterHub",
            "Waldo_fnc_TacticalDisplayRegister",
            "Waldo_fnc_DynamicAACreate",
            "Waldo_fnc_GunshipRegister",
            "Waldo_fnc_RecoveryRegisterVehicle",
            "Waldo_fnc_CreateLimitedArsenal",
            '[_carrier, 12, "VIRTUAL", 2]',
            "B_UAV_02_dynamicLoadout_F",
            "(group _actor) reveal",
        ):
            self.assertIn(token, server)
        self.assertIn('["qa_tactical_console"] call _get', server)
        self.assertIn("dedicated white map board", client)
        for label in (
            "ENABLE + REGISTER QA CRATE",
            "MUTATE QA CRATE",
            "RELOAD SAVED QA CRATE",
            "RESET QA PATIENT WOUND",
            "OVERTURN VEHICLE",
            "ENABLE PID FOR THIS TESTER",
            "VERIFY UID GATE DENIES",
            "SIMULATE CONFIGURED DEMO CHARGE",
            "ASSIGN ME 2 FIELD CRATES",
            "CREATE QA DYNAMIC AA SYSTEM",
            "SPAWN ABOVE-ALTITUDE WEST UAV",
            "SPAWN QA GUNSHIP",
            "RESET RECOVERY LANE",
            "REPORT NESTED PLAYABLE LOADOUT POOL",
        ):
            self.assertIn(label, client)

    def test_new_feature_sources_avoid_known_invalid_sqf_forms(self):
        paths = (
            ROOT / "MissionScripts" / "AiScripting" / "aiApplyProfile.sqf",
            ROOT / "MissionScripts" / "Logistics" / "FieldResupply" / "fieldResupplyServerHandle.sqf",
            ROOT / "MissionScripts" / "Respawn" / "RallyPoint" / "rallyPointInit.sqf",
            ROOT / "MissionScripts" / "Persistence" / "persistenceSaveObject.sqf",
            ROOT / "MissionScripts" / "Persistence" / "persistenceLoadObject.sqf",
            ROOT / "MissionScripts" / "MissionFlowAndUi" / "Accessibility" / "accessibilityPIDInit.sqf",
            ROOT / "MissionScripts" / "MissionInit" / "VehicleActionsSetup" / "EmergencyDismount" / "emergencyDismountInit.sqf",
            ROOT / "MissionScripts" / "Logistics" / "VehicleRecovery" / "recoveryMonitorServer.sqf",
        )
        source = "\n".join(path.read_text(encoding="utf-8") for path in paths)
        for invalid in (" notIn ", "vectorDirAndUp _object", "missionNamespace addMissionEventHandler"):
            self.assertNotIn(invalid, source)
        self.assertIn('(missionNamespace getVariable ["Waldo_EmergencyDismount_Interval", 0.5]) max 0.1', source)
        self.assertIn('(missionNamespace getVariable ["Waldo_Recovery_ScanInterval", 3]) max 1', source)

    def test_accessibility_audit_uses_current_tester_without_changing_pack_default(self):
        pack = (ROOT / "MissionConfig" / "interfaceConfig.sqf").read_text(encoding="utf-8")
        preinit = (
            ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "auditPreInitPlayerLocal.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn('["76561198094931408"]', pack)
        self.assertIn("getPlayerUID player", preinit)
        self.assertIn('Waldo_AccessibilityPID_AllowedUIDs", if (_auditUid == "")', preinit)
        pid = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "Accessibility" / "accessibilityPIDInit.sqf").read_text(encoding="utf-8")
        self.assertNotIn('Waldo_AccessibilityPID_Style', pid)
        self.assertNotIn('Waldo_AccessibilityPID_FarLabel', pid)
        self.assertIn('Waldo_AccessibilityPID_TextDistanceGrowth", 0.00025', pid)
        self.assertIn('Waldo_AccessibilityPID_TextMaximumScale", 0.05', pid)
        self.assertIn('Waldo_AccessibilityPID_TextHeadOffset", 0.30', pid)
        self.assertIn('Waldo_AccessibilityPID_IconHeadOffset", 0.75', pid)
        self.assertIn('selectionPosition "head"', pid)
        self.assertIn('modelToWorldVisual _headModelPosition', pid)
        self.assertIn('"PuristaBold"', pid)
        self.assertIn('configFile >> "CfgMarkers" >> "mil_dot" >> "icon"', pid)
        self.assertIn('if (_showIcons) then', pid)
        self.assertIn('if (_showNames && {_distance <= _nameRange}) then', pid)
        self.assertEqual(2, pid.count('drawIcon3D [_textAnchorIcon'))
        self.assertEqual(2, pid.count('_textAnchorIcon, _draw'))
        self.assertIn('_drawOutline, _textPosition', pid)
        self.assertIn('_drawColour, _textPosition', pid)
        self.assertIn('_drawColour, _iconPosition', pid)
        self.assertNotIn('_textAnchorIcon, _drawColour, _position, 0, 0, 0, _text, 2,', pid)
        accessibility_station = (
            ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "extendedFeatureStationsClient.sqf"
        ).read_text(encoding="utf-8")
        self.assertNotIn("PID STYLE:", accessibility_station)

    def test_selected_features_are_not_registered_as_zen_modules(self):
        source = (ROOT / "MissionScripts" / "ZenModules" / "Zen_initModules.sqf").read_text(encoding="utf-8")
        for removed in (
            "Treatment Feedback - Control",
            "Tree Felling - Control",
            "Accessibility PID - Control",
            "Breaching - Configure Class",
        ):
            self.assertNotIn(removed, source)
        self.assertIn('Waldo_ZenModuleCount", 42', source)

    def test_field_resupply_zen_can_create_a_hub_crate_authoritatively(self):
        zen = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeZen.sqf").read_text(encoding="utf-8")
        apply = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeApply.sqf").read_text(encoding="utf-8")
        self.assertIn('_stock = if (round _stockChoice == 0) then {-1} else {round _stockChoice}', zen)
        self.assertIn('["FIELD_RESUPPLY_HUB", [_target, _side, _stock, _modulePos]]', zen)
        self.assertIn('if (isNull _hub && {count _modulePos >= 2})', apply)
        self.assertIn('createVehicle [_crateClass, _modulePos, [], 0, "NONE"]', apply)
        self.assertIn('[_hub, _requestOwner, false, false] call Waldo_fnc_ZenAssignObjectOwnerServer', apply)

    def test_field_resupply_grants_are_authoritative_targeted_and_intro_safe(self):
        root = ROOT / "MissionScripts" / "Logistics" / "FieldResupply"
        grant = (root / "fieldResupplyGrantCrates.sqf").read_text(encoding="utf-8")
        notify = (root / "fieldResupplyNotifyGrantLocal.sqf").read_text(encoding="utf-8")
        info_text = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "infoText.sqf").read_text(encoding="utf-8")
        zen = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeZen.sqf").read_text(encoding="utf-8")
        apply = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeApply.sqf").read_text(encoding="utf-8")
        self.assertIn("if !(isServer) exitWith", grant)
        self.assertIn("getAssignedCuratorLogic", grant)
        self.assertIn('setVariable ["Waldo_FieldResupply_Crates", _current, true]', grant)
        self.assertIn('remoteExecCall ["Waldo_fnc_FieldResupplyNotifyGrantLocal", owner _unit]', grant)
        self.assertIn('missionNamespace getVariable ["Waldo_InfoText_Complete", false]', notify)
        self.assertIn('!(missionNamespace getVariable ["Waldo_InfoText_Active", false])', notify)
        self.assertIn("diag_tickTime - _queuedAt >= 60", notify)
        self.assertIn('setVariable ["Waldo_InfoText_Active", true]', info_text)
        self.assertIn('setVariable ["Waldo_InfoText_Complete", true]', info_text)
        self.assertIn('case "FIELD_RESUPPLY_GRANT"', zen)
        self.assertIn('case "FIELD_RESUPPLY_GRANT"', apply)

    def test_recovery_carrier_zen_exposes_engine_independent_virtual_cargo(self):
        zen = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeZen.sqf").read_text(encoding="utf-8")
        apply = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeApply.sqf").read_text(encoding="utf-8")
        audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "extendedFeatureStationsServer.sqf").read_text(encoding="utf-8")
        self.assertIn('[["AUTO", "VIRTUAL", "PHYSICAL"]', zen)
        self.assertIn('missionNamespace getVariable ["Waldo_Recovery_PackageClasses"', zen)
        self.assertIn('["Package capacity"', zen)
        self.assertIn('["_mode", "AUTO"]', apply)
        self.assertIn('["_capacity", 1]', apply)
        self.assertIn('"B_MRAP_01_F"', audit)
        self.assertIn('[_carrier, 12, "VIRTUAL", 2]', audit)

    def test_runtime_setting_bundle_is_not_unpacked_as_one_pair(self):
        source = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeApply.sqf").read_text(encoding="utf-8")
        self.assertIn("private _updates = _this;", source)
        self.assertNotIn('private _publishAll = {\n    params ["_updates"]', source)

    def test_accessibility_toggle_is_an_ace_self_interaction(self):
        accessibility = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "Accessibility" / "accessibilitySelfInteractionInit.sqf").read_text(encoding="utf-8")
        pid = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "Accessibility" / "accessibilityPIDInit.sqf").read_text(encoding="utf-8")
        self.assertIn('"Waldo_Accessibility_Root"', accessibility)
        self.assertIn('[] call Waldo_fnc_SetupUiCleanupAction;', accessibility)
        self.assertIn('["ACE_SelfActions", "Waldo_UI_SelfRoot"]', accessibility)
        self.assertIn(
            '["ACE_SelfActions", "Waldo_UI_SelfRoot", "Waldo_Accessibility_Root"]',
            accessibility,
        )
        self.assertIn('"Waldo_Accessibility_ColourVision"', accessibility)
        self.assertIn('"Waldo_AccessibilityPID_Toggle"', accessibility)
        self.assertIn("Waldo_fnc_UiColourVisionOpenLocal", accessibility)
        self.assertIn("Accessibility: Colour Vision", accessibility)
        self.assertNotIn("Accessibility: Toggle Friendly Identification", accessibility)
        self.assertIn("Waldo_fnc_AccessibilitySelfInteractionInit", pid)
        self.assertNotIn("ace_interact_menu_fnc_createAction", pid)

    def test_colour_vision_profiles_are_personal_and_theme_aware(self):
        profile = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "Accessibility" / "uiColourVisionProfile.sqf").read_text(encoding="utf-8")
        apply = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "Accessibility" / "uiColourVisionApplyLocal.sqf").read_text(encoding="utf-8")
        theme = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "uiTheme.sqf").read_text(encoding="utf-8")
        audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        qa_bootstrap = (ROOT / "releaseVerificationAndDeployment" / "interactionEquipmentQA" / "InteractionEquipmentQA.VR" / "scriptedBootstrap.sqf").read_text(encoding="utf-8")
        for profile_id in ("STANDARD", "RED_GREEN", "PROTAN", "TRITAN", "HIGH_CONTRAST"):
            self.assertIn(f'"{profile_id}"', profile)
        self.assertIn('profileNamespace setVariable ["Waldo_UI_ColourVisionProfile"', apply)
        self.assertIn("saveProfileNamespace", apply)
        self.assertNotIn("publicVariable", apply)
        self.assertNotIn("remoteExec", apply)
        self.assertIn("Waldo_fnc_UiColourVisionProfile", theme)
        self.assertIn("OPEN ACCESSIBILITY COLOUR-VISION UI", audit)
        self.assertLess(qa_bootstrap.index('"Waldo_fnc_UiColourVisionProfile"'), qa_bootstrap.index('"Waldo_fnc_UiTheme"'))

    def test_persistence_gate_executes_a_native_version_probe(self):
        source = (ROOT / "MissionScripts" / "Persistence" / "persistenceDependencyAvailable.sqf").read_text(encoding="utf-8")
        self.assertIn('private _version = "getVersion" call _probeDb', source)
        self.assertIn('_versionText find "inidbi" >= 0', source)
        self.assertIn("private _dllHasDigits", source)
        self.assertIn("&& {_dllHasDigits}", source)
        launcher = (ROOT / "releaseVerificationAndDeployment" / "launch_pr_review_audit.ps1").read_text(encoding="utf-8")
        self.assertIn("[switch]$ExcludePersistenceMod", launcher)
        self.assertIn("if ($ExcludePersistenceMod)", launcher)

    def test_notification_stack_reflows_surviving_cards(self):
        source = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "reflowUiPanels.sqf").read_text(encoding="utf-8")
        audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeClient.sqf").read_text(encoding="utf-8")
        extended = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        server = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "extendedFeatureStationsServer.sqf").read_text(encoding="utf-8")
        self.assertIn("ctrlCommit _duration", source)
        for duration in ('"INFO", 4, "TOP_RIGHT", "QA_STACK_1"', '"SUCCESS", 8, "TOP_RIGHT", "QA_STACK_2"', '"WARNING", 12, "TOP_RIGHT", "QA_STACK_3"'):
            self.assertIn(duration, audit)
        self.assertIn("RUN LIVE NOTIFICATION STREAMS", extended)
        self.assertIn("SHOW ALL UI POSITIONS", audit)
        for placement in ("TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"):
            self.assertIn(f'["{placement}",', audit)
        self.assertIn("Waldo_fnc_TreatmentFeedbackShowLocal", extended)
        for channel in ("FIELD_RESUPPLY", "DYNAMIC_AA", "TREE_FELLING", "ACCESSIBILITY_PID"):
            self.assertIn(f'"{channel}"', extended)
        self.assertIn("Waldo_fnc_RallyPointNotifyLocal", extended)
        self.assertIn("Waldo_fnc_RecoveryNotifyLocal", extended)
        self.assertIn('format ["QA_%1", toUpperANSI _title]', server)
        self.assertNotIn('"QA_FEATURE_STATION", 8', server)

        player_init = (ROOT / "MissionConfig" / "interfaceConfig.sqf").read_text(encoding="utf-8")
        for channel in ("TREATMENT_FEEDBACK", "DYNAMIC_AA", "FIELD_RESUPPLY", "RALLY_POINT"):
            self.assertIn(f'["{channel}",', player_init)

    def test_rally_audit_has_a_real_selectable_respawn_path(self):
        client = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        self.assertIn("TEST RALLY RESPAWN SELECTION", client)
        self.assertIn('getVariable ["Waldo_Rally_Active", false]', client)
        self.assertIn("player setDamage 1", client)
        launcher = (ROOT / "releaseVerificationAndDeployment" / "launch_pr_review_audit.ps1").read_text(encoding="utf-8")
        self.assertIn('"MPMissions\\WMP_PR_Review_Audit.VR"', launcher)
        self.assertIn('template = "WMP_PR_Review_Audit.VR"', launcher)
        self.assertIn('"-autoInit"', launcher)
        self.assertIn('"-connect=localhost"', launcher)
        self.assertIn('"-password=wmpqa"', launcher)
        self.assertIn('".qa\\pr-review-audit\\runtime-$runStamp"', launcher)
        self.assertIn("$serverMods += $persistenceMod.FullName", launcher)
        self.assertIn("$clientModArgument", launcher)
        self.assertIn("arma3server_x64.exe", launcher)
        self.assertNotIn("playMission['','WMP_PR_Review_Audit.VR'", launcher)

    def test_audit_zeus_follows_the_replacement_player_unit(self):
        server = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeServer.sqf").read_text(encoding="utf-8")
        client = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeClient.sqf").read_text(encoding="utf-8")
        self.assertIn('addMissionEventHandler ["EntityRespawned"', server)
        self.assertIn("Waldo_QA_CuratorAssignedUnit", server)
        self.assertIn("[_unit] call Waldo_QA_fnc_assignCuratorServer", server)
        self.assertIn("owner _x > 2", server)
        self.assertIn('getAssignedCuratorUnit _curator', server)
        self.assertIn('[player, false] remoteExecCall ["Waldo_QA_fnc_assignCuratorServer", 2]', client)
        self.assertIn("Waldo_QA_CuratorRequestId", server)
        self.assertIn("WMP FULL AUDIT ZEUS SERVER READY", server)
        self.assertIn("Waldo_QA_fnc_curatorAssignmentConfirmedClient", client)
        self.assertIn("getAssignedCuratorLogic player isEqualTo _curator", client)
        self.assertIn("ASSIGN / OPEN ZEUS", client)
        self.assertIn("openCuratorInterface", client)

        generator = (ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py").read_text(encoding="utf-8")
        self.assertNotIn('property="ModuleCurator_F_Owner"', generator)
        self.assertIn('property="ModuleCurator_F_Addons"', generator)

    def test_respawn_overlay_is_location_only(self):
        source = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "respawnText.sqf").read_text(encoding="utf-8")
        for token in ("_time", "_date", "_localePos"):
            self.assertIn(token, source)
        for unwanted in ("_RnkAndName", "_groupInfo", "rank player", "name player"):
            self.assertNotIn(unwanted, source)

    def test_dynamic_aa_target_is_crewed_airborne_and_retained_in_the_zone(self):
        source = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "extendedFeatureStationsServer.sqf").read_text(encoding="utf-8")
        for token in ('["mobileClass", "O_APC_Tracked_02_AA_F"]', '["mobilePositions", [[175, -110, 0]]]', "west createVehicleCrew _target", "_target engineOn true", "setVelocityModelSpace", 'setWaypointType "LOITER"', "setWaypointLoiterRadius", "WMP DYNAMIC AA QA TARGET"):
            self.assertIn(token, source)

    def test_field_resupply_has_logical_cargo_grouped_ace_controls_and_blue_information(self):
        root = ROOT / "MissionScripts" / "Logistics" / "FieldResupply"
        server = (root / "fieldResupplyServerHandle.sqf").read_text(encoding="utf-8")
        carrier = (root / "fieldResupplyInit.sqf").read_text(encoding="utf-8")
        crate = (root / "fieldResupplySetupCrateLocal.sqf").read_text(encoding="utf-8")
        hub = (root / "fieldResupplySetupHubLocal.sqf").read_text(encoding="utf-8")
        self.assertNotIn("addMagazineCargoGlobal", server)
        self.assertNotIn("getMagazineCargo _crate", server)
        self.assertIn("clearMagazineCargoGlobal _crate", server)
        self.assertIn("magazinesAmmoFull _sourceUnit", server)
        self.assertIn("Waldo_FieldResupply_UseCapacityBasedAmounts", server)
        self.assertIn("Waldo_FieldResupply_InitialCharges", server)
        self.assertIn("ACE_SelfActions", carrier)
        self.assertIn("Waldo_FieldResupply_InspectCarrier", carrier)
        self.assertIn("Waldo_FieldResupply_Deploy", carrier)
        self.assertIn('"Waldo_FieldResupply_Category"', carrier)
        self.assertIn('["ACE_SelfActions", "Waldo_FieldResupply_Category"]', carrier)
        self.assertIn('["ACE_MainActions", "Waldo_FieldResupply_Category"]', crate)
        self.assertIn('["ACE_MainActions", "Waldo_FieldResupply_Category"]', hub)
        self.assertIn("<t color='#79C7FF'>Check Resupply Crates</t>", carrier)
        self.assertIn("<t color='#79C7FF'>Field Resupply Crate</t>", crate)
        self.assertIn('backpack _caller != ""', carrier)
        self.assertIn("vehicle _caller isEqualTo _caller", carrier)
        for source in (carrier, crate, hub):
            self.assertIn("ace_interact_menu_fnc_createAction", source)
            self.assertIn("ace_interact_menu_fnc_addActionToObject", source)
            self.assertIn("addAction", source)
        starter = (ROOT / "MissionScripts" / "Logistics" / "Crates" / "starterCrateSetupLocal.sqf").read_text(encoding="utf-8")
        gunship = (ROOT / "MissionScripts" / "CombatSystems" / "AirborneGunship" / "gunshipSetupLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("<t color='#79C7FF'>Starter Crate</t>", starter)
        self.assertIn("<t color='#79C7FF'>%1: Status (%2)</t>", gunship)

    def test_gunship_service_action_uses_a_known_task_icon(self):
        source = (ROOT / "MissionScripts" / "CombatSystems" / "AirborneGunship" / "gunshipSetupLocal.sqf").read_text(encoding="utf-8")
        self.assertIn(r"\A3\ui_f\data\igui\cfg\simpletasks\types\repair_ca.paa", source)
        self.assertNotIn("holdAction_refuel_ca.paa", source)
        self.assertNotIn("holdactions\\refuel_ca.paa", source)

    def test_treatment_feedback_cannot_recursively_forward_on_listen_server(self):
        source = (ROOT / "MissionScripts" / "MedicalSystems" / "TreatmentFeedback" / "treatmentFeedbackNotify.sqf").read_text(encoding="utf-8")
        local_show = (ROOT / "MissionScripts" / "MedicalSystems" / "TreatmentFeedback" / "treatmentFeedbackShowLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("remoteExecutedOwner > 0", source)
        self.assertIn("!local _medic", source)
        self.assertIn("isPlayer _patient", source)
        self.assertNotIn('remoteExecCall ["Waldo_fnc_TreatmentFeedbackNotify"', source)
        self.assertEqual(1, source.count('remoteExecCall ["Waldo_fnc_TreatmentFeedbackShowLocal"'))
        self.assertNotIn("remoteExec", local_show)
        self.assertIn('"BOTTOM_CENTER"', local_show)
        self.assertIn('"REPLACE"', local_show)
        self.assertIn("Waldo_TreatmentFeedback_Duration", local_show)
        audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        self.assertIn("PREVIEW GIVER + RECEIVER FEEDBACK", audit)
        self.assertIn("ENABLE ACTUAL GIVER FEEDBACK", audit)
        self.assertIn("INJURE ME FOR RECEIVER / SELF TEST", audit)

    def test_hazard_audit_uses_live_runtime_start_and_exposes_state(self):
        audit = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"
        server = (audit / "extendedFeatureStationsServer.sqf").read_text(encoding="utf-8")
        client = (audit / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        self.assertIn('["HAZARD_SET", ["qa_hazard", _hazardEmitter, _hazardProfile]] call Waldo_fnc_FeatureRuntimeApply', server)
        self.assertNotIn('remoteExecCall ["Waldo_fnc_HazardRegisterZone", -2, "Waldo_QA_HazardZone"]', server)
        self.assertIn("SHOW HAZARD RUNTIME STATUS", client)
        self.assertIn("Waldo_Hazard_ClientStarted", client)
        self.assertIn("[] call Waldo_fnc_HazardInit", client)
        self.assertIn('["intensityMode", "CONSTANT"]', server)
        self.assertIn('["damageThresholds", [[4, 0.1], [10, 0.2], [18, 0.35]]]', server)
        self.assertIn('["fatalExposure", 24]', server)
        self.assertIn('player addHeadgear "H_PilotHelmetFighter_B"', client)
        tick = (ROOT / "MissionScripts" / "EnvironmentalSystems" / "HazardousEnvironments" / "hazardTick.sqf").read_text(encoding="utf-8")
        self.assertIn("Waldo_Hazard_LocalDamageStages", tick)
        self.assertIn("notifyDamageStages", tick)

    def test_dismount_fixture_has_live_simulation_and_vehicle_bound_controls(self):
        audit = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"
        server = (audit / "extendedFeatureStationsServer.sqf").read_text(encoding="utf-8")
        client = (audit / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        init_player = (ROOT / "initPlayerLocal.sqf").read_text(encoding="utf-8")
        upright = (ROOT / "MissionScripts" / "MissionInit" / "VehicleActionsSetup" / "vehicleUpright.sqf").read_text(encoding="utf-8")
        setup = (ROOT / "MissionScripts" / "MissionInit" / "VehicleActionsSetup" / "setupVehicleUprightLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("_dismountVehicle enableSimulationGlobal true", server)
        self.assertIn('private _dismount = missionNamespace getVariable ["Waldo_QA_DismountVehicle", objNull]', client)
        self.assertNotIn('private _dismount = "qa_sign_emergency_dismount" call _get', client)
        self.assertNotIn('player addAction [\n    "Flip Vehicle"', init_player)
        self.assertIn("boundingBoxReal", upright)
        self.assertIn("surfaceNormal", upright)
        self.assertIn("_vehicle addAction", setup)
        self.assertIn('remoteExecCall ["Waldo_fnc_VehicleUpright", 2]', setup)

    def test_tactical_display_fixture_is_a_map_board(self):
        generator = (ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py").read_text(encoding="utf-8")
        client = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        setup = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "TacticalDisplay" / "tacticalDisplaySetupLocal.sqf").read_text(encoding="utf-8")
        self.assertIn('fixture("qa_tactical_console", "Land_MapBoard_F"', generator)
        self.assertIn("dedicated white map board", client)
        self.assertIn("[player, 'VIEW', _target] checkVisibility", setup)
        self.assertNotIn("[player, 'VIEW'] checkVisibility", setup)

    def test_scale_zen_exposes_explicit_decorative_conversion(self):
        source = (ROOT / "MissionScripts" / "MissionMakerResourceScripts" / "ObjectTransforms" / "objectScaleZen.sqf").read_text(encoding="utf-8")
        implementation = (ROOT / "MissionScripts" / "MissionMakerResourceScripts" / "ObjectTransforms" / "objectScale.sqf").read_text(encoding="utf-8")
        self.assertIn('"Convert decorative object"', source)
        self.assertIn('[_target, _scale, _asSimple] remoteExecCall ["Waldo_fnc_ObjectScale", 2]', source)
        self.assertIn("BIS_fnc_replaceWithSimpleObject", implementation)
        self.assertIn("getObjectScale _scaledObject", implementation)
        self.assertIn("addCuratorEditableObjects", implementation)

    def test_diagnostics_accept_nested_loadouts_and_real_interaction_ids(self):
        diagnostics = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "runDiagnostics.sqf").read_text(encoding="utf-8")
        interactions = (ROOT / "MissionScripts" / "InteractionsMinigames" / "Integration" / "miniGameInteractionGetDiagnostics.sqf").read_text(encoding="utf-8")
        self.assertIn("_configuredLoadoutSides", diagnostics)
        self.assertIn("mission-scraped item(s)", diagnostics)
        self.assertIn('["commandinput", "Waldo_fnc_MiniGameCommandInput"]', interactions)
        self.assertNotIn('["command", "Waldo_fnc_MiniGameCommandInput"]', interactions)

    def test_tree_felling_default_replacement_exists_in_base_game(self):
        root_init = (ROOT / "MissionConfig" / "environmentConfig.sqf").read_text(encoding="utf-8")
        process = (ROOT / "MissionScripts" / "EnvironmentalSystems" / "TreeFelling" / "treeFellingProcess.sqf").read_text(encoding="utf-8")
        self.assertIn('["Land_WoodenLog_F"]', root_init)
        self.assertIn('["Land_WoodenLog_F"]', process)
        self.assertNotIn("Land_TreeTrunk_01_F", root_init)


    def test_corrected_feature_workflows_have_runtime_controls_and_bounds(self):
        scripts = ROOT / "MissionScripts"
        audit = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"

        arsenal = (scripts / "Logistics" / "Crates" / "createLimitedAceArsenal.sqf").read_text(encoding="utf-8")
        self.assertIn('_aceArsenalPool select {!(_x isEqualTo ["EMPTY"])}', arsenal)
        self.assertNotIn("deleteAt _x", arsenal)

        jammer = (scripts / "MissionInit" / "Jamming" / "jammerScan.sqf").read_text(encoding="utf-8")
        self.assertIn("_d > _coverage", jammer)
        self.assertIn("(_radius max 0) + (_falloff max 0)", jammer)
        self.assertIn("_receiverSide in _sides", jammer)
        self.assertIn("terrainIntersectASL", jammer)
        self.assertIn("(_now % _period) >= _onTime", jammer)
        self.assertIn("Bearing between %1 and %2 deg", jammer)
        for vague_band in ("VERY CLOSE", "NEARBY", "DISTANT", "VERY DISTANT"):
            self.assertIn(vague_band, jammer)
        self.assertNotIn("Signal strength", jammer)

        rally = (scripts / "Respawn" / "RallyPoint" / "rallyPointSetupLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("ACE_SelfActions", rally)
        self.assertIn("ace_common_fnc_progressBar", rally)
        self.assertIn("BIS_fnc_holdActionAdd", rally)

        gunship = (scripts / "CombatSystems" / "AirborneGunship" / "gunshipSetupLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("_x select 2", gunship)
        self.assertIn("Waldo_Gunship_AceActions", gunship)
        self.assertIn("simpletasks\\types\\repair_ca.paa", gunship)
        self.assertIn("serviceCompleteAt", gunship)
        self.assertIn("Tasking and weapon control are locked", gunship)
        self.assertNotIn("\\holdactions\\refuel_ca.paa", gunship)
        self.assertIn("[(_args select 0)] call Waldo_fnc_GunshipSelectOrbitLocal", gunship)
        self.assertIn("_newAceActions append _paths", gunship)

        tactical = (scripts / "MissionFlowAndUi" / "TacticalDisplay" / "tacticalDisplaySetupLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("[player, 'VIEW', _target] checkVisibility [eyePos player, aimPos _target]", tactical)

    def test_dynamic_paradrop_is_authoritative_configurable_and_side_independent(self):
        scripts = ROOT / "MissionScripts"
        audit = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"
        root = ROOT / "MissionScripts" / "Paradrop"
        create = (root / "paradropCreateDropZone.sqf").read_text(encoding="utf-8")
        remove = (root / "paradropRemoveDropZone.sqf").read_text(encoding="utf-8")
        zen = (root / "paradropDropZoneZen.sqf").read_text(encoding="utf-8")
        embark = (root / "paradropEmbark.sqf").read_text(encoding="utf-8")
        configure = (root / "paradropConfigureAircraftLocal.sqf").read_text(encoding="utf-8")
        backpack = (root / "paraBackpack.sqf").read_text(encoding="utf-8")
        restore_backpack = (root / "paradropRestoreBackpackLocal.sqf").read_text(encoding="utf-8")
        registration = (ROOT / "MissionScripts" / "ZenModules" / "Zen_initModules.sqf").read_text(encoding="utf-8")
        self.assertIn("getAssignedCuratorLogic", create + remove)
        self.assertIn('setBehaviourStrong "CARELESS"', create)
        self.assertIn('setCombatMode "BLUE"', create)
        self.assertIn("flyInHeight [_altitude, true]", create)
        self.assertIn("limitSpeed _maximumSpeed", create)
        self.assertIn("forceSpeed (_maximumSpeed / 3.6)", create)
        self.assertIn("addWaypoint [AGLToASL _position, -1]", create)
        self.assertIn('[0, 60, 0, 0]', zen)
        self.assertIn('[0.5, 10, 2, 1]', zen)
        self.assertIn("Operational side", zen)
        self.assertIn("does not filter the airframe", zen)
        self.assertIn("Optional generated AI jumpers", zen)
        self.assertIn("Loop and repeat", zen)
        self.assertIn("Static-line parachute", zen)
        self.assertIn("HALO parachute backpack", zen)
        self.assertIn("Who to embark", zen)
        self.assertIn('[["PLAYER", "GROUP"]', zen)
        self.assertIn('[_id, "SELECTION", _units', zen)
        self.assertIn('[_id, "POLE", []', zen)
        self.assertNotIn('"Boarding method"', zen)
        self.assertIn('"FlagPole_F"', zen)
        self.assertIn('remoteExec ["Waldo_fnc_ParadropConfigureAircraftLocal", 0, _aircraft]', create)
        self.assertIn('call Waldo_fnc_AddStaticJump', configure)
        self.assertIn('call Waldo_fnc_AddHaloJump', configure)
        for token in ("STANDBY", "GREEN", "RED", 'setMarkerShape "RECTANGLE"'):
            self.assertIn(token, create)
        self.assertIn("Waldo_Paradrop_PublicDropZones", create + remove)
        self.assertIn("Waldo_Paradrop_BoardingOperation", embark)
        self.assertIn('remoteExecCall ["Waldo_fnc_ParadropEmbarkLocal", owner _x]', embark)
        self.assertIn("Paradrop - Create Drop Zone", registration)
        self.assertIn("Paradrop - Embark Players", registration)
        self.assertIn("Paradrop - Remove Operation", registration)
        self.assertIn('isKindOf "FlagCarrierCore"', embark)
        self.assertIn("Flag_blue_CO.paa", embark)
        self.assertIn('getVariable ["Waldo_Paradrop_SavedBackpackLoadout", []]', backpack)
        self.assertIn('getUnitLoadout _player', backpack)
        self.assertNotIn("backpackItems _player", backpack)
        self.assertIn("isTouchingGround _unit", backpack)
        self.assertIn("surfaceIsWater", backpack)
        self.assertIn("call Waldo_fnc_ParadropRestoreBackpackLocal", backpack)
        self.assertIn("getUnitLoadout _unit", restore_backpack)
        self.assertIn("_loadout set [5", restore_backpack)
        self.assertIn("setUnitLoadout _loadout", restore_backpack)

        dynamic_aa = (scripts / "CombatSystems" / "DynamicAA" / "dynamicAACreate.sqf").read_text(encoding="utf-8")
        dynamic_aa_detector = (scripts / "CombatSystems" / "DynamicAA" / "dynamicAADetectorLoop.sqf").read_text(encoding="utf-8")
        self.assertIn('getOrDefault ["staticSiteSpacing", 30]', dynamic_aa)
        self.assertIn("getPos [_staticSiteSpacing", dynamic_aa)
        self.assertIn('getOrDefault ["maximumOperationalRadarDamage", 0.8]', dynamic_aa_detector)
        self.assertIn("damage _radar >= _maximumRadarDamage", dynamic_aa_detector)
        self.assertIn("radarOperationalCondition", dynamic_aa_detector)

        recovery = (scripts / "Logistics" / "VehicleRecovery" / "recoveryRegisterWorkshop.sqf").read_text(encoding="utf-8")
        restore = (scripts / "Logistics" / "VehicleRecovery" / "recoveryRestoreServer.sqf").read_text(encoding="utf-8")
        self.assertIn('setMarkerShape "ELLIPSE"', recovery)
        self.assertIn('setMarkerType "mil_dot"', recovery)
        self.assertIn("Waldo_Recovery_CreateWorkshopMarkers", recovery)
        self.assertIn("allPlayers select", restore)
        self.assertIn("_x distance2D _workshop <= _notificationRadius", restore)
        recovery_zen = (scripts / "ZenModules" / "RuntimeControl" / "featureRuntimeZen.sqf").read_text(encoding="utf-8")
        self.assertIn("Completion notice radius", recovery_zen)
        self.assertIn("Create map markers", recovery_zen)
        self.assertIn("_notificationRadius, _createMarkers", recovery_zen)

        server = (audit / "extendedFeatureStationsServer.sqf").read_text(encoding="utf-8")
        client = (audit / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        controls = (audit / "featureRangeClient.sqf").read_text(encoding="utf-8")
        expected_primaries = (
            "arifle_MX_GL_Hamr_pointer_F", "arifle_MXC_Black_F", "arifle_MX_Black_F",
            "arifle_MX_SW_Black_F", "srifle_DMR_03_F",
        )
        for primary in expected_primaries:
            self.assertIn(primary, server)
        self.assertIn("WMP NESTED LOADOUT PRIMARY AUDIT", server)
        self.assertIn('missionNamespace getVariable ["Waldo_QA_DismountVehicle", objNull]', client)
        self.assertNotIn('private _dismount = "qa_sign_emergency_dismount" call _get', client)
        self.assertIn("REFRESH MY GUNSHIP CONTROLS", client)
        self.assertIn("_scale, true] call Waldo_fnc_ObjectScale", server)
        self.assertIn('missionNamespace setVariable [_name, _scaled, true]', server)
        self.assertIn("Waldo_QA_ControlConsole", controls)
        self.assertIn("Waldo_QA_CoreConsole", controls)
        self.assertIn("_forceVanilla", controls)

    def test_improved_helicopter_landing_is_ai_only_event_driven_and_locality_safe(self):
        root = ROOT / "MissionScripts" / "AiScripting"
        init = (root / "improvedHelicopterLandingInit.sqf").read_text(encoding="utf-8")
        tracker = (root / "improvedHelicopterLandingTrackLocal.sqf").read_text(encoding="utf-8")
        controller = (root / "improvedHelicopterLandingExecuteLocal.sqf").read_text(encoding="utf-8")
        anchor = (root / "improvedHelicopterLandingAnchorLocal.sqf").read_text(encoding="utf-8")
        restore = (root / "improvedHelicopterLandingRestoreLocal.sqf").read_text(encoding="utf-8")
        self.assertIn('["Helicopter", "init"', init)
        self.assertIn('addEventHandler ["Local"', init)
        self.assertIn('getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]', init)
        self.assertNotIn("allMissionObjects", init + tracker)
        self.assertNotIn("ImprovedHelicopterLandingMonitor", init + tracker)
        self.assertIn("!isPlayer _pilot", tracker)
        self.assertIn("isNull (remoteControlled _pilot)", tracker)
        self.assertIn('["LAND", "UNLOAD", "TR UNLOAD", "GETOUT"]', tracker)
        self.assertIn("max 50", tracker + controller)
        self.assertIn("nearestTerrainObjects", controller)
        self.assertIn("surfaceNormal", controller)
        self.assertIn("setVectorDirAndUp", controller)
        self.assertIn("MaximumClimbRate", controller)
        self.assertIn("MaximumGoArounds", controller)
        self.assertIn('"FinalCommitDistance", 75', controller)
        self.assertIn("!_committedToTouchdown && {currentWaypoint _group != _expectedWaypoint}", controller)
        self.assertIn("_liveScript != _expectedScript", controller)
        self.assertIn("distance2D _targetPosition > 0.5", controller)
        self.assertIn("(_targetDeltaX / _targetDeltaMagnitude) * _desiredSpeed", controller)
        self.assertIn("private _desiredVelocityZ = if (_goAround) then {3}", controller)
        self.assertIn("_atlAltitude <= 1", controller)
        self.assertIn("_horizontalVelocity <= 2", controller)
        self.assertIn('"Waldo_ImprovedHelicopterLanding_LastResult"', controller)
        self.assertIn('disableAI "PATH"', controller)
        self.assertIn('setVariable ["Waldo_ImprovedHelicopterLanding_Active", true, true]', controller)
        self.assertIn("spawn Waldo_fnc_ImprovedHelicopterLandingAnchorLocal", controller)
        self.assertIn('disableAI "MOVE"', anchor)
        self.assertIn('flyInHeight 0', anchor)
        self.assertIn('"LANDING_WAYPOINT_DELETED"', anchor)
        self.assertIn('"LANDING_WAYPOINT_EDITED"', anchor)
        self.assertIn('"ONWARD_WAYPOINT"', anchor)
        self.assertIn('"TouchdownHoldSeconds", 8', anchor)
        self.assertIn('enableAI "PATH"', restore)
        self.assertIn('setVariable ["Waldo_ImprovedHelicopterLanding_Active", false, true]', restore)
        zen_modules = (ROOT / "MissionScripts" / "ZenModules" / "Zen_initModules.sqf").read_text(encoding="utf-8")
        self.assertNotIn("AI - Helicopter Landing Control", zen_modules)

    def test_full_pack_audit_exercises_real_ai_landing_and_live_ui_themes(self):
        audit = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"
        generator = (ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py").read_text(encoding="utf-8")
        server = (audit / "extendedFeatureStationsServer.sqf").read_text(encoding="utf-8")
        client = (audit / "extendedFeatureStationsClient.sqf").read_text(encoding="utf-8")
        self.assertIn('("ai-helicopter-landing", "AI HELICOPTER LANDING"', generator)
        self.assertIn('("ui-theme-qa", "UI THEME QA"', generator)
        self.assertIn('fixture("qa_ai_helicopter_landing_pad", "Land_HelipadCircle_F"', generator)
        self.assertIn('createVehicleCrew _helicopter', server)
        self.assertIn('private _spawnAltitude = [30, 220] select _highApproach', server)
        self.assertIn('private _spawnMode = "FLY"', server)
        self.assertIn('private _helicopter = createVehicle ["B_Heli_Light_01_F", [325, -30, _spawnAltitude]', server)
        self.assertIn('_helicopter enableSimulationGlobal true', server)
        self.assertIn('{_x enableSimulationGlobal true} forEach crew _helicopter', server)
        self.assertIn('_group setCurrentWaypoint _waypoint', server)
        self.assertIn('_waypoint setWaypointType "SCRIPTED"', server)
        self.assertIn('_waypoint setWaypointScript "A3\\functions_f\\waypoints\\fn_wpLand.sqf"', server)
        self.assertIn('_waypoint setWaypointSpeed "NORMAL"', server)
        self.assertNotIn("call Waldo_fnc_ImprovedHelicopterLandingExecuteLocal", server)
        server_audit = (audit / "runServerAudit.sqf").read_text(encoding="utf-8")
        staged_server_audit = (
            ROOT
            / "releaseVerificationAndDeployment"
            / "fullArmaAudit"
            / "FullArmaAudit.VR"
            / "runServerAudit.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn('"core/ai-helicopter/land-touchdown"', server_audit)
        self.assertIn('Waldo_ImprovedHelicopterLanding_LastResult', server_audit)
        self.assertIn('"core/ai-helicopter/land-touchdown"', staged_server_audit)
        self.assertIn('fn_wpland.sqf', staged_server_audit)
        self.assertIn("START NORMAL AI LANDING", client)
        self.assertIn("START HIGH APPROACH / GO-AROUND", client)
        for theme in ('["DEFAULT", "DEFAULT"]', '["WW2", "WW2"]', '["VIETNAM", "VIETNAM"]', '["SCIFI", "SCI-FI"]'):
            self.assertIn(theme, client)

    def test_recovery_restore_requires_a_complete_clear_footprint(self):
        root = ROOT / "MissionScripts" / "Logistics" / "VehicleRecovery"
        resolver = (root / "recoveryResolveRestorePosition.sqf").read_text(encoding="utf-8")
        restore = (root / "recoveryRestoreServer.sqf").read_text(encoding="utf-8")
        self.assertIn("boundingBoxReal _workshop", resolver)
        self.assertIn("_workshopRadius + _vehicleRadius + _clearance", resolver)
        self.assertIn("findEmptyPosition", resolver)
        self.assertIn("nearestObjects", resolver)
        self.assertIn("nearestTerrainObjects", resolver)
        self.assertIn("surfaceIsWater", resolver)
        self.assertIn("call Waldo_fnc_RecoveryResolveRestorePosition", restore)
        self.assertIn("no clear position", restore)

    def test_ui_themes_are_visual_only_global_jip_state_with_qa_control(self):
        root = ROOT / "MissionScripts" / "MissionFlowAndUi"
        resolver = (root / "uiTheme.sqf").read_text(encoding="utf-8")
        setter = (root / "uiThemeSetServer.sqf").read_text(encoding="utf-8")
        apply_local = (root / "uiThemeApplyLocal.sqf").read_text(encoding="utf-8")
        restyle_notifications = (root / "restyleUiNotificationsLocal.sqf").read_text(encoding="utf-8")
        notification = (root / "showUiNotification.sqf").read_text(encoding="utf-8")
        root_init = (ROOT / "init.sqf").read_text(encoding="utf-8")
        shared_config = (ROOT / "MissionConfig" / "interfaceConfig.sqf").read_text(encoding="utf-8")
        snapshot = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeRequestState.sqf").read_text(encoding="utf-8")
        receive = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeReceiveState.sqf").read_text(encoding="utf-8")
        for theme in ("DEFAULT", "WW2", "VIETNAM", "SCIFI"):
            self.assertIn(f'["{theme}"', resolver)
        self.assertIn('missionNamespace setVariable ["Waldo_UI_Theme", _themeId, true]', setter)
        self.assertIn("getAssignedCuratorLogic", setter)
        self.assertIn('remoteExecCall ["Waldo_fnc_UiThemeApplyLocal", 0]', setter)
        self.assertIn("Waldo_UI_CustomThemes", resolver + shared_config)
        self.assertIn("Waldo_UI_ThemeOverrides", resolver + shared_config)
        self.assertIn("Waldo_UI_Theme", shared_config)
        self.assertIn("Waldo_fnc_ShowUiNotification", apply_local)
        self.assertIn("Waldo_fnc_RestyleUiNotificationsLocal", apply_local)
        self.assertIn('setVariable ["Waldo_IMG_Profile"', apply_local)
        self.assertIn('setVariable ["Waldo_IMG_PickerTheme"', apply_local)
        self.assertIn('setVariable ["WaldoEcoCore_PromptTheme"', apply_local)
        self.assertIn("ctrlSetStructuredText", restyle_notifications)
        self.assertIn("ctrlTextHeight", restyle_notifications)
        self.assertIn("[_title, _messageText, _state, _source]", notification)
        self.assertIn('"Waldo_UI_Theme"', snapshot)
        self.assertIn("call Waldo_fnc_UiThemeApplyLocal", receive)


    def test_dynamic_ao_runtime_generator_and_recent_regressions_are_wired(self):
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        ao_dir = ROOT / "MissionScripts" / "CombatSystems" / "DynamicAO"
        create = (ao_dir / "dynamicAOCreate.sqf").read_text(encoding="utf-8")
        zen = (ao_dir / "dynamicAOZen.sqf").read_text(encoding="utf-8")
        all_ao = "\n".join(path.read_text(encoding="utf-8") for path in ao_dir.glob("*.sqf"))
        modules = (ROOT / "MissionScripts" / "ZenModules" / "Zen_initModules.sqf").read_text(encoding="utf-8")
        for function in (
            "DynamicAOGetFactions", "DynamicAOResolvePools", "DynamicAOCreate",
            "DynamicAODestroyMinefield", "DynamicAODestroy", "DynamicAOZen", "DynamicAORemoveZen",
        ):
            self.assertIn(f"class {function}", functions)
        for token in (
            'configClasses (configFile >> "CfgFactionClasses")', 'configClasses (configFile >> "CfgVehicles")',
            'Waldo_DynamicAO_Registry', 'Waldo_DynamicAO_PublicSystems', 'Waldo_fnc_AIApplyProfile',
            'createMine', 'nearRoads', 'buildingPos -1', 'addCuratorEditableObjects',
        ):
            self.assertIn(token, all_ao)
        self.assertNotIn('Waldo_AI_Exclude', all_ao)
        self.assertNotIn('["skill",', create + zen)
        self.assertNotIn('AI skill', zen)
        route = (ao_dir / "dynamicAOAddPatrolWaypoints.sqf").read_text(encoding="utf-8")
        for token in (
            'deleteWaypoint', 'enableAI "PATH"', 'enableAI "MOVE"', 'setCurrentWaypoint',
            'setBehaviour _behaviour', 'setSpeedMode _speed', 'setWaypointFormation _formation',
        ):
            self.assertIn(token, route)
        self.assertIn('_group addVehicle _vehicle', create)
        self.assertIn('"SAFE", "LIMITED", ["COLUMN", "STAG COLUMN", "WEDGE"]', create)
        self.assertIn('"AWARE", "NORMAL"', create)
        for control in (
            "Enemy faction and side", "Vehicle ratio - cars", "Air ratio - helicopters",
            "Civilian faction", "Outer-ring minefields", "Manned roadblocks",
        ):
            self.assertIn(control, zen)
        for category in (
            "WMP Mission Flow", "WMP Logistics", "WMP Combat Systems", "WMP Air Operations",
            "WMP Mission Tools", "WMP Interface & QA",
        ):
            self.assertIn(category, modules)
        self.assertNotIn("Generate in editor", create + zen)

        paradrop = (ROOT / "MissionScripts" / "Paradrop" / "paradropCreateDropZone.sqf").read_text(encoding="utf-8")
        embark = (ROOT / "MissionScripts" / "Paradrop" / "paradropEmbarkLocal.sqf").read_text(encoding="utf-8")
        self.assertIn('_maximumSpeed + 40', paradrop)
        self.assertIn('_altitude + 75', paradrop)
        self.assertIn('if (!canSuspend) exitWith', embark)
        jammer = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammerScan.sqf").read_text(encoding="utf-8")
        self.assertIn('Waldo_Jamming_ScanDistanceBands', jammer)
        self.assertIn('"VERY CLOSE"', jammer)

    def test_concurrent_hud_regions_reflow_and_yield_to_ace(self):
        ui_root = ROOT / "MissionScripts" / "MissionFlowAndUi"
        reflow = (ui_root / "reflowUiPanels.sqf").read_text(encoding="utf-8")
        suppress = (ui_root / "setUiPanelsSuppressed.sqf").read_text(encoding="utf-8")
        priority = (ui_root / "setupUiAcePriority.sqf").read_text(encoding="utf-8")
        rally = (ROOT / "MissionScripts" / "Respawn" / "RallyPoint" / "rallyPointNotifyLocal.sqf").read_text(encoding="utf-8")
        jammer = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammingHud.sqf").read_text(encoding="utf-8")
        hazard = (ROOT / "MissionScripts" / "EnvironmentalSystems" / "HazardousEnvironments" / "hazardTick.sqf").read_text(encoding="utf-8")
        legacy = (ui_root / "dynamicText.sqf").read_text(encoding="utf-8")

        reservation = (ui_root / "registerUiReservationLocal.sqf").read_text(encoding="utf-8")
        unregister = (ui_root / "unregisterUiReservationLocal.sqf").read_text(encoding="utf-8")
        self.assertIn('Waldo_UI_ReservationRegistry', reflow + reservation + unregister)
        self.assertNotIn('displayCtrl 5299', reflow)
        self.assertNotIn('displayCtrl 5309', reflow)
        self.assertIn('_placement in _placements', reflow)
        self.assertIn('"TOP_RIGHT", "RALLY_POINT"', rally)
        self.assertIn('Waldo_fnc_RegisterUiReservationLocal', jammer)
        self.assertIn('Waldo_UI_ReservationRegistry', suppress)
        for feature_name in ("RALLY", "JAMMER", "SAFESTART"):
            self.assertNotIn(feature_name, reflow)
        self.assertIn('ace_interactMenuOpened', priority)
        self.assertIn('ace_interactMenuClosed', priority)
        self.assertIn('"HAZARD_STATUS"', hazard)
        self.assertNotIn('BIS_fnc_dynamicText', hazard + legacy)

        save_loadout = (ROOT / "MissionScripts" / "Logistics" / "LogiHelpers" / "saveRespawnLoadout.sqf").read_text(encoding="utf-8")
        acre = (ROOT / "MissionScripts" / "MissionInit" / "ACRE2" / "ACRE2Init.sqf").read_text(encoding="utf-8")
        self.assertIn('params [["_showNotification", true', save_loadout)
        self.assertIn('if (_showNotification)', save_loadout)
        self.assertIn('[false] call Waldo_fnc_SaveLoadout', acre)

        zen_modules = (ROOT / "MissionScripts" / "ZenModules" / "Zen_initModules.sqf").read_text(encoding="utf-8")
        self.assertIn('["WMP Logistics", "Respawn: Create Loadout Save Point"', zen_modules)
        self.assertNotIn('Emergency Dismount - Control', zen_modules)

        jammer_zen = (ROOT / "MissionScripts" / "ZenModules" / "Zen_jammerPlaceModule.sqf").read_text(encoding="utf-8")
        jammer_server = (ROOT / "MissionScripts" / "ZenModules" / "ZenCreateJammerServer.sqf").read_text(encoding="utf-8")
        jammer_interaction = (ROOT / "MissionScripts" / "MissionInit" / "Jamming" / "jammerInteraction.sqf").read_text(encoding="utf-8")
        self.assertIn('["EXISTING"]', jammer_zen)
        self.assertIn('[_emitterClasses, _emitterLabels, 0]', jammer_zen)
        self.assertIn('private _existingObject = if (_source isEqualTo "EXISTING")', jammer_zen)
        self.assertIn('player,\n            _existingObject', jammer_zen)
        self.assertIn('ZenAssignObjectOwnerServer', jammer_server)
        self.assertIn('_requestOwner, false, false', jammer_server)
        self.assertIn('private _object = _existingObject', jammer_server)
        self.assertIn('simulationEnabled _object', jammer_server)
        self.assertIn('["className", _className]', jammer_zen)
        self.assertIn('createHashMapFromArray _settings', jammer_server)
        self.assertIn('_className = _settingsMap getOrDefault ["className", _className]', jammer_server)
        self.assertNotIn('_settings params ["_radius"', jammer_server)
        for setting_name in ("radius", "side", "bands", "falloff", "strength", "active", "marker", "sector", "duty", "jamUAV", "show3D", "className", "disableChallenge", "challengeId", "difficulty", "engineerOnly", "resultMode", "allowPlayerToggle"):
            self.assertIn(f'["{setting_name}",', jammer_zen)
            self.assertIn(f'["{setting_name}", _', jammer_server)
        self.assertIn('sleep 0.35', jammer_server)
        owner_helper = (ROOT / "MissionScripts" / "ZenModules" / "zenAssignObjectOwnerServer.sqf").read_text(encoding="utf-8")
        self.assertIn('_object enableSimulationGlobal (!_freezeSimulation)', owner_helper)
        self.assertIn('_object setOwner _ownerId', owner_helper)
        self.assertIn('Waldo_Jamming_DisableACEPath', jammer_interaction)
        self.assertIn('Waldo_Jamming_DisableACEInstalled', jammer_interaction)
        self.assertIn('Waldo_Jamming_DisableResult', jammer_interaction)
        self.assertIn('"Waldo_Jammer_Activate"', jammer_interaction)
        self.assertIn('"Activate Jammer"', jammer_interaction)
        self.assertIn('[_target, true] call Waldo_fnc_JammerToggle', jammer_interaction)
        activate_block = jammer_interaction.split('private _activate = [', 1)[1].split('private _disable = [', 1)[0]
        self.assertNotIn('Waldo_Jamming_FieldDisabled', activate_block)
        self.assertNotIn('private _deactivate = [', jammer_interaction)
        self.assertNotIn('"Deactivate Jammer"', jammer_interaction)
        self.assertNotIn('[_target, false] call Waldo_fnc_JammerToggle', jammer_interaction)
        self.assertIn('Waldo_Jamming_InteractionVersion', jammer_interaction)
        self.assertIn('Allow Reactivation', jammer_zen)
        self.assertIn('["allowPlayerToggle", _allowPlayerToggle]', jammer_zen)
        self.assertNotIn('enableSimulationGlobal false', jammer_server)

        tracker_zen = (ROOT / "MissionScripts" / "ZenModules" / "Zen_trackerModule.sqf").read_text(encoding="utf-8")
        self.assertIn('if (isNull _objectPos) exitWith', tracker_zen)
        self.assertIn('Place this module directly on the object or unit to track.', tracker_zen)
        self.assertIn('[_target, _sideStr, _label, _active] call Waldo_fnc_Tracker', tracker_zen)
        self.assertNotIn('nearestObjects', tracker_zen)


if __name__ == "__main__":
    unittest.main()
