"""Static integration contracts; these checks do not simulate Arma or prove runtime behaviour."""
from pathlib import Path
import re
import unittest
ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'MissionScripts/AiScripting/Cortex'
def src(name):
    return re.sub(r'^/\*.*?\*/\s*', '', (BASE / (name+'.sqf')).read_text(encoding='utf-8-sig'), flags=re.S)
class AIModularityContracts(unittest.TestCase):
    def test_child_switches_are_configured_validated_and_replayed(self):
        config = (ROOT/'MissionConfig/aiConfig.sqf').read_text(encoding='utf-8')
        spec = src('cortexTuningSpec')
        names = ['VehicleDismount','VehicleRemount','VehicleWithdraw','CoverValidation','Hearing']
        names = ['Waldo_AIPass_'+n+'_Enable' for n in names] + ['Waldo_Convoy_'+n+'_Enable' for n in ['MountedFire','Cover','AvoidInfantry','ContactHalt','Unload']]
        for name in names:
            self.assertIn('"'+name+'"',config)
            self.assertEqual(spec.count('"'+name+'"'),1)
        self.assertIn('Waldo_fnc_CortexTuningSpec',src('cortexControlOpenLocal'))
        for path in ['featureRuntimeRequestState']:
            self.assertIn('Waldo_fnc_CortexTuningSpec',(ROOT/'MissionScripts/ZenModules/RuntimeControl'/f'{path}.sqf').read_text(encoding='utf-8'))
        self.assertIn('"CHECKBOX"',src('cortexTuning'))
    def test_group_opt_out_cannot_enable_a_global_switch(self):
        gate = src('cortexFeatureEnabled')
        self.assertLess(gate.index('missionNamespace getVariable'),gate.index('Waldo_AIPass_DisabledFeatures'))
        self.assertIn('Waldo_AI_ExternalControl',src('cortexIsEligible'))
        self.assertIn('Waldo_fnc_CortexFeatureEnabled',src('cortexFlankStep'))
        self.assertIn('Waldo_fnc_CortexFeatureEnabled',src('cortexRegroupStep'))
    def test_capability_is_live_ammo_not_exclusive_role(self):
        text = src('cortexCapabilities')
        self.assertIn('magazinesAmmoFull _unit',text)
        self.assertIn('_rounds > 0',text)
        self.assertIn('_magazine in _compatible',text)
        self.assertIn('/ 256',text)
        self.assertIn('/ 512',text)
        self.assertNotIn('leader group',text)
        for name in ['cortexAntiArmour','cortexMorale','cortexSupportApply']:
            self.assertIn('Waldo_fnc_CortexCapabilities',src(name))
    def test_passengers_share_safety_checks_and_cleanup_does_not_board(self):
        text = src('cortexPassengerReady')
        for check in ['local _unit','isPlayer','Waldo_fnc_CortexCombatEffective','abs speed _vehicle','surfaceIsWater','lineIntersectsSurfaces','fullCrew','emptyPositions']:
            self.assertIn(check,text)
        for name in ['cortexVehicles','cortexRestoreCalm']:
            self.assertIn('Waldo_fnc_CortexPassengerReady',src(name))
        for name in ['cortexReleaseGroup','cortexLocality']:
            self.assertIn('false] call Waldo_fnc_CortexRestoreCalm',src(name))
    def test_report_transport_contains_positions_not_enemy_objects(self):
        report = src('cortexContactReport')
        self.assertIn('+(_x select 1)',report)
        self.assertIn('serverTime - (_x select 2)',report)
        for name in ['cortexReportServer','cortexReportLocal']:
            text = src(name)
            self.assertNotIn(' reveal ',text)
            self.assertIn('Waldo_fnc_CortexFeatureEnabled',text)
            self.assertIn('serverTime',text)
        self.assertIn('groupOwner _receiver',src('cortexReportServer'))
        self.assertIn('from 1 to 8',src('cortexReportServer'))
    def test_support_reserves_before_dispatch_and_checks_owner_ack(self):
        step = src('cortexSupportStep')
        reservation = step.index('setVariable ["Waldo_AIPass_SupportLease",_lease,true]')
        self.assertLess(reservation,step.index('remoteExecCall ["Waldo_fnc_CortexSupportLocal",groupOwner'))
        self.assertIn('groupOwner _helper != _owner',step)
        self.assertIn('from 1 to 8',step)
        ack = src('cortexSupportAck')
        self.assertIn('[_replyOwner,groupOwner _group] call Waldo_fnc_HeadlessResolveSender',ack)
        self.assertIn('_lease isNotEqualTo _snapshot',ack)
        self.assertLess(ack.index('(_lease select 0) != _token'),ack.index('set [4,'))
    def test_support_waits_for_snapshot_and_revalidates_before_moving(self):
        text = src('cortexSupportApply')
        move = text.index('call Waldo_fnc_CortexGroupMove')
        for check in ['_current isNotEqualTo _lease','serverTime < _expiry','Waldo_fnc_CortexIsEligible','Waldo_fnc_CortexCapabilities','Waldo_AIPass_Garrison','Waldo_AIPass_Defend','artilleryScanner']:
            self.assertLess(text.index(check),move)
        self.assertIn('Waldo_AIPass_SupportRequests',src('cortexStop'))
        self.assertIn('Waldo_fnc_CortexGroupMoveClear',src('cortexSupportMaintain'))
    def test_assault_uses_existing_reservations_across_owners(self):
        text = src('cortexSupportAssaultServer')
        for contract in ['[_replyOwner,groupOwner _requester] call Waldo_fnc_HeadlessResolveSender','assaultIssued','Waldo_AIPass_SupportStatus','Waldo_AIPass_CoordinatedAssault_Enable','groupOwner _helper']:
            self.assertIn(contract,text)
        self.assertNotIn('local _x',src('cortexCoordinatedAssault'))
    def test_hearing_is_optional_bounded_and_cleaned(self):
        text = src('cortexHearingLocal')
        self.assertIn('"FiredNear"',text)
        self.assertIn('removeEventHandler',text)
        self.assertIn('serverTime+20',text)
        self.assertIn('50*round',text)
        self.assertNotIn(' reveal ',text)
        self.assertNotIn('allGroups',text)
        self.assertNotIn('allUnits',text)
        self.assertIn('Waldo_fnc_CortexHearingLocal',src('cortexStop'))
        self.assertIn('Waldo_fnc_CortexHearingLocal',src('cortexLocality'))
    def test_cover_and_infantry_checks_are_bounded(self):
        cover = src('cortexFindCover')
        for value in ['_objects resize 10','min 25','surfaceNormal','GEOM','Waldo_AIPass_CoverValidation_Enable']:
            self.assertIn(value,cover)
        drive = src('cortexInfantrySpeed')
        self.assertIn('count _people > 32',drive)
        self.assertIn('min 30',drive)
        self.assertNotIn('doMove',drive)
        self.assertNotIn('forceSpeed',drive)
    def test_convoy_checks_each_crew_and_passenger_group(self):
        text = (ROOT/'MissionScripts/AiScripting/convoyCrewLocal.sqf').read_text(encoding='utf-8')
        for feature in ['MountedFire','Unload','Cover']:
            self.assertIn('[group _unit,"Waldo_Convoy_'+feature+'_Enable",true]',text)
        for contract in ['fullCrew','_seats set','_unit doTarget _enemy','Waldo_fnc_CortexPassengerReady']:
            self.assertIn(contract,text)
    def test_disable_cleans_stance_targeting_and_pending_automatic_drop(self):
        tick = src('cortexGroupTick')
        for contract in ['Waldo_AIPass_Stance_Enable','setUnitPos "AUTO"','Waldo_AIPass_VehicleTarget','doTarget objNull']:
            self.assertIn(contract,tick)
        self.assertIn('Waldo_AIPass_Airborne_Enable',src('cortexAirborneDropStep'))
        self.assertIn('"forced", _force',src('cortexAirborneCheck'))
    def test_artillery_rechecks_actual_rounds(self):
        for name in ['cortexArtilleryAmmo','cortexArtilleryShot']:
            self.assertIn('magazinesAllTurrets',src(name))
            self.assertIn('(_x select 2) > 0',src(name))
        self.assertIn('Waldo_fnc_CortexFeatureEnabled',src('cortexArtilleryShot'))
if __name__ == '__main__': unittest.main()
