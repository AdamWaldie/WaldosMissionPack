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
            self.assertIn('onLoadName = "WMP PR REVIEW AUDIT"', (destination / "description.ext").read_text(encoding="utf-8"))
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

    def test_audit_artifacts_are_not_part_of_release_contract(self):
        entries = set(BUILDER.release_entries())
        self.assertNotIn("releaseVerificationAndDeployment", entries)
        self.assertNotIn("wiki", entries)
        self.assertNotIn(".qa", entries)
        self.assertNotIn("mission.sqm", entries)

    def test_pack_supports_legacy_mission_loadout_scraping(self):
        source = (
            ROOT / "MissionScripts" / "Logistics" / "LogiHelpers" / "missionFileLookup.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn("_matchedConfigUnits == 0", source)
        self.assertIn("getUnitLoadout _x", source)
        self.assertIn("forEach playableUnits", source)

    def test_pack_scrapes_playable_units_inside_nested_eden_folders(self):
        source = (
            ROOT / "MissionScripts" / "Logistics" / "LogiHelpers" / "missionFileLookup.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn('getText (_entity >> "dataType") == "Object"', source)
        self.assertIn("_isPlayer == 1 || _isPlayable == 1", source)
        self.assertIn('private _children = _entity >> "Entities"', source)
        self.assertIn("[_x] call _visitEntity", source)
        self.assertIn('missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities"', source)

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
            "Waldo_fnc_HazardRegisterZone",
            "Waldo_fnc_BreachingServerHandle",
            "Waldo_fnc_FieldResupplyRegisterHub",
            "Waldo_fnc_TacticalDisplayRegister",
            "Waldo_fnc_DynamicAACreate",
            "Waldo_fnc_GunshipRegister",
            "Waldo_fnc_RecoveryRegisterVehicle",
            "Waldo_fnc_CreateLimitedArsenal",
            "B_T_VTOL_01_vehicle_F",
            "B_UAV_02_dynamicLoadout_F",
            "(group _actor) reveal",
        ):
            self.assertIn(token, server)
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
        pack = (ROOT / "initPlayerLocal.sqf").read_text(encoding="utf-8")
        preinit = (
            ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "auditPreInitPlayerLocal.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn('["76561198094931408"]', pack)
        self.assertIn("getPlayerUID player", preinit)
        self.assertIn('Waldo_AccessibilityPID_AllowedUIDs", if (_auditUid == "")', preinit)

    def test_selected_features_are_not_registered_as_zen_modules(self):
        source = (ROOT / "MissionScripts" / "ZenModules" / "Zen_initModules.sqf").read_text(encoding="utf-8")
        for removed in (
            "Treatment Feedback - Control",
            "Tree Felling - Control",
            "Accessibility PID - Control",
            "Breaching - Configure Class",
        ):
            self.assertNotIn(removed, source)
        self.assertIn('Waldo_ZenModuleCount", 36', source)

    def test_field_resupply_zen_can_create_a_hub_crate_authoritatively(self):
        zen = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeZen.sqf").read_text(encoding="utf-8")
        apply = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeApply.sqf").read_text(encoding="utf-8")
        self.assertIn('[_target, _side, parseNumber _stockText, _modulePos]', zen)
        self.assertIn('if (isNull _hub && {count _modulePos >= 2})', apply)
        self.assertIn('createVehicle [_crateClass, _modulePos, [], 0, "NONE"]', apply)
        self.assertIn('addCuratorEditableObjects [[_hub], true]', apply)

    def test_runtime_setting_bundle_is_not_unpacked_as_one_pair(self):
        source = (ROOT / "MissionScripts" / "ZenModules" / "RuntimeControl" / "featureRuntimeApply.sqf").read_text(encoding="utf-8")
        self.assertIn("private _updates = _this;", source)
        self.assertNotIn('private _publishAll = {\n    params ["_updates"]', source)

    def test_accessibility_toggle_is_an_ace_self_interaction(self):
        source = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "Accessibility" / "accessibilityPIDInit.sqf").read_text(encoding="utf-8")
        self.assertIn('[player, 1, ["ACE_SelfActions"], _action]', source)
        self.assertIn("ace_interact_menu_fnc_createAction", source)
        self.assertNotIn("player addAction", source)

    def test_persistence_gate_executes_a_native_version_probe(self):
        source = (ROOT / "MissionScripts" / "Persistence" / "persistenceDependencyAvailable.sqf").read_text(encoding="utf-8")
        self.assertIn('private _version = "getVersion" call _probeDb', source)
        self.assertIn('_versionText find "inidbi" >= 0', source)
        self.assertIn('_dllVersion != ""', source)
        launcher = (ROOT / "releaseVerificationAndDeployment" / "launch_pr_review_audit.ps1").read_text(encoding="utf-8")
        self.assertIn("[switch]$ExcludePersistenceMod", launcher)
        self.assertIn("if ($ExcludePersistenceMod)", launcher)

    def test_notification_stack_reflows_surviving_cards(self):
        source = (ROOT / "MissionScripts" / "MissionFlowAndUi" / "reflowUiPanels.sqf").read_text(encoding="utf-8")
        audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR" / "featureRangeClient.sqf").read_text(encoding="utf-8")
        self.assertIn("ctrlCommit _duration", source)
        for duration in ('"INFO", 4, "TOP_RIGHT", "QA_STACK_1"', '"SUCCESS", 8, "TOP_RIGHT", "QA_STACK_2"', '"WARNING", 12, "TOP_RIGHT", "QA_STACK_3"'):
            self.assertIn(duration, audit)

    def test_scale_zen_does_not_replace_curator_selected_objects(self):
        source = (ROOT / "MissionScripts" / "MissionMakerResourceScripts" / "ObjectTransforms" / "objectScaleZen.sqf").read_text(encoding="utf-8")
        self.assertIn('[_target, _scale, false]', source)
        self.assertNotIn("Convert to simple object", source)


    def test_corrected_feature_workflows_have_runtime_controls_and_bounds(self):
        scripts = ROOT / "MissionScripts"
        audit = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"

        arsenal = (scripts / "Logistics" / "Crates" / "createLimitedAceArsenal.sqf").read_text(encoding="utf-8")
        self.assertIn('_aceArsenalPool select {!(_x isEqualTo ["EMPTY"])}', arsenal)
        self.assertNotIn("deleteAt _x", arsenal)

        jammer = (scripts / "MissionInit" / "Jamming" / "jammerScan.sqf").read_text(encoding="utf-8")
        self.assertIn("_d <= _range", jammer)
        self.assertIn("Bearing between %1 and %2 deg", jammer)
        for vague_band in ("NEARBY", "DISTANT", "VERY DISTANT"):
            self.assertIn(vague_band, jammer)
        self.assertNotIn("Signal strength", jammer)

        rally = (scripts / "Respawn" / "RallyPoint" / "rallyPointSetupLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("ACE_SelfActions", rally)
        self.assertIn("ace_common_fnc_progressBar", rally)
        self.assertIn("BIS_fnc_holdActionAdd", rally)

        gunship = (scripts / "CombatSystems" / "AirborneGunship" / "gunshipSetupLocal.sqf").read_text(encoding="utf-8")
        self.assertIn("_x select 2", gunship)
        self.assertIn("Waldo_Gunship_AceActions", gunship)

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
        self.assertIn("qa_sign_emergency_dismount", client)
        self.assertIn("REFRESH MY GUNSHIP CONTROLS", client)
        self.assertIn("_scale, true] call Waldo_fnc_ObjectScale", server)
        self.assertIn('missionNamespace setVariable [_name, _scaled, true]', server)
        self.assertIn("Waldo_QA_ControlConsole", controls)
        self.assertIn("Waldo_QA_CoreConsole", controls)
        self.assertIn("_forceVanilla", controls)


if __name__ == "__main__":
    unittest.main()
