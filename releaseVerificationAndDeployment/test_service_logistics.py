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
    def test_ace_cargo_zen_uses_server_validated_shared_setter(self):
        modules = source("MissionScripts/ZenModules/Zen_initModules.sqf")
        dialog = source("MissionScripts/ZenModules/zenServiceLogisticsModule.sqf")
        server = source("MissionScripts/ZenModules/zenServiceLogisticsServer.sqf")
        self.assertIn('"ACE Cargo - Set Object Handling", "ACE_CARGO"', modules)
        self.assertIn('case "ACE_CARGO":', dialog)
        self.assertIn('"ignoreCarryWeight"', dialog)
        self.assertIn('case "ACE_CARGO_SET":', server)
        self.assertIn('call Waldo_fnc_SetCargoAttributes', server)
        self.assertIn('remoteExecutedOwner', server)

    def test_quartermaster_defaults_include_every_normal_issue(self):
        config = source("MissionConfig/logisticsConfig.sqf")
        for kind in ("Medical", "Ammo", "Supply", "Wheel", "Track", "Grenades",
                     "Explosives", "Rearm", "FuelBarrel", "FuelJerrycan"):
            self.assertIn(f'["Waldo_QM_{kind}_Enable", true]', config)

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
            self.assertIn('name="acre_test_logistics_loadout"', mission)
            self.assertIn('isPlayable=1;', mission)
            self.assertIn('name="HandGrenade"', mission)
            self.assertIn('name="DemoCharge_Remote_Mag"', mission)
            self.assertIn('name="ACRE_PRC77"', mission)
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
            self.assertIn('[test_quartermaster, 90, 5] remoteExec ["Waldo_fnc_SetupQuarterMaster", 0, test_quartermaster]', seat_setup)
            self.assertIn('["SAVE", "HEAL", "SPECTATE", "TELEPORT"]', seat_setup)
            with zipfile.ZipFile(archive) as package:
                self.assertIn(
                    "WMP_ACRE2_Respawn_Test.VR/serviceLogisticsTestServer.sqf",
                    package.namelist(),
                )

    def test_eden_examples_do_not_bake_in_vehicle_seat_coordinates(self):
        base = source("WMP_Compositions/[WMP]Base_Services_Example/composition.sqe")
        cargo = source("WMP_Compositions/[WMP]Supply_Transfers_And_Cargo_Example/composition.sqe")
        self.assertEqual(base.count('""SPECTATE""'), 2)
        self.assertIn('type="B_LSV_01_unarmed_F"', cargo)
        self.assertNotIn('""Waldo_PhysicalCargo_SeatPoints""', cargo)
        self.assertIn('init="[this] call Waldo_fnc_SupplyTransfersRegister;"', cargo)
        resolver = source("MissionScripts/Logistics/PhysicalCargo/physicalCargoDiscoverSeatsServer.sqf")
        self.assertIn('selectionNames _lod', resolver)
        self.assertIn('selectionPosition [_x, _lod]', resolver)
        self.assertIn('proxyIndex', resolver)
        self.assertIn('setVariable ["Waldo_PhysicalCargo_SeatPoints", +_points];', resolver)
        self.assertNotIn('setVariable ["Waldo_PhysicalCargo_SeatPoints", +_points, true]', resolver)
        self.assertNotIn('createUnit', resolver)
        self.assertNotIn('moveInCargo', resolver)
        self.assertNotIn('moveInTurret', resolver)
        self.assertIn('call Waldo_fnc_PhysicalCargoDiscoverSeatsServer',
                      source("MissionScripts/Logistics/PhysicalCargo/physicalCargoSeatsServer.sqf"))

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
                     "qa_weapon_static", "qa_seat_vehicle", "qa_seat_crate", "qa_seat_control"):
            self.assertIn(name, fixture_ids)
        live = {row["name"]: row for row in generator.FIXTURES}
        for name in ("qa_transfer_source", "qa_transfer_target", "qa_transfer_vehicle", "qa_cargo_vehicle",
                     "qa_cargo_crate", "qa_weapon_vehicle", "qa_weapon_static",
                     "qa_seat_vehicle", "qa_seat_crate", "qa_seat_control"):
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
        self.assertNotIn('Waldo_QA_fnc_calibrateCargoSeatsServer', server)
        self.assertEqual(live["qa_seat_vehicle"]["class"], "B_LSV_01_unarmed_F")
        self.assertNotIn('"rhsusf_mrzr4_d"', server)
        self.assertEqual(live["qa_seat_crate"]["class"], "Box_NATO_Ammo_F")
        self.assertEqual(live["qa_seat_control"]["class"], "Box_NATO_Ammo_F")
        self.assertIn('"qa_seat_control" call _get', server)
        self.assertIn('"Measured post-exit velocity', client)
        self.assertIn('TEST CRATE + VEHICLE TRANSFERS', client)

    def test_dialogue_editor_mutations_do_not_flood_notification_lanes(self):
        mutator = source("MissionScripts/ZenModules/Dialogue/conversationAuthorMutateLocal.sqf")
        self.assertIn('ctrlSetStructuredText', mutator)
        self.assertNotIn('Waldo_fnc_FeatureNotifyLocal', mutator)

    def test_base_and_transfers_start_opted_out_but_quartermaster_is_full(self):
        logistics = source("MissionConfig/logisticsConfig.sqf")
        systems = source("MissionConfig/missionSystemsConfig.sqf")
        self.assertIn('["Waldo_BaseServices_Enable", false]', systems)
        self.assertIn('["Waldo_SupplyTransfers_Enable", false]', logistics)
        self.assertNotIn('Waldo_PhysicalCargo_WeaponMount_Enable', logistics)
        for name in ("Grenades", "Explosives", "Rearm", "FuelBarrel", "FuelJerrycan"):
            self.assertIn(f'["Waldo_QM_{name}_Enable", true]', logistics)
        for name in ("VehicleRearm", "StaticRearm"):
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
        self.assertIn('Waldo_QM_Marker_Enable', actions)
        self.assertIn('boundingBoxReal _target', actions)

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
        self.assertIn('if (_role == "STARTER" || {_object getVariable ["Waldo_Logistics_StarterCrate", false]}) exitWith', helper)
        self.assertIn('[_object, _role] call Waldo_fnc_CargoAttributesPrepareObject', helper)
        prepare = source('MissionScripts/MissionInit/VehicleActionsSetup/cargoAttributesPrepareObject.sqf')
        self.assertIn('_object isKindOf "LandVehicle"', prepare)
        self.assertNotIn('private _size = nil;', prepare)
        self.assertIn('if (_size == -999) then {[_object, nil, nil] + _choice}', prepare)
        self.assertLess(helper.index('call Waldo_fnc_CargoAttributesPrepareObject'),
                        helper.index('if (missionNamespace getVariable ["Waldo_PhysicalCargo_Enable"'))
        zen_crate = source('MissionScripts/ZenModules/ZenSpawnCrateServer.sqf')
        self.assertNotIn('call Waldo_fnc_CargoAttributesPrepareObject', zen_crate)
        self.assertNotIn('[_crate, true] call ace_dragging_fnc_setCarryable', zen_crate)
        transfer = source('MissionScripts/Logistics/SupplyTransfers/supplyTransfersRegister.sqf')
        self.assertIn('[_container] call Waldo_fnc_CargoAttributesPrepareObject', transfer)
        purchase = source('MissionScripts/EconomySystems/Buy/executePurchase.sqf')
        self.assertIn('[{_this spawn Waldo_fnc_LogisticsRegisterSpawned}, [_spawned, "CARGO"]] call CBA_fnc_execNextFrame', purchase)
        resource = source('MissionScripts/EconomySystems/Resource/spawnResourceCrate.sqf')
        self.assertIn('[{[_this select 0] call Waldo_fnc_CargoAttributesPrepareObject}, [_crate]] call CBA_fnc_execNextFrame', resource)

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
        label = source('MissionScripts/Logistics/Crates/quartermasterRearmLabelLocal.sqf')
        for cargo_type in ('Weapon', 'Magazine', 'Item', 'Backpack'):
            self.assertIn(f'clear{cargo_type}CargoGlobal _object', extended)
        self.assertIn('ace_rearm_fnc_makeSource', extended)
        self.assertIn('Waldo_fnc_QuartermasterRearmLabelLocal', extended)
        self.assertIn('missionNamespace getVariable ["ace_rearm_supply", 0]', extended)
        self.assertIn('if (_limited) then {(_configuredSupply max 1) min 100000} else {0}', extended)
        self.assertIn('ace_rearm_currentSupply', label)
        self.assertIn('Rearm supply exhausted', label)
        self.assertIn('Rearm supply: unlimited', label)
        self.assertIn('Waldo_QM_RearmInfoActionLocal', label)

    def test_zen_cargo_apply_uses_server_local_next_frame(self):
        server = source('MissionScripts/ZenModules/zenServiceLogisticsServer.sqf')
        block = server.split('case "ACE_CARGO_SET": {', 1)[1].split('\n    };', 1)[0]
        self.assertIn('CBA_fnc_execNextFrame', block)
        self.assertNotIn('] spawn {', block)
        self.assertIn('private _applied = !isNull _target && {_args call Waldo_fnc_SetCargoAttributes}', block)
        self.assertIn('"[WMP ZEN ACE CARGO] applied=%1', block)

    def test_zen_cargo_dialog_reads_live_ace_state_and_skips_unchanged_apply(self):
        dialog = source('MissionScripts/ZenModules/zenServiceLogisticsModule.sqf')
        block = dialog.split('case "ACE_CARGO": {', 1)[1]
        for key in ('ace_dragging_canDrag', 'ace_dragging_canCarry',
                    'ace_dragging_ignoreWeightDrag', 'ace_dragging_ignoreWeightCarry',
                    'ace_cargo_size', 'ace_cargo_space'):
            self.assertIn(key, block)
        self.assertNotIn('getVariable ["Waldo_CargoAttributes_Choice"', block)
        self.assertNotIn('"Change ACE cargo size"', block)
        self.assertNotIn('"Change ACE cargo space"', block)
        self.assertIn('private _setSize = _size isNotEqualTo (round _originalSize)', block)
        self.assertIn('private _setSpace = _space isNotEqualTo (round _originalSpace)', block)
        self.assertIn('if (!_setHandling && {!_setSize} && {!_setSpace}) exitWith {}', block)
        self.assertIn('["setHandling", _setHandling]', block)
        self.assertIn('_size = round _size', block)
        self.assertIn('_space = round _space', block)
        self.assertIn('[_target, _send, _choice, _size, _space]', block)
        self.assertEqual(block.count(', true]'), 6)
        server = source('MissionScripts/ZenModules/zenServiceLogisticsServer.sqf')
        self.assertIn('if (!_setHandling && {!isNull _target}) then', server)
        self.assertIn('if (_size isEqualType 0 && {_setSize isEqualType true} && {_setSize}) then {_size = round _size}', server)
        self.assertIn('if (_space isEqualType 0 && {_setSpace isEqualType true} && {_setSpace}) then {_space = round _space}', server)

    def test_spawned_crate_defaults_and_starter_exception(self):
        for path, object_name in (
            ('MissionScripts/Logistics/Crates/LogiBoxes.sqf', '_box'),
            ('MissionScripts/Logistics/Crates/quartermasterExtendedSpawn.sqf', '_object'),
            ('MissionScripts/ZenModules/ZenSpawnCrateServer.sqf', '_crate'),
            ('MissionScripts/ZenModules/Zen_loadoutSaveModule.sqf', '_target'),
            ('MissionScripts/ZenModules/RuntimeControl/featureRuntimeApply.sqf', '_hub'),
            ('MissionScripts/Logistics/FieldResupply/fieldResupplyServerHandle.sqf', '_crate'),
        ):
            # Remote-executed callers finish cargo setup from CBA's next frame, where the
            # object is passed as _this select 0 (see test_registration_leaves_remote_context).
            deferred = path.endswith(('LogiBoxes.sqf', 'quartermasterExtendedSpawn.sqf', 'ZenSpawnCrateServer.sqf',
                                      'Zen_loadoutSaveModule.sqf', 'featureRuntimeApply.sqf',
                                      'fieldResupplyServerHandle.sqf'))
            target = '_this select 0' if deferred else object_name
            self.assertIn(f'[{target}, nil, 1, true, true, true, true] call Waldo_fnc_SetCargoAttributes'
                          if path.endswith(('ZenSpawnCrateServer.sqf', 'Zen_loadoutSaveModule.sqf',
                                            'featureRuntimeApply.sqf', 'fieldResupplyServerHandle.sqf'))
                          else f'[{target}, -1, 1, true, true, true, true] call Waldo_fnc_SetCargoAttributes',
                          source(path), path)
        starter = source('MissionScripts/Logistics/Crates/doStarterCrate.sqf')
        self.assertLess(starter.index('[_target, nil, -1, false, false] call Waldo_fnc_SetCargoAttributes'),
                        starter.index('waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE"'))

    def test_registration_leaves_remote_context(self):
        # A child spawned from a client's remoteExec request keeps isRemoteExecuted, which
        # LogisticsRegisterSpawned and SetCargoAttributes reject. Every caller must hand off
        # through CBA's server-local next frame, otherwise non-crate QM issues (wheels, tracks)
        # never become physical-cargo eligible on a dedicated server.
        import pathlib, re
        root = pathlib.Path(__file__).resolve().parent.parent / 'MissionScripts'
        callers = []
        for path in root.rglob('*.sqf'):
            text = path.read_text(encoding='utf-8', errors='replace')
            if 'Waldo_fnc_LogisticsRegisterSpawned' not in text or path.name == 'logisticsRegisterSpawned.sqf':
                continue
            callers.append(path.name)
            self.assertIsNone(re.search(r'\]\s*spawn\s+Waldo_fnc_LogisticsRegisterSpawned', text), path.name)
            self.assertIn('_this spawn Waldo_fnc_LogisticsRegisterSpawned', text, path.name)
            self.assertIn('call CBA_fnc_execNextFrame', text, path.name)
        self.assertIn('LogiBoxes.sqf', callers)
        zen = source('MissionScripts/ZenModules/zenServiceLogisticsServer.sqf')
        physical = zen[zen.index('case "PHYSICAL_ENABLE"'):zen.index('case "PHYSICAL_DISABLE"')]
        self.assertIn('[{_this spawn {', physical)
        self.assertIn('}}, [_target, _replyOwner]] call CBA_fnc_execNextFrame;', physical)
        # BASE_UPSERT, BASE_REMOVE, SUPPLY_REGISTER and PHYSICAL_ENABLE call guarded registrars.
        self.assertIsNone(re.search(r'\]\s*spawn\s*\{', zen))
        self.assertEqual(zen.count('[{_this spawn {'), 4)
        logi = source('MissionScripts/Logistics/Crates/LogiBoxes.sqf')
        self.assertLess(logi.index('call Waldo_fnc_SetCargoAttributes'),
                        logi.index('_this spawn Waldo_fnc_LogisticsRegisterSpawned'))

    def test_3d_marker_joiner_forwards_do_not_rebroadcast_or_restore(self):
        # Eden Init fields run again on every JIP client and forward the same create call.
        create = source('MissionScripts/MissionFlowAndUi/create3DMarker.sqf')
        remove = source('MissionScripts/MissionFlowAndUi/remove3DMarker.sqf')
        self.assertIn('[_id, _anchor, _options, true] remoteExecCall ["Waldo_fnc_Create3DMarker", 2];', create)
        self.assertIn('if (_forwarded && {_id in _removed}) exitWith', create)
        self.assertIn('if (_index >= 0 && {(_registry select _index) isEqualTo _row}) exitWith {_id};', create)
        self.assertLess(create.index('isEqualTo _row}) exitWith'),
                        create.index('remoteExecCall ["Waldo_fnc_Marker3DApplyDeltaLocal", -2]'))
        self.assertIn('{_tombstones set [_x, true]} forEach _removedIds;', remove)

    def test_transport_menus_hidden_without_registered_transports(self):
        text = source('MissionScripts/Logistics/TransportServices/transportInteractionInitLocal.sqf')
        for action in ('Waldo_Transport_Root', 'Waldo_Transport_HelicopterRoot', 'Waldo_Transport_GroundRoot',
                       'Waldo_Transport_BoatRoot', 'Waldo_Transport_AllRoot', 'Waldo_Transport_AllHeliRtb',
                       'Waldo_Transport_AllGroundRtb', 'Waldo_Transport_AllBoatRtb'):
            line = next(l for l in text.splitlines() if f'["{action}",' in l)
            self.assertNotIn('{true}]', line, action)
            self.assertIn('Waldo_TransportService_Type', line, action)
        for label in ('Return All Helicopters to Base', 'Return All Ground Vehicles to Base', 'Return All Boats to Base'):
            line = next(l for l in text.splitlines() if 'player addAction' in l and label in l)
            self.assertIn("Waldo_TransportService_Type", line, label)

    def test_theme_font_applied_before_button_text_is_fitted(self):
        fit = source('MissionScripts/EconomySystems/Core/fitPromptDisplay.sqf')
        # Both the card and nested-group passes set the theme font before the shrink loop.
        starts = [i for i in range(len(fit)) if fit.startswith('ctrlSetFont (_theme getOrDefault ["font"', i)]
        loops = [i for i in range(len(fit)) if fit.startswith('ctrlTextWidth _x > (_newWidth', i)]
        self.assertEqual(len(starts), 2)
        self.assertEqual(len(loops), 2)
        for font, loop in zip(starts, loops):
            self.assertLess(font, loop)
        live = source('MissionScripts/MissionFlowAndUi/uiThemeApplyDisplayLocal.sqf')
        self.assertIn('Waldo_UI_BaseFontHeight', live)
        self.assertIn('ctrlTextWidth _control > (_width * 0.94)', live)

    def test_wmp_setup_paths_apply_standard_ace_handling(self):
        helper = source('MissionScripts/Logistics/Crates/logisticsApplyAceHandling.sqf')
        self.assertIn('_object isKindOf "CAManBase"', helper)
        self.assertIn('!(_object isKindOf "StaticWeapon")', helper)
        self.assertIn('true, true, true, true] call Waldo_fnc_SetCargoAttributes', helper)
        self.assertIn('class LogisticsApplyAceHandling', source('MissionScripts/WaldosFunctions.sqf'))
        for path in ('MissionScripts/Logistics/Crates/doSupplyCrate.sqf',
                     'MissionScripts/Logistics/Crates/doMedicalCrate.sqf'):
            text = source(path)
            self.assertIn('[_this select 0, 1] call Waldo_fnc_LogisticsApplyAceHandling;', text, path)
            self.assertLess(text.index('LogisticsApplyAceHandling'), text.index('_this spawn Waldo_fnc_LogisticsRegisterSpawned'))
        zen = source('MissionScripts/ZenModules/zenServiceLogisticsServer.sqf')
        for case, registrar in (('BASE_UPSERT', 'BaseServicesRegisterNode'),
                                ('SUPPLY_REGISTER', 'SupplyTransfersRegister'),
                                ('PHYSICAL_ENABLE', 'PhysicalCargoRegister')):
            block = zen[zen.index(f'case "{case}"'):]
            self.assertLess(block.index('[_target] call Waldo_fnc_LogisticsApplyAceHandling;'),
                            block.index(f'Waldo_fnc_{registrar}'), case)
            # Applied inside the deferred worker, never in the curator's remote context.
            self.assertLess(block.index('[{_this spawn {'), block.index('LogisticsApplyAceHandling'), case)

    def test_jip_replays_never_recreate_removed_state(self):
        import re
        functions = source('MissionScripts/WaldosFunctions.sqf')
        block = functions[functions.index('class ClientInitPhaseEnd'):]
        block = block[:block.index('};')]
        self.assertIn('clientInitPhaseEnd.sqf', block)
        self.assertIn('postInit = 1;', block)
        self.assertIn('missionNamespace setVariable ["Waldo_ClientInitPhaseDone", true];',
                      source('MissionScripts/Networking/clientInitPhaseEnd.sqf'))
        # The event scripts also set the flag first, so mission-maker calls there are never
        # suppressed even if postInit happens to run after them.
        for script in ('init.sqf', 'initPlayerLocal.sqf'):
            text = source(script)
            flag = text.index('missionNamespace setVariable ["Waldo_ClientInitPhaseDone", true];')
            self.assertLess(flag, text.index('/*', text.index('*/')), script)
        for path, fn in (('MissionScripts/MissionInit/Jamming/jammerCreate.sqf', 'Waldo_fnc_Jammer'),
                         ('MissionScripts/MissionInit/ElectronicWarfare/tracker.sqf', 'Waldo_fnc_Tracker'),
                         ('MissionScripts/MissionFlowAndUi/createObjective.sqf', 'Waldo_fnc_CreateObjective'),
                         ('MissionScripts/MissionFlowAndUi/notificationTrigger.sqf', 'Waldo_fnc_NotificationTrigger'),
                         ('MissionScripts/MissionFlowAndUi/create3DMarker.sqf', 'Waldo_fnc_Create3DMarker')):
            text = source(path)
            branch = text[text.index('if (!isServer) exitWith {'):]
            self.assertLess(branch.index('Waldo_ClientInitPhaseDone'), branch.index(f'"{fn}", 2]'), path)
            self.assertIn('Skipped Init-field replay', branch[:branch.index(f'"{fn}", 2]')], path)
        remove = source('MissionScripts/MissionInit/Jamming/jammerRemove.sqf')
        kept = remove[remove.index('if (!isNull _obj) then {'):remove.index('if (_deleteObject')]
        self.assertIn('_obj setVariable ["Waldo_Jamming_Id", nil, true];', kept)
        self.assertIn('remoteExec ["", _obj];', kept)

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
        self.assertIn('class=%3 maxLoad=%4', source("MissionScripts/ZenModules/zenServiceLogisticsServer.sqf"))
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

    def test_quartermaster_categories_use_distinct_icons(self):
        actions = source("MissionScripts/Logistics/Crates/initQuartermaster.sqf")
        self.assertIn('simpletasks\\types\\refuel_ca.paa', actions)
        self.assertIn('simpletasks\\types\\repair_ca.paa', actions)
        self.assertIn('military\\dot_CA.paa', actions)
        self.assertIn('"Waldo_QM_Category", "Quartermaster"', actions)
        self.assertIn('[5, [_target, _player, _boxType', actions)

    def test_merge_source_can_be_deselected_or_expire(self):
        actions = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersSetupLocal.sqf")
        result = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersResultLocal.sqf")
        config = source("MissionConfig/logisticsConfig.sqf")
        self.assertIn('WMP_SUPPLY_DESELECT', actions)
        self.assertIn('Waldo_SupplyTransfers_SourceExpiresAt', actions)
        self.assertIn('uiSleep _timeout', actions)
        self.assertIn('Waldo_SupplyTransfers_SourceExpiresAt', result)
        self.assertIn('["Waldo_SupplyTransfers_SourceTimeout", 120]', config)

    def test_zero_capacity_inventory_boxes_and_capacity_override(self):
        register = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersRegister.sqf")
        request = source("MissionScripts/Logistics/SupplyTransfers/supplyTransfersRequestServer.sqf")
        config = source("MissionConfig/logisticsConfig.sqf")
        self.assertIn('_container isKindOf "ReammoBox_F"', register)
        self.assertIn('_container setMaxLoad', register)
        self.assertIn('if (maxLoad _container <= 0) exitWith {false}', register)
        self.assertIn('Waldo_SupplyTransfers_IgnoreCapacity', request)
        self.assertIn('destination snapshot rebuild mismatch', request)
        self.assertIn('["Waldo_SupplyTransfers_EmptyCrateCapacity", 400]', config)

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
