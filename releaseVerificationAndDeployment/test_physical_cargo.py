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
        self.assertIn('ACE pickup requests mount clear', source)
        self.assertIn('"Waldo_PhysicalCargo_Mounts"', source)

    def test_carry_permissions_reach_clients_and_jip(self):
        helper = (ROOT / "MissionScripts" / "MissionInit" / "VehicleActionsSetup"
                  / "SetCargoAttributes.sqf").read_text(encoding="utf-8")
        register = self.read("physicalCargoRegister.sqf")
        self.assertIn('"Waldo_CargoAttributes_Choice", _choice, true', helper)
        self.assertIn('call ace_dragging_fnc_setDraggable', helper)
        self.assertIn('call ace_dragging_fnc_setCarryable', helper)
        self.assertIn('_ignoreDrag, true]', helper)
        self.assertIn('_ignoreCarry, true]', helper)
        self.assertIn('time > 0', helper)
        self.assertIn('if (count _this <= 3) then {_draggable = _portable}', helper)
        self.assertIn('if (count _this <= 4) then {_carryable = _portable}', helper)
        self.assertNotIn('remoteExecCall ["Waldo_fnc_CargoAttributesApplyLocal", 0]', helper)
        self.assertNotIn('remoteExecCall ["Waldo_fnc_CargoAttributesRequestServer", 2]',
                         (ROOT / "initPlayerLocal.sqf").read_text(encoding="utf-8"))
        self.assertIn('[_object] call Waldo_fnc_CargoAttributesPrepareObject', register)
        self.assertLess(register.index('call Waldo_fnc_CargoAttributesPrepareObject'),
                        register.index('"Waldo_PhysicalCargo_Eligible", true, true'))
        init_server = self.read("physicalCargoInitServer.sqf")
        self.assertIn('entities "ReammoBox_F"', init_server)
        self.assertIn('_x getVariable ["Waldo_PhysicalCargo_Eligible", true]', init_server)
        self.assertIn('[_x] call Waldo_fnc_PhysicalCargoRegister', init_server)
        self.assertIn('addMissionEventHandler ["EntityDeleted"', init_server)
        self.assertIn('[_cargo, _vehicle, false] call Waldo_fnc_PhysicalCargoSeatsServer', init_server)
        self.assertIn('}, 3] call CBA_fnc_addPerFrameHandler', init_server)
        load_handler = init_server.split('private _id = ["ace_cargoLoaded", {', 1)[1].split('missionNamespace setVariable ["Waldo_PhysicalCargo_CargoLoadedEH"', 1)[0]
        self.assertIn('CBA_fnc_execNextFrame', load_handler)
        self.assertIn('[_cargo] call Waldo_fnc_PhysicalCargoClearServer', load_handler)
        self.assertIn('"Waldo_PhysicalCargo_AttachedVehicle"', load_handler)
        audit = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "WMP_FPA.VR"
                 / "serviceLogisticsStationsServer.sqf").read_text(encoding="utf-8")
        self.assertIn('_seatControl setVariable ["Waldo_PhysicalCargo_Eligible", false, true]', audit)

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
        self.assertIn('Cargo mounted. Use ACE Carry', source)

    def test_quartermaster_spares_enter_physical_carry_path(self):
        register = (ROOT / "MissionScripts" / "Logistics" / "Crates"
                    / "logisticsRegisterSpawned.sqf").read_text(encoding="utf-8")
        self.assertIn('"FUELBARREL", "FUELJERRYCAN", "TRACK", "WHEEL", "SPARE", "STARTER"', register)
        self.assertIn('[_object] call Waldo_fnc_PhysicalCargoRegister', register)
        # Every issued role is mountable: no role allow-list gates physical cargo any more.
        physical = register[register.index('Waldo_PhysicalCargo_Enable'):register.index('Waldo_SupplyTransfers_Enable')]
        self.assertNotIn('_role in', physical)

    def test_single_eligibility_rule_is_broad_and_shared(self):
        rule = self.read("physicalCargoIsEligible.sqf")
        for kind in ('"CAManBase"', '"StaticWeapon"', '"LandVehicle"', '"Air"', '"Ship"'):
            self.assertIn(f'isKindOf {kind}', rule)
        self.assertIn('_object getVariable ["Waldo_PhysicalCargo_Eligible", true]', rule)
        self.assertNotIn('ReammoBox_F', rule)
        self.assertIn('Waldo_Logistics_StarterCrate', rule)
        for source in (self.read("physicalCargoInitLocal.sqf"), self.read("physicalCargoAttachServer.sqf"),
                       (ROOT / "MissionScripts" / "ZenModules" / "zenServiceLogisticsModule.sqf").read_text(encoding="utf-8"),
                       (ROOT / "MissionScripts" / "ZenModules" / "zenServiceLogisticsServer.sqf").read_text(encoding="utf-8")):
            self.assertIn('call Waldo_fnc_PhysicalCargoIsEligible', source)
            self.assertNotIn('_isKindOf "ReammoBox_F"]', source)
        functions = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
        self.assertIn('class PhysicalCargoIsEligible', functions)

    def test_mount_mass_recovery_uses_owner_acknowledgement(self):
        release = self.read("physicalCargoReleaseLocal.sqf")
        attach = self.read("physicalCargoAttachServer.sqf")
        clear = self.read("physicalCargoClearServer.sqf")
        ack = self.read("physicalCargoRestoreAckServer.sqf")
        drop = release.index('call ace_dragging_fnc_dropObject_carry')
        # ACE's mass restore is suppressed before its drop, and the object is attached right after.
        self.assertLess(release.index('_cargo setVariable ["ace_dragging_originalMass", 0, true]'), drop)
        self.assertLess(drop, release.index('_cargo attachTo [_vehicle, _offset]'))
        self.assertLess(release.index('_cargo attachTo [_vehicle, _offset]'),
                        release.index('Waldo_fnc_PhysicalCargoAttachServer'))
        # A rejected mount is detached and moved clear before its mass returns.
        reject = attach[attach.index('private _reject'):attach.index('private _bounds')]
        self.assertNotIn('ace_common_setMass', reject)
        self.assertIn('if (_clear isEqualTo []) exitWith', reject)
        self.assertIn('Waldo_PhysicalCargo_RestorePending', reject)
        self.assertIn('Waldo_fnc_PhysicalCargoRestoreLocal', reject)
        self.assertIn('CBA_fnc_execNextFrame', attach)
        recovery = attach[attach.index('// The recovery worker'):]
        self.assertNotIn('call Waldo_fnc_PhysicalCargoClearServer', recovery)
        self.assertIn('private _released =', recovery)
        self.assertIn('Waldo_fnc_PhysicalCargoUnmountServer', attach)
        # Mass returns to ACE on pickup, or after the safe set-down is acknowledged.
        self.assertIn('_cargo setVariable ["ace_dragging_originalMass", _mass, true]', clear)
        self.assertIn('Waldo_PhysicalCargo_RestoreMass', clear)
        self.assertLess(ack.index('_cargo enableSimulationGlobal _priorSimulation'), ack.index('ace_common_setMass'))

    def test_provisional_attachment_is_not_an_owner_acknowledgement(self):
        apply = self.read("physicalCargoApplyLocal.sqf")
        attach = self.read("physicalCargoAttachServer.sqf")
        owner = apply.split('if (local _cargo) then {', 1)[1]
        self.assertLess(owner.index('setVectorDirAndUp'), owner.index('"Waldo_PhysicalCargo_OwnerAppliedRevision"'))
        self.assertEqual(attach.count('"Waldo_PhysicalCargo_OwnerAppliedRevision", -1'), 3)

    def test_old_mount_worker_cannot_recover_a_later_mount(self):
        attach = self.read("physicalCargoAttachServer.sqf")
        clear = self.read("physicalCargoClearServer.sqf")
        self.assertIn('"Waldo_PhysicalCargo_ServerMountRevision", _revision', attach)
        self.assertEqual(attach.count('"Waldo_PhysicalCargo_ServerMountRevision", -1'), 2)
        self.assertIn('"Waldo_PhysicalCargo_ServerMountRevision", nil', clear)

    def test_pickup_recovers_mass_before_server_clear_request(self):
        pickup = self.read("physicalCargoInitLocal.sqf")
        self.assertLess(pickup.index('"ace_dragging_originalMass", _savedMass'),
                        pickup.index('remoteExecCall ["Waldo_fnc_PhysicalCargoClearServer"'))

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
        rule = self.read("physicalCargoIsEligible.sqf")
        release = self.read("physicalCargoReleaseLocal.sqf")
        for source in (register, rule, release):
            self.assertIn('isKindOf "StaticWeapon"', source)
        # The carry hook and server mount check both go through the shared rule.
        for name in ("physicalCargoInitLocal.sqf", "physicalCargoAttachServer.sqf"):
            self.assertIn('call Waldo_fnc_PhysicalCargoIsEligible', self.read(name))
        self.assertIn('"Waldo_PhysicalCargo_Eligible", false, true', register)

    def test_verified_ffv_seats_use_separate_owned_turret_locks(self):
        seats = self.read("physicalCargoSeatsServer.sqf")
        attach = self.read("physicalCargoAttachServer.sqf")
        self.assertIn('fullCrew [_vehicle, "", true]', seats)
        self.assertIn('"TURRET"', seats)
        self.assertIn('Waldo_PhysicalCargo_TurretLocks', seats)
        owner = self.read("physicalCargoSeatLockLocal.sqf")
        self.assertIn('remoteExecCall ["Waldo_fnc_PhysicalCargoSeatLockLocal", _vehicle]', seats)
        self.assertIn('remoteExecutedOwner isNotEqualTo 2', owner)
        self.assertIn('!local _vehicle', owner)
        self.assertIn('_vehicle lockTurret [_key, _lock]', owner)
        monitor = self.read("physicalCargoInitServer.sqf")
        self.assertIn('Waldo_PhysicalCargo_SeatAttempts', monitor)
        self.assertIn('if (_tries < 3)', monitor)
        self.assertIn('remoteExecCall ["Waldo_fnc_PhysicalCargoSeatLockLocal", _vehicle]', monitor)
        self.assertIn('_delta vectorDotProduct _right', seats)
        self.assertIn('_delta vectorDotProduct _forward', seats)
        self.assertIn('_delta vectorDotProduct _up', seats)
        self.assertNotIn('_radius', seats)
        self.assertIn('0.2 min (((_maximum select _axis) - (_minimum select _axis)) * 0.2)', seats)
        self.assertIn('true, _offset, _relativeDir, _relativeUp', attach)

    def test_audit_station_measures_real_cargo_and_ffv_seats(self):
        station = (ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit"
                   / "WMP_FPA.VR" / "serviceLogisticsStationsServer.sqf").read_text(encoding="utf-8")
        self.assertIn('Waldo_QA_fnc_reportCargoSeatsServer', station)
        self.assertIn('Waldo_QA_fnc_captureCargoSeatServer', station)
        self.assertNotIn('_probe moveInCargo', station)
        self.assertNotIn('_probe moveInTurret', station)
        self.assertIn('"Waldo_PhysicalCargo_SeatPoints", _points]', station)

    def test_mount_deltas_replace_public_whole_registry(self):
        attach = self.read("physicalCargoAttachServer.sqf")
        clear = self.read("physicalCargoClearServer.sqf")
        snapshot = self.read("physicalCargoReceiveStateLocal.sqf")
        apply = self.read("physicalCargoApplyLocal.sqf")
        restore = self.read("physicalCargoRestoreLocal.sqf")
        for source in (attach, clear):
            self.assertNotIn('"Waldo_PhysicalCargo_Mounts", _mounts, true', source)
            self.assertIn('"Waldo_PhysicalCargo_MountRevision"', source)
        self.assertIn('"Waldo_PhysicalCargo_LocalRevision"', snapshot)
        self.assertIn('"Waldo_PhysicalCargo_LocalMountRevision"', apply)
        self.assertIn('"Waldo_PhysicalCargo_LocalMountRevision"', restore)
        self.assertIn('"Waldo_PhysicalCargo_Mounts", _mounts', apply)
        self.assertIn('"Waldo_PhysicalCargo_Mounts",', restore)
        request = self.read("physicalCargoRequestStateServer.sqf")
        shared_init = (ROOT / "init.sqf").read_text(encoding="utf-8")
        self.assertIn('remoteExecutedOwner isNotEqualTo _target', request)
        self.assertIn('[clientOwner] remoteExecCall ["Waldo_fnc_PhysicalCargoRequestStateServer", 2]', shared_init)

    def test_server_only_bookkeeping_is_not_broadcast(self):
        seats = self.read("physicalCargoSeatsServer.sqf")
        attach = self.read("physicalCargoAttachServer.sqf")
        clear = self.read("physicalCargoClearServer.sqf")
        self.assertIn('"Waldo_PhysicalCargo_SeatLocks", _locks]', seats)
        self.assertIn('"Waldo_PhysicalCargo_TurretLocks", _turretLocks]', seats)
        self.assertNotIn('"Waldo_PhysicalCargo_SeatLocks", _locks, true', seats)
        self.assertNotIn('"Waldo_PhysicalCargo_TurretLocks", _turretLocks, true', seats)
        self.assertNotIn('"Waldo_PhysicalCargo_PreviousSimulation", simulationEnabled _cargo, true', attach)
        self.assertNotIn('"Waldo_PhysicalCargo_RestoreSerial", _restoreToken, true', clear)

    def test_init_and_config_routes_are_present(self):
        self.assertIn('Waldo_fnc_PhysicalCargoInitLocal', (ROOT / "initPlayerLocal.sqf").read_text(encoding="utf-8"))
        self.assertIn('Waldo_fnc_PhysicalCargoInitServer', (ROOT / "initServer.sqf").read_text(encoding="utf-8"))
        self.assertIn('"Waldo_PhysicalCargo_Enable", true', (ROOT / "MissionConfig" / "logisticsConfig.sqf").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
