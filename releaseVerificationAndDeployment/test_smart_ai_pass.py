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
        text = source('aiPassArtilleryShot')
        shot = text.index('_battery doArtilleryFire')
        for gate in ['call Waldo_fnc_AIPassIsEligible', 'call Waldo_fnc_AIPassArtilleryRole',
                     'Waldo_AIPass_CounterBattery_Enable', '_aim nearEntities', 'crew _entity']:
            self.assertLess(text.index(gate), shot)
        self.assertIn('_battery doArtilleryFire [_aim, _magazine, 1]', text)
        self.assertIn('"COUNTER", objNull, _vehicle', source('aiPassCounterBattery'))
        self.assertIn('(_mission get "side")', source('aiPassArtilleryMissionStep'))

    def test_opening_aim_is_bounded_and_player_positions_are_rejection_only(self):
        text = source('aiPassArtilleryAim')
        self.assertEqual(1, text.count('allPlayers'))
        self.assertIn('from 0 to 7', text)
        self.assertIn('_radius max (_safe + _buffer)', text)
        self.assertIn('_players findIf', text)
        self.assertNotIn('set ["fix"', text)
        self.assertIn('if (_aim isEqualTo []) exitWith', source('aiPassArtilleryMissionStep'))

    def test_corrections_require_owner_observation_and_real_shots(self):
        report = source('aiPassArtilleryReport')
        self.assertIn('remoteExecutedOwner != owner _spotter', report)
        self.assertIn('Waldo_AIPass_Spotter', source('aiPassSpotterFix'))
        self.assertIn('checkVisibility', source('aiPassSpotterFix'))
        self.assertIn('Waldo_fnc_AIPassCanTransmit', source('aiPassSpotterFix'))
        fired = source('aiPassArtilleryFired')
        self.assertIn('time + _eta +', fired)
        self.assertIn('UNCERTAIN', fired)
        self.assertNotIn('doArtilleryFire', source('aiPassArtilleryMissionStep'))

    def test_locality_retires_old_jobs_and_replays_clearing_progress(self):
        self.assertIn('ownerEpoch', source('aiPassQueueJob'))
        self.assertIn('private _stale', source('aiPassSchedulerTick'))
        self.assertIn('"Waldo_AIPass_Checkpoint", _saved, true', source('aiPassCheckpoint'))
        self.assertIn('"restoreDisabled"', source('aiPassLocality'))
        self.assertIn('Waldo_AIPass_ClearOrder', source('aiPassDiscover'))
        self.assertIn('if (_resume)', source('aiPassClearBuilding'))

    def test_release_does_not_erase_unrecorded_headless_exclusions(self):
        text = source('aiPassReleaseFeatureCrew')
        self.assertIn('Waldo_Headless_PinBefore', text)
        self.assertIn('if (_existed)', text)
        self.assertNotIn('setVariable ["acex_headless_blacklist", false', text)

    def test_orders_use_actual_owner_result_and_named_settings(self):
        self.assertIn('remoteExecutedOwner != _expectedOwner', source('aiPassOrderResult'))
        self.assertIn('Waldo_fnc_AIPassOrderResult', source('aiPassOrderLocal'))
        zen = (ROOT / 'MissionScripts/ZenModules/RuntimeControl/featureRuntimeZen.sqf').read_text()
        for key in ['order', 'group', 'position', 'radius', 'building', 'facing', 'unit']:
            self.assertIn(f'["{key}",', zen)
            self.assertIn(f'getOrDefault ["{key}"', source('aiPassOrderDispatch') + source('aiPassOrderLocal'))

    def test_convoy_has_bounded_storage_and_no_server_pin(self):
        convoy = (ROOT / 'MissionScripts/AiScripting/convoyTick.sqf').read_text()
        self.assertIn('count _trail > 128', convoy)
        self.assertIn('_nearest + 10', convoy)
        self.assertIn('!local _group', convoy)
        registration = (ROOT / 'MissionScripts/AiScripting/simpleAiConvoy.sqf').read_text()
        self.assertNotIn('HeadlessPinCrew', registration)
        self.assertIn('Waldo_fnc_ConvoySync', registration)
        self.assertNotIn('execFSM', convoy)

    def test_known_shot_rejection_releases_without_retry(self):
        self.assertIn('Waldo_fnc_AIPassArtilleryRejected', source('aiPassArtilleryShot'))
        rejected = source('aiPassArtilleryRejected')
        self.assertIn('gunOwner', rejected)
        self.assertIn('["remaining", 0]', rejected)
        self.assertNotIn('doArtilleryFire', rejected)

    def test_garrison_handlers_are_removed_on_release_and_migration(self):
        for name in ['aiPassGarrisonRelease', 'aiPassLocality', 'aiPassStop']:
            text = source(name)
            self.assertIn('Waldo_AIPass_GarrisonHandlerIds', text)
            self.assertIn('removeEventHandler', text)
        for name in ['aiPassGarrison', 'aiPassDefend']:
            self.assertIn('call Waldo_fnc_AIPassClearRelease', source(name))

    def test_ai_setup_palette_and_exact_target_contract(self):
        modules = (ROOT / 'MissionScripts/ZenModules/Zen_initModules.sqf').read_text()
        for name in ['AI Control', 'AI Tuning', 'AI Orders', 'Artillery - Set Up Spotter',
                     'Artillery - Set Battery Role', 'Artillery - Set Up Radar', 'Convoy - Create Moving Group']:
            self.assertIn(f'["WMP AI Control", "{name}"', modules)
        zen = (ROOT / 'MissionScripts/ZenModules/RuntimeControl/featureRuntimeZen.sqf').read_text()
        setup = zen[zen.index('case "AI_SPOTTER"'):zen.index('case "AI_ORDERS"')]
        self.assertNotIn('nearestObjects', setup)
        self.assertNotIn('call _resolveTarget', setup)
        server = (ROOT / 'MissionScripts/ZenModules/RuntimeControl/featureRuntimeApply.sqf').read_text()
        for key in ['target', 'role', 'enabled', 'side']:
            self.assertIn(f'["{key}",', setup)
            self.assertIn(f'getOrDefault ["{key}"', server)
        radar = source('aiPassRegisterRadar')
        self.assertIn('remoteExecutedOwner != 2', radar)
        self.assertIn('if (_enabled) then {_radars pushBack', radar)
        self.assertIn('(_x select 0) != _object', radar)

    def test_finite_bursts_and_inventory_independent_comms(self):
        self.assertNotIn('assignedItems', source('aiPassCanTransmit'))
        self.assertNotIn('assignedItems', source('aiPassSpotterFix'))
        self.assertIn('JammingFactor', source('aiPassCanTransmit'))
        fired = source('aiPassArtilleryFired')
        self.assertIn('get "burstsLeft") - 1', fired)
        self.assertIn('["phase", "FIRING"]', fired)
        step = source('aiPassArtilleryMissionStep')
        self.assertIn('get "burstsLeft") <= 0', step)
        self.assertIn('then {_mission get "aim"}', step)
        self.assertIn('LocationResetDistance', step)
        self.assertNotIn('getPosATL', step)
        self.assertIn('LastEmission', step)
        counter = source('aiPassCounterBattery')
        self.assertNotIn('CounterBattery_Mode', counter)
        self.assertNotIn('AIPassCounterObserve', counter)
        self.assertIn('CounterBattery_RadarDelay', counter)
        self.assertIn('CounterGeneration', counter)

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
