"""Static integration checks for the ACE carried-crate release adapter.

These checks cover routing and authority, not Arma interaction or vehicle geometry.
"""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
FEATURE = ROOT / "MissionScripts" / "Logistics" / "PhysicalCargo"


class PhysicalCargoSourceTests(unittest.TestCase):
    def read(self, name: str) -> str:
        return (FEATURE / name).read_text(encoding="utf-8")

    def test_native_release_is_replaced_only_after_replacement_exists(self):
        source = self.read("physicalCargoInitLocal.sqf")
        self.assertIn('"ace_dragging_startedCarry"', source)
        self.assertIn('"ace_dragging_releaseActionID"', source)
        self.assertLess(source.index('if (_wmpID < 0)'), source.index('[_unit, "DefaultAction", _aceID]'))
        self.assertNotIn('"ace_dragging_stoppedCarry"', source)

    def test_carry_permissions_reach_clients_and_jip(self):
        helper = (ROOT / "MissionScripts" / "MissionInit" / "VehicleActionsSetup"
                  / "SetCargoAttributes.sqf").read_text(encoding="utf-8")
        register = self.read("physicalCargoRegister.sqf")
        self.assertIn('"ace_dragging_dragPosition", [0, 1.5, 0]', helper)
        self.assertIn('"ace_dragging_carryPosition", [0, 1, 1]', helper)
        self.assertIn('false, true]', helper)
        self.assertIn('"ace_dragging_carryPosition", [0, 1, 1]', register)
        self.assertIn('false, true]', register)
        self.assertIn('"Waldo_CargoAttributes_CarryablePublished", _carryable', helper)
        self.assertIn('if (!(_object getVariable ["Waldo_CargoAttributes_CarryablePublished", false])', register)

    def test_release_drops_through_ace_without_native_cargo_attempt(self):
        source = self.read("physicalCargoReleaseLocal.sqf")
        self.assertIn('[_carrier, _cargo, false] call ace_dragging_fnc_dropObject_carry;', source)
        self.assertIn('"Waldo_fnc_PhysicalCargoAttachServer", 2', source)
        self.assertNotIn('ace_cargo_fnc_loadItem', source)

    def test_server_validates_request_and_publishes_mount(self):
        source = self.read("physicalCargoAttachServer.sqf")
        self.assertIn('remoteExecutedOwner isNotEqualTo owner _carrier', source)
        self.assertIn('boundingBoxReal _vehicle', source)
        self.assertIn('"Waldo_PhysicalCargo_AttachedVehicle", _vehicle, true', source)
        self.assertIn('enableSimulationGlobal false', source)
        self.assertNotIn('Waldo_PhysicalCargo_WorkingWeapons', source)
        self.assertIn('"Waldo_PhysicalCargo_Mode", "CARGO"', source)
        self.assertIn('(getPhysicsCollisionFlag _cargo) param [0, true]', source)
        self.assertIn('_carrier distance (_vehicle modelToWorld _offset)', source)
        self.assertNotIn('_carrier distance _vehicle > 6', source)
        self.assertNotIn('_cargo distance _vehicle > 7', source)

    def test_unload_restores_physics_after_owner_placement(self):
        clear = self.read("physicalCargoClearServer.sqf")
        restore = self.read("physicalCargoRestoreLocal.sqf")
        ack = self.read("physicalCargoRestoreAckServer.sqf")
        self.assertIn('Waldo_PhysicalCargo_RestorePending', clear)
        self.assertIn('Waldo_fnc_PhysicalCargoRestoreAckServer', restore)
        self.assertLess(restore.index('_cargo setPosATL _dropPosition'),
                        restore.index('Waldo_fnc_PhysicalCargoRestoreAckServer'))
        self.assertIn('if (!isNull attachedTo _cargo) exitWith {false}', ack)
        self.assertIn('_cargo enableSimulationGlobal _priorSimulation', ack)

    def test_mount_preserves_carried_pose_without_bbox_reposition(self):
        release = self.read("physicalCargoReleaseLocal.sqf")
        self.assertIn('ASLToAGL getPosWorld _cargo', release)
        self.assertIn('_vehicle worldToModel _heldPosition', release)
        self.assertIn('vectorDir _cargo', release)
        self.assertNotIn('boundingBoxReal _cargo', release)

    def test_working_weapon_actions_removed(self):
        apply = self.read("physicalCargoApplyLocal.sqf")
        actions = self.read("physicalCargoInitLocal.sqf")
        self.assertIn('vectorNormalized _relativeDir', apply)
        self.assertIn('vectorNormalized _relativeUp', apply)
        self.assertNotIn('"Mount as working weapon"', actions)
        self.assertNotIn('"Enter mounted weapon"', actions)
        self.assertNotIn('ace_interact_menu_fnc_addActionToClass', actions)
        self.assertNotIn('Unload physical cargo', actions)

    def test_static_weapons_never_enter_wmp_mount_path(self):
        register = self.read("physicalCargoRegister.sqf")
        local = self.read("physicalCargoInitLocal.sqf")
        release = self.read("physicalCargoReleaseLocal.sqf")
        server = self.read("physicalCargoAttachServer.sqf")
        for source in (register, local, release, server):
            self.assertIn('isKindOf "StaticWeapon"', source)
        self.assertIn('"Waldo_PhysicalCargo_Eligible", false, true', register)

    def test_verified_ffv_seats_use_separate_owned_turret_locks(self):
        seats = self.read("physicalCargoSeatsServer.sqf")
        attach = self.read("physicalCargoAttachServer.sqf")
        self.assertIn('fullCrew [_vehicle, "", true]', seats)
        self.assertIn('"TURRET"', seats)
        self.assertIn('Waldo_PhysicalCargo_TurretLocks', seats)
        self.assertIn('_vehicle lockTurret [_key, true]', seats)
        self.assertIn('_vehicle lockTurret [_path, false]', seats)
        self.assertIn('_delta vectorDotProduct _right', seats)
        self.assertIn('_delta vectorDotProduct _forward', seats)
        self.assertIn('_delta vectorDotProduct _up', seats)
        self.assertNotIn('_radius', seats)
        self.assertIn('0.2 min (((_maximum select _axis) - (_minimum select _axis)) * 0.2)', seats)
        self.assertIn('true, _offset, _relativeDir, _relativeUp', attach)

    def test_audit_station_measures_real_cargo_and_ffv_seats(self):
        station = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit"
                   / "WMP_FPA.VR" / "serviceLogisticsStationsServer.sqf").read_text(encoding="utf-8")
        self.assertIn('Waldo_QA_fnc_calibrateCargoSeatsServer', station)
        self.assertIn('_probe moveInCargo [_vehicle, _index]', station)
        self.assertIn('_probe moveInTurret [_vehicle, _path]', station)
        self.assertIn('(_x select 0) isEqualTo _probe', station)
        self.assertIn('"Waldo_PhysicalCargo_SeatPoints", _points, true', station)

    def test_init_and_config_routes_are_present(self):
        self.assertIn('Waldo_fnc_PhysicalCargoInitLocal', (ROOT / "initPlayerLocal.sqf").read_text(encoding="utf-8"))
        self.assertIn('Waldo_fnc_PhysicalCargoInitServer', (ROOT / "initServer.sqf").read_text(encoding="utf-8"))
        self.assertIn('"Waldo_PhysicalCargo_Enable", true', (ROOT / "MissionConfig" / "logisticsConfig.sqf").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
