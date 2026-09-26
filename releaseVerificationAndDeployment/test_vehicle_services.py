"""Source integration contracts for ACE vehicle services; no Arma runtime simulation."""
from pathlib import Path
import json
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]

def source(path):
    return (ROOT / path).read_text(encoding="utf-8")

class VehicleServicesTests(unittest.TestCase):
    def setUp(self):
        self.api = source("MissionScripts/Logistics/VehicleServices/vehicleServicesConfigure.sqf")
        self.apply = source("MissionScripts/Logistics/VehicleServices/vehicleServicesApplyServer.sqf")
        self.dialog = source("MissionScripts/ZenModules/zenVehicleServicesModule.sqf")
        self.bridge = source("MissionScripts/ZenModules/zenVehicleServicesServer.sqf")

    def test_every_dialog_option_has_a_server_consumer(self):
        for key in ("rearm", "refuel", "repair", "medical", "fuelLitres", "rearmSupply", "refillFuel", "refillRearm"):
            with self.subTest(key=key):
                self.assertIn('"' + key + '"', self.dialog)
                self.assertRegex(self.apply, r'(?:getOrDefault \[|get )"' + key + '"')
        self.assertIn('if (_choice != "KEEP")', self.dialog)
        self.assertIn('[["rearm", _rearm], ["refuel", _refuel], ["repair", _repair], ["medical", _medical]]', self.dialog)

    def test_curator_authentication_precedes_clean_context_dispatch(self):
        for token in ("remoteExecutedOwner", "owner _curator != _replyOwner", "isNull getAssignedCuratorLogic _curator"):
            self.assertIn(token, self.bridge)
        self.assertLess(self.bridge.index("owner _curator != _replyOwner"), self.bridge.index("call Waldo_fnc_VehicleServicesConfigure"))
        self.assertIn("CBA_fnc_execNextFrame", self.bridge)
        self.assertIn("isRemoteExecuted", self.api)
        self.assertIn("isRemoteExecuted", self.apply)

    def test_role_edits_do_not_implicitly_refill(self):
        self.assertIn("if (!_fuelWas || {_refillFuel}) then", self.apply)
        self.assertIn("if (!_rearmWas || {_refillRearm}) then", self.apply)
        self.assertIn('["refillFuel", false]', self.apply)
        self.assertIn('["refillRearm", false]', self.apply)
        self.assertIn("Waldo_VehicleServices_SavedFuel", self.apply)
        self.assertIn("Waldo_VehicleServices_SavedRearm", self.apply)
        self.assertIn("if (_fuelCapacity == -10) then {-10}", self.apply)

    def test_disable_overrides_native_service_classes_without_duplicate_fuel_actions(self):
        self.assertIn('["ace_rearm_currentSupply", -1, true]', self.apply)
        self.assertIn('["ace_rearm_isSupplyVehicle", false, true]', self.apply)
        self.assertIn('["ace_refuel_capacity", -1, true]', self.apply)
        self.assertIn("Waldo_VehicleServices_FuelInitialized", self.apply)
        self.assertNotIn("call ace_refuel_fnc_initSource", self.apply)
        self.assertNotIn("removeGlobalEventJIP", self.apply)

    def test_reenable_replays_rearm_actions_for_clients_who_joined_while_disabled(self):
        self.assertIn('if (!_rearmWas) then', self.apply)
        self.assertIn('["ace_rearm_initSupplyVehicle", [_vehicle]] call CBA_fnc_globalEvent', self.apply)
        self.assertLess(self.apply.index('call ace_rearm_fnc_makeSource'), self.apply.index('["ace_rearm_initSupplyVehicle"'))

    def test_whole_request_and_dependencies_validated_before_role_writes(self):
        write = self.apply.index('setVariable ["ace_refuel_capacity"')
        for token in ("_key in _keys", "!finite _value", "_value > 1000000", "_missing isNotEqualTo []", "ace_refuel_isConnected", "Magazine-based mode is not supported"):
            self.assertLess(self.apply.index(token), write)
        self.assertNotIn("call ace_refuel_fnc_getCapacity", self.apply)

    def test_eden_queue_preserves_order_and_is_bounded(self):
        for token in ("_queue pushBack [_pairs, _replyOwner]", "diag_tickTime + 60", "ace_common_settingsInitFinished", "isNil {", "Waldo_VehicleServices_LastResult", "Waldo_VehicleServices_Ready"):
            self.assertIn(token, self.api)
        self.assertNotIn("addPerFrameHandler", self.api + self.apply)
        self.assertNotIn("spawn Waldo_fnc_VehicleServicesConfigure", self.api)

    def test_exact_vehicle_required_and_gameplay_state_preserved(self):
        for text in (self.dialog, self.api, self.apply):
            for kind in ("LandVehicle", "Air", "Ship", "StaticWeapon"):
                self.assertIn('"' + kind + '"', text)
        for forbidden in ("nearestObjects", "createVehicle", "setOwner", "enableSimulation", "clearItemCargo", "setDamage", "setFuel 1", "setVehicleAmmo"):
            self.assertNotIn(forbidden, self.dialog + self.api + self.apply)

    def test_jip_cannot_overwrite_explicit_medical_choice(self):
        auto = source("MissionScripts/MissionInit/VehicleActionsSetup/AddVehicleFunctions.sqf")
        assignments = auto.count('setVariable ["ace_medical_isMedicalVehicle", true, true]')
        self.assertEqual(assignments, 4)
        self.assertEqual(auto.count('if (isServer && {isNil {_vehicle getVariable "ace_medical_isMedicalVehicle"}})'), assignments)

    def test_registered_documented_and_staged_for_real_vehicle_qa(self):
        functions = source("MissionScripts/WaldosFunctions.sqf")
        for name in ("VehicleServicesConfigure", "VehicleServicesApplyServer", "ZenVehicleServicesModule", "ZenVehicleServicesServer"):
            self.assertIn("class " + name, functions)
        records = json.loads(source("releaseVerificationAndDeployment/zeus_script_parity.json"))
        self.assertTrue(any(row["module"] == "ACE Vehicle Services - Configure" for row in records))
        fixture = source("releaseVerificationAndDeployment/fullArmaAudit/WMP_FPA.VR/serviceLogisticsStationsServer.sqf")
        self.assertIn("call Waldo_fnc_VehicleServicesConfigure", fixture)
        self.assertIn("_transferVehicle enableSimulationGlobal true", fixture)
        self.assertIn("ACE-Vehicle-Services", source("wiki/Feature-Tutorials.md"))

if __name__ == "__main__":
    unittest.main()
