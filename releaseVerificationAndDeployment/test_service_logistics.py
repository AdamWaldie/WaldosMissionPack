"""Static contracts for the opt-in service and logistics additions.

These checks do not replace ACE or Arma multiplayer interaction tests.
"""

from pathlib import Path
import importlib.util
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class ServiceLogisticsSourceTests(unittest.TestCase):
    def test_packaged_acre_test_uses_current_pack_and_nato_buggy(self):
        builder_path = ROOT / "releaseVerificationAndDeployment/build_service_logistics_test_mission.py"
        spec = importlib.util.spec_from_file_location("wmp_service_logistics_builder", builder_path)
        assert spec and spec.loader
        builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(builder)
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "WMP_ACRE2_Respawn_Test.VR"
            archive = Path(temporary) / "mission.zip"
            builder.build(destination)
            builder.package(destination, archive)
            mission = (destination / "mission.sqm").read_text(encoding="utf-8")
            self.assertIn('vehicle="B_LSV_01_unarmed_F"', mission)
            self.assertIn('text="test_transfer_source"', mission)
            self.assertIn('text="test_cargo_crate"', mission)
            self.assertIn('"ALPHA_NET"', (destination / "MissionConfig/acreConfig.sqf").read_text(encoding="utf-8"))
            self.assertEqual(
                (ROOT / "MissionScripts/WaldosFunctions.sqf").read_bytes(),
                (destination / "MissionScripts/WaldosFunctions.sqf").read_bytes(),
            )
            self.assertIn('serviceLogisticsTestPreInit.sqf', (destination / "init.sqf").read_text(encoding="utf-8"))
            self.assertIn('serviceLogisticsTestServer.sqf', (destination / "initServer.sqf").read_text(encoding="utf-8"))
            seat_setup = (destination / "serviceLogisticsTestServer.sqf").read_text(encoding="utf-8")
            self.assertIn('Waldo_PhysicalCargo_SeatPoints', seat_setup)
            self.assertIn('moveInTurret [test_cargo_vehicle, _path]', seat_setup)
            with zipfile.ZipFile(archive) as package:
                self.assertIn(
                    "WMP_ACRE2_Respawn_Test.VR/serviceLogisticsTestServer.sqf",
                    package.namelist(),
                )

    def test_audit_has_live_station_for_each_new_workflow(self):
        import importlib.util

        path = ROOT / "releaseVerificationAndDeployment/generate_full_arma_audit_mission.py"
        spec = importlib.util.spec_from_file_location("wmp_audit_generator", path)
        generator = importlib.util.module_from_spec(spec)
        assert spec and spec.loader
        spec.loader.exec_module(generator)
        station_ids = {row[0] for row in generator.STATIONS}
        fixture_ids = {row["name"] for row in generator.FIXTURES}
        for name in ("base-services", "quartermaster-issues", "supply-transfers", "physical-cargo",
                     "static-cargo", "cargo-seats", "briefing-docs", "dialogue-author", "emergency-dismount"):
            self.assertIn(name, station_ids)
            self.assertIn("qa_sign_" + name.replace("-", "_"), fixture_ids)
        for name in ("qa_base_hq", "qa_base_fob", "qa_qm_point", "qa_transfer_source",
                     "qa_transfer_target", "qa_transfer_vehicle", "qa_cargo_vehicle", "qa_cargo_crate", "qa_weapon_vehicle",
                     "qa_weapon_static", "qa_seat_vehicle", "qa_seat_crate"):
            self.assertIn(name, fixture_ids)
        live = {row["name"]: row for row in generator.FIXTURES}
        for name in ("qa_transfer_source", "qa_transfer_target", "qa_transfer_vehicle", "qa_cargo_vehicle",
                     "qa_cargo_crate", "qa_weapon_vehicle", "qa_weapon_static",
                     "qa_seat_vehicle", "qa_seat_crate"):
            self.assertTrue(live[name]["simulation"], name)
        server = source("releaseVerificationAndDeployment/fullArmaAudit/WMP_FPA.VR/serviceLogisticsStationsServer.sqf")
        client = source("releaseVerificationAndDeployment/fullArmaAudit/WMP_FPA.VR/extendedFeatureStationsClient.sqf")
        self.assertIn('call Waldo_fnc_BaseServicesRegister', server)
        self.assertIn('call Waldo_fnc_SetupQuarterMaster', server)
        self.assertIn('call Waldo_fnc_SupplyTransfersRegister', server)
        self.assertIn('"qa_transfer_vehicle"', server)
        self.assertIn('call Waldo_fnc_PhysicalCargoRegister', server)
        self.assertIn('call Waldo_fnc_SetCargoAttributes', server)
        self.assertIn('"QA Forward Base", _services]], "TRAVEL"', server)
        self.assertIn('[_qmPoint, 0, 5] call Waldo_fnc_SetupQuarterMaster', client)
        self.assertIn('Waldo_QA_fnc_captureCargoSeatServer', server)
        self.assertIn('ASLToAGL getPosWorld _actor', server)
        self.assertIn('"CAPTURE MY OCCUPIED CARGO SEAT"', client)
        self.assertIn('[player, 1, ["ACE_SelfActions"], _captureSeat]', client)
        self.assertIn('[WMP QA SEAT CAPTURE]', server)
        self.assertEqual(live["qa_seat_vehicle"]["class"], "B_LSV_01_unarmed_F")
        self.assertNotIn('"rhsusf_mrzr4_d"', server)
        self.assertEqual(live["qa_seat_crate"]["class"], "Box_NATO_Ammo_F")
        self.assertIn('"Measured post-exit velocity', client)
        self.assertIn('TEST CRATE + VEHICLE TRANSFERS', client)

    def test_dialogue_editor_mutations_do_not_flood_notification_lanes(self):
        mutator = source("MissionScripts/ZenModules/Dialogue/conversationAuthorMutateLocal.sqf")
        self.assertIn('ctrlSetStructuredText', mutator)
        self.assertNotIn('Waldo_fnc_FeatureNotifyLocal', mutator)

    def test_new_features_start_opted_out(self):
        logistics = source("MissionConfig/logisticsConfig.sqf")
        systems = source("MissionConfig/missionSystemsConfig.sqf")
        self.assertIn('["Waldo_BaseServices_Enable", false]', systems)
        self.assertIn('["Waldo_SupplyTransfers_Enable", false]', logistics)
        self.assertNotIn('Waldo_PhysicalCargo_WeaponMount_Enable', logistics)
        for name in ("Grenades", "Explosives", "Rearm", "VehicleRearm", "StaticRearm", "FuelBarrel", "FuelJerrycan"):
            self.assertIn(f'["Waldo_QM_{name}_Enable", false]', logistics)

    def test_base_services_authority_and_jip(self):
        register = source("MissionScripts/MissionFlowAndUi/BaseServices/baseServicesRegister.sqf")
        teleport = source("MissionScripts/MissionFlowAndUi/BaseServices/baseServicesTeleportServer.sqf")
        self.assertIn('missionNamespace setVariable ["Waldo_BaseServices_Registry", _registry, true]', register)
        self.assertIn('Waldo_fnc_Create3DMarker', register)
        self.assertIn('Waldo_fnc_Remove3DMarker', register)
        self.assertIn('remoteExecutedOwner isNotEqualTo owner _player', teleport)
        self.assertIn('Waldo_fnc_BaseServicesRequestStateServer', source("MissionScripts/MissionFlowAndUi/BaseServices/baseServicesSetupLocal.sqf"))
        local = source("MissionScripts/MissionFlowAndUi/BaseServices/baseServicesTeleportLocal.sqf")
        for preset in ('"QUICK"', '"TRAVEL"', '"NIGHT"', '"DAYLIGHT"', '"NONE"'):
            self.assertIn(preset, local)
        self.assertIn('apertureParams', local)
        self.assertIn('format ["Traveling to %1...", _destinationName]', local)
        self.assertLess(local.index('uiSleep _out'), local.index('_unit setPosATL _clear'))
        heal = source("MissionScripts/MissionFlowAndUi/BaseServices/baseServicesUseLocal.sqf")
        self.assertIn('"BOTTOM_RIGHT", "BASE_HEAL"', heal)
        self.assertIn('Waldo_fnc_ShowUiNotification', heal)

    def test_quartermaster_issues_have_consistent_names_and_one_rearm_action(self):
        actions = source("MissionScripts/Logistics/Crates/initQuartermaster.sqf")
        extended = source("MissionScripts/Logistics/Crates/quartermasterExtendedSpawn.sqf")
        legacy = source("MissionScripts/Logistics/Crates/LogiBoxes.sqf")
        self.assertIn('"Retrieve Rearm Box", "Rearm"', actions)
        self.assertNotIn('"Retrieve Vehicle Rearm Box"', actions)
        self.assertNotIn('"Retrieve Static Weapon Rearm Box"', actions)
        self.assertIn('_offsetDistance, _title', actions)
        self.assertIn('ace_cargo_customName', extended)
        self.assertIn('ace_cargo_customName', legacy)
        self.assertIn('Box_%1_%2', extended)

    def test_module_crates_and_compositions_follow_role_registration(self):
        for path in (
            "MissionScripts/ZenModules/ZenSpawnCrateServer.sqf",
            "MissionScripts/ZenModules/Zen_loadoutSaveModule.sqf",
            "MissionScripts/Logistics/FieldResupply/fieldResupplyServerHandle.sqf",
            "MissionScripts/ZenModules/RuntimeControl/featureRuntimeApply.sqf",
        ):
            self.assertIn('Waldo_fnc_LogisticsRegisterSpawned', source(path), path)
        for path in (
            "MissionScripts/Logistics/Crates/doSupplyCrate.sqf",
            "MissionScripts/Logistics/Crates/doMedicalCrate.sqf",
        ):
            self.assertIn('Waldo_fnc_LogisticsRegisterSpawned', source(path), path)
        self.assertIn('Waldo_Logistics_StarterCrate', source('MissionScripts/Logistics/Crates/doStarterCrate.sqf'))
        helper = source('MissionScripts/Logistics/Crates/logisticsRegisterSpawned.sqf')
        self.assertIn('Waldo_SupplyTransfers_Enable', helper)
        self.assertIn('Waldo_PhysicalCargo_Enable', helper)
        self.assertIn('if (_role == "STARTER") exitWith', helper)

    def test_node_registration_is_additive_and_zen_is_curator_gated(self):
        node = source('MissionScripts/MissionFlowAndUi/BaseServices/baseServicesRegisterNode.sqf')
        self.assertIn('Waldo_SharedFeatureConfigReady', node)
        self.assertIn('_rows pushBack _row', node)
        self.assertIn('call Waldo_fnc_BaseServicesRegister', node)
        server = source('MissionScripts/ZenModules/zenServiceLogisticsServer.sqf')
        self.assertIn('getAssignedCuratorLogic _requester', server)
        for operation in ('BASE_UPSERT', 'BASE_REMOVE', 'QUARTERMASTER', 'SUPPLY_REGISTER', 'PHYSICAL_ENABLE'):
            self.assertIn(f'case "{operation}"', server)

    def test_rearm_box_is_empty_and_identified(self):
        extended = source('MissionScripts/Logistics/Crates/quartermasterExtendedSpawn.sqf')
        for cargo_type in ('Weapon', 'Magazine', 'Item', 'Backpack'):
            self.assertIn(f'clear{cargo_type}CargoGlobal _object', extended)
        self.assertIn('ace_rearm_fnc_makeSource', extended)
        self.assertIn('Waldo_fnc_QuartermasterRearmLabelLocal', extended)

    def test_crate_options_and_merge_are_separate(self):
        options = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf")
        load = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetAceLoadServer.sqf")
        merge = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersRequestServer.sqf")
        self.assertIn('"Enable ACE loading"', options)
        self.assertIn('"Disable ACE loading"', options)
        self.assertIn('ace_cargo_fnc_setSize', load)
        self.assertIn('remoteExecutedOwner isNotEqualTo owner _player', load)
        self.assertIn('"ALL"', merge)
        self.assertNotIn('Waldo_fnc_SupplyTransfersSnapshot', options)
        self.assertIn('"DELETE"', merge)
        self.assertIn('"vehicle removal is not a crate action"', merge)
        self.assertIn('"Transfer from this box..."', options)
        self.assertIn('"Select this box for merge / vehicle transfer"', options)
        self.assertIn('"Merge selected source into this box"', options)
        self.assertNotIn('"Consolidate all into this container"', options)
        self.assertIn('Waldo_SupplyTransfers_Range', merge)
        self.assertIn('Waldo_fnc_SupplyTransfersRefreshLocal',
                      source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersOpenLocal.sqf"))
        self.assertIn('"MERGE SOURCE SELECTED"', options)
        self.assertIn('Waldo_SupplyTransfers_SelectedSource', options)
        self.assertNotIn('Waldo_fnc_SupplyTransfersOpenMergeLocal', options)

    def test_dynamic_text_uses_feature_titles_with_legacy_default(self):
        adapter = source("MissionScripts/MissionFlowAndUi/dynamicText.sqf")
        self.assertIn('"MISSION UPDATE"', adapter)
        self.assertIn('format ["DYNAMIC_TEXT_%1", _title]', adapter)
        for path in (
            "MissionScripts/Logistics/Crates/LogiBoxes.sqf",
            "MissionScripts/Logistics/Crates/initQuartermaster.sqf",
            "MissionScripts/Logistics/Crates/quartermasterExtendedSpawn.sqf",
        ):
            self.assertIn('"QUARTERMASTER"] call Waldo_fnc_DynamicText', source(path))

    def test_base_markers_touch_object_surface_and_allow_manual_offset(self):
        register = source("MissionScripts/MissionFlowAndUi/BaseServices/baseServicesRegister.sqf")
        self.assertIn('boundingBoxReal _object', register)
        self.assertIn('"_markerOffset"', register)
        self.assertIn('["offset", _markerOffset]', register)
        self.assertNotIn('["offset", [0, 0, 0.5]]', register)

    def test_vehicle_destinations_are_discovered_and_revalidated(self):
        destinations = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersDestinationsLocal.sqf")
        request = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersRequestServer.sqf")
        panel = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersOpenLocal.sqf")
        self.assertIn('nearestObjects [_source, ["LandVehicle", "Air", "Ship"], _range]', destinations)
        self.assertIn('maxLoad _destination > 0', request)
        self.assertIn('alive _destination', request)
        self.assertIn('"invalid interaction origin"', request)
        self.assertIn('"BATCH", _moves, 1, _interaction', source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSubmitLocal.sqf"))
        self.assertIn('player distance _interaction > 6', panel)
        self.assertNotIn('"Transfer supplies into vehicle..."', source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf"))
        self.assertIn('"Transfer from this vehicle..."', source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf"))
        self.assertIn('"Select this vehicle as supply source"', source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf"))
        self.assertIn('"Merge selected source into this vehicle"', source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf"))
        self.assertIn('private _source = ["WMP_SUPPLY_SOURCE", _selectLabel', source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf"))
        self.assertIn('private _merge = ["WMP_SUPPLY_MERGE", _mergeLabel', source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf"))
        self.assertIn('!isNull _selected && {_selected isNotEqualTo _target}', source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf"))
        self.assertIn('"SUPPLY_REGISTER"', source("MissionScripts/ZenModules/zenServiceLogisticsServer.sqf"))
        self.assertIn('call Waldo_fnc_SupplyTransfersRegister', source("MissionScripts/ZenModules/zenServiceLogisticsServer.sqf"))
        station = source("releaseVerificationAndDeployment/fullArmaAudit/WMP_FPA.VR/serviceLogisticsStationsServer.sqf")
        self.assertIn('"qa_transfer_vehicle" call _get', station)
        self.assertIn('_transferVehicle enableSimulationGlobal true', station)
        self.assertIn('"qa_transfer_control" call _get', station)
        self.assertNotIn('[_transferControl] call Waldo_fnc_SupplyTransfersRegister', station)

    def test_transfer_panel_queues_multiple_lines_for_one_authoritative_commit(self):
        panel = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersOpenLocal.sqf")
        submit = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSubmitLocal.sqf")
        request = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersRequestServer.sqf")
        result = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersResultLocal.sqf")
        for label in ("ADD TO LIST", "ALL OF TYPE", "REMOVE LINE", "CLEAR LIST", "TRANSFER LIST"):
            self.assertIn(label, panel)
        self.assertIn('"BATCH", _moves, 1', submit)
        self.assertIn('count _moves <= 100', request)
        self.assertIn('forEach _moves', request)
        self.assertIn('Waldo_SupplyTransfers_Pending', result)
        self.assertIn('Waldo_SupplyTransfers_Queue', result)
        actions = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf")
        self.assertIn('"ALL", [], 1', actions)

    def test_quartermaster_fuel_icon_is_not_missing_asset(self):
        actions = source("MissionScripts/Logistics/Crates/initQuartermaster.sqf")
        self.assertNotIn('simpletasks\\types\\fuel_ca.paa', actions)
        self.assertIn('mapcontrol\\Fuelstation_CA.paa', actions)

    def test_zen_quartermaster_prefills_script_created_point_and_sends_all_controls(self):
        setup = source("MissionScripts/Logistics/Crates/initQuartermaster.sqf")
        dialog = source("MissionScripts/ZenModules/zenServiceLogisticsModule.sqf")
        server = source("MissionScripts/ZenModules/zenServiceLogisticsServer.sqf")
        self.assertIn('"Waldo_QM_SetupSettings"', setup)
        self.assertIn('"Waldo_QM_SetupSettings"', dialog)
        for key in ('bearing', 'distance', 'deploymentControlled', 'allowedKinds'):
            self.assertIn(f'["{key}",', dialog)
            self.assertIn(f'getOrDefault ["{key}",', server)

    def test_shared_rearm_issue_reaches_extended_spawner(self):
        dispatcher = source("MissionScripts/Logistics/Crates/LogiBoxes.sqf")
        self.assertIn('"Grenades", "Explosives", "Rearm", "VehicleRearm"', dispatcher)
        extended = source("MissionScripts/Logistics/Crates/quartermasterExtendedSpawn.sqf")
        self.assertIn('case "Rearm":', extended)
        audit = source("releaseVerificationAndDeployment/fullArmaAudit/WMP_FPA.VR/auditPreInit.sqf")
        self.assertIn('"Grenades", "Explosives", "Rearm", "FuelBarrel"', audit)

    def test_supply_snapshot_retains_non_flat_cargo(self):
        snapshot = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSnapshot.sqf")
        apply = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersApplySnapshot.sqf")
        self.assertIn('weaponsItemsCargo', snapshot)
        self.assertIn('magazinesAmmoCargo', snapshot)
        self.assertIn('everyBackpack', snapshot)
        self.assertIn('addWeaponWithAttachmentsCargoGlobal', apply)
        self.assertIn('addMagazineAmmoCargo', apply)


if __name__ == "__main__":
    unittest.main()
