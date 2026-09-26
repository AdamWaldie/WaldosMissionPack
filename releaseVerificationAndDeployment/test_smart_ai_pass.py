"""Static regression contracts for PR 151; these do not execute SQF or prove engine behaviour."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'MissionScripts' / 'AiScripting' / 'SmartAIPass'

def source(name):
    return re.sub(r'^/\*.*?\*/\s*', '', (BASE / f'{name}.sqf').read_text(encoding='utf-8-sig'), flags=re.S)

class SmartAIPassContracts(unittest.TestCase):
    def test_curator_payloads_are_not_conflated(self):
        text = source('aiPassZeusWatchLocal')
        self.assertIn('forEach ["CuratorWaypointPlaced", "CuratorWaypointEdited"]', text)
        self.assertNotIn('["CuratorWaypointEdited", "CuratorWaypointDeleted"]', text)
        self.assertIn('params ["", "_group"]', text)
        self.assertIn('_waypoint select 0', text)

    def test_orders_gate_players_and_other_features_before_side_effects(self):
        for name, effect in [('aiPassGarrison', 'call lambs_wp_fnc_taskGarrison'),
                             ('aiPassDefend', '_x setVariable ["Waldo_AIPass_DefendPos"'),
                             ('aiPassClearBuilding', 'spawn lambs_wp_fnc_taskCQB')]:
            with self.subTest(name=name):
                text = source(name)
                self.assertLess(text.index('call Waldo_fnc_AIPassIsEligible'), text.index(effect))
        self.assertIn('[_group] call _isFeatureOwned', source('aiPassIsEligible'))

    def test_fire_revalidates_after_queue_and_dispersion(self):
        text = source('aiPassArtilleryFire')
        shot = text.index('_battery doArtilleryFire')
        for gate in ['call Waldo_fnc_AIPassIsEligible', 'call Waldo_fnc_AIPassArtilleryRole',
                     'Waldo_AIPass_CounterBattery_Enable', '_aim nearEntities', 'crew _entity']:
            self.assertLess(text.index(gate), shot)
        self.assertLess(text.index('private _aim ='), text.index('_aim nearEntities'))
        self.assertIn('true], "COUNTER"]', source('aiPassCounterBattery'))
        self.assertIn('(_job get "side")', source('aiPassCounterBattery'))

    def test_repeat_orders_invalidate_old_jobs(self):
        for kind in ['Garrison', 'Defend']:
            text = source(f'aiPass{kind}ApplyLocal')
            self.assertIn('["generation", _generation]', text)
            self.assertIn('!= (_job get "generation")', text)
        text = source('aiPassGarrisonRelease')
        self.assertRegex(text, r'if \(_x getVariable \["Waldo_AIPass_GarrisonDisabledPath", false\]\) then \{_x enableAI "PATH"\}')

    def test_stop_cancels_startup_and_airborne_work(self):
        stop = source('aiPassStop')
        for marker in ['["Waldo_AIPass_InitPending", false]', '["Waldo_AIPass_Dropping", nil]',
                       '["Waldo_AIPass_DropUntil", nil]', 'removeEventHandler ["IncomingMissile", _handler]']:
            self.assertIn(marker, stop)
        self.assertIn('Waldo_AIPass_InitPending', source('aiPassInit'))
        self.assertIn('_requested &&', source('aiPassInit'))
        self.assertIn('"team" in (_x select 2)', stop)

    def test_backblast_blocks_shot_in_current_invocation(self):
        text = source('aiPassAntiArmour')
        self.assertRegex(text, r'if \(_blocked\) exitWith \{[^}]*_gunner doMove _spot;\s*false\s*\};')
        self.assertLess(text.index('if (_blocked) exitWith'), text.index('_gunner doFire'))

    def test_parachute_restores_original_damage_on_current_owner(self):
        text = source('aiPassParachuteJump')
        self.assertIn('isDamageAllowed _unit', text)
        self.assertNotIn('allowDamage true', text)
        self.assertEqual(2, text.count('[_unit, _damageAllowed] remoteExecCall ["allowDamage", _unit]'))

    def test_airborne_land_is_gated_and_requires_landing(self):
        text = source('aiPassAirborneDropStep')
        self.assertLess(text.index('call Waldo_fnc_AIPassIsEligible'), text.index('// LAND'))
        self.assertIn('if (_landed &&', text)

    def test_lambs_mode_can_change_after_adoption(self):
        text = source('aiPassDiscover')
        self.assertLess(text.index('if ((!_lambsWmpMode'), text.index('if (!(_group getVariable ["Waldo_AIPass_Managed"'))
        self.assertIn('["Waldo_AIPass_LambsDisabledByPass", true, true]', text)
        self.assertIn('["Waldo_AIPass_LambsDisabledByPass", nil, true]', source('aiPassReleaseGroup'))

    def test_completed_waypoints_are_not_pending(self):
        text = source('aiPassGroupTick')
        self.assertEqual(3, text.count('(_x select 1) >= currentWaypoint _group'))

    def test_tuning_dialog_server_and_jip_share_spec(self):
        runtime = ROOT / 'MissionScripts' / 'ZenModules' / 'RuntimeControl'
        for name in ['featureRuntimeZen', 'featureRuntimeRequestState']:
            self.assertIn('call Waldo_fnc_AIPassTuningSpec', (runtime / f'{name}.sqf').read_text())
        self.assertIn('call Waldo_fnc_AIPassTuningSpec', source('aiPassTuning'))
        names = re.findall(r'\["(Waldo_AIPass_[^"]+)"', source('aiPassTuningSpec'))
        config = (ROOT / 'MissionConfig' / 'aiConfig.sqf').read_text()
        for name in names:
            self.assertIn(f'["{name}",', config)

if __name__ == '__main__':
    unittest.main()
