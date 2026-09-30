"""Static regression contracts for PR 151; these do not execute SQF or prove engine behaviour."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'MissionScripts' / 'AiScripting' / 'Cortex'

def source(name):
    return re.sub(r'^/\*.*?\*/\s*', '', (BASE / f'{name}.sqf').read_text(encoding='utf-8-sig'), flags=re.S)

class CortexContracts(unittest.TestCase):
    def test_dead_leader_recovery_respects_authority_and_existing_leaders(self):
        text = source('cortexGroupTick')
        recovery = text.index('_group selectLeader _successor')
        self.assertLess(text.index('if (!local _group'), recovery)
        self.assertLess(text.index('call Waldo_fnc_CortexIsEligible'), recovery)
        self.assertIn('if ((isNull _leader || {!alive _leader}) && {[_group,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then', text)
        self.assertIn('local _x && {[_x] call Waldo_fnc_CortexCombatEffective}', text)
        effective = source('cortexCombatEffective')
        for exclusion in ['INCAPACITATED', 'ACE_isUnconscious', 'captive _unit', 'ace_captives_isSurrendering', 'ace_captives_isHandcuffed']:
            self.assertIn(exclusion, effective)
        self.assertLess(recovery, text.index('call Waldo_fnc_CortexKnowledge'))

    def test_curator_payloads_are_not_conflated(self):
        text = source('cortexZeusWatchLocal')
        self.assertIn('forEach ["CuratorWaypointPlaced", "CuratorWaypointEdited"]', text)
        self.assertNotIn('["CuratorWaypointEdited", "CuratorWaypointDeleted"]', text)
        self.assertIn('params ["", "_group"]', text)
        self.assertIn('_waypoint select 0', text)

    def test_plain_curator_selection_does_not_cancel_ai(self):
        text=source('cortexZeusWatchLocal')
        self.assertNotIn('SelectionChanged',text)
        for event in ['CuratorWaypointPlaced','CuratorWaypointEdited','CuratorWaypointDeleted','CuratorObjectEdited']:
            self.assertIn(event,text)

    def test_orders_gate_players_and_other_features_before_side_effects(self):
        for name, effect in [('cortexGarrison', 'call lambs_wp_fnc_taskGarrison'),
                             ('cortexDefend', '_x setVariable ["Waldo_AIPass_DefendPos"'),
                             ('cortexClearBuilding', 'spawn lambs_wp_fnc_taskCQB')]:
            with self.subTest(name=name):
                text = source(name)
                self.assertLess(text.index('call Waldo_fnc_CortexIsEligible'), text.index(effect))
        self.assertIn('[_group] call _isFeatureOwned', source('cortexIsEligible'))

    def test_fire_revalidates_after_queue_and_dispersion(self):
        text = source('cortexArtilleryShot')
        shot = text.index('_battery doArtilleryFire')
        for gate in ['call Waldo_fnc_CortexIsEligible', 'call Waldo_fnc_CortexArtilleryRole',
                     'Waldo_AIPass_CounterBattery_Enable', '_aim nearEntities', 'crew _entity']:
            self.assertLess(text.index(gate), shot)
        self.assertIn('_battery doArtilleryFire [_aim, _magazine, 1]', text)
        self.assertIn('"COUNTER", objNull, _vehicle', source('cortexCounterBattery'))
        self.assertIn('(_mission get "side")', source('cortexArtilleryMissionStep'))

    def test_opening_aim_is_bounded_and_player_positions_are_rejection_only(self):
        text = source('cortexArtilleryAim')
        self.assertEqual(1, text.count('allPlayers'))
        self.assertIn('from 0 to 7', text)
        self.assertIn('_radius max (_safe + _buffer)', text)
        self.assertIn('_players findIf', text)
        self.assertNotIn('set ["fix"', text)
        self.assertIn('if (_aim isEqualTo []) exitWith', source('cortexArtilleryMissionStep'))

    def test_corrections_require_owner_observation_and_real_shots(self):
        report = source('cortexArtilleryReport')
        self.assertIn('_sender != owner _spotter', report)
        self.assertIn('Waldo_AIPass_Spotter', source('cortexSpotterFix'))
        self.assertIn('checkVisibility', source('cortexSpotterFix'))
        self.assertIn('Waldo_fnc_CortexCanTransmit', source('cortexSpotterFix'))
        fired = source('cortexArtilleryFired')
        self.assertIn('time + _eta +', fired)
        self.assertIn('UNCERTAIN', fired)
        self.assertNotIn('doArtilleryFire', source('cortexArtilleryMissionStep'))

    def test_locality_retires_old_jobs_and_replays_clearing_progress(self):
        self.assertIn('ownerEpoch', source('cortexQueueJob'))
        self.assertIn('private _stale', source('cortexSchedulerTick'))
        self.assertIn('"Waldo_AIPass_Checkpoint", _saved, true', source('cortexCheckpoint'))
        self.assertIn('"restoreDisabled"', source('cortexLocality'))
        self.assertIn('Waldo_AIPass_ClearOrder', source('cortexDiscover'))
        self.assertIn('if (_resume)', source('cortexClearBuilding'))

    def test_release_does_not_erase_unrecorded_headless_exclusions(self):
        text = source('cortexReleaseFeatureCrew')
        self.assertIn('Waldo_Headless_PinBefore', text)
        self.assertIn('if (_existed)', text)
        self.assertNotIn('setVariable ["acex_headless_blacklist", false', text)

    def test_orders_use_actual_owner_result_and_named_settings(self):
        self.assertIn('[_replyOwner,_expectedOwner] call Waldo_fnc_HeadlessResolveSender', source('cortexOrderResult'))
        self.assertIn('Waldo_fnc_CortexOrderResult', source('cortexOrderLocal'))
        zen = (ROOT / 'MissionScripts/ZenModules/RuntimeControl/featureRuntimeZen.sqf').read_text()
        for key in ['order', 'group', 'position', 'radius', 'building', 'facing', 'unit']:
            self.assertIn(f'["{key}",', zen)
            self.assertIn(f'getOrDefault ["{key}"', source('cortexOrderDispatch') + source('cortexOrderLocal'))

    def test_convoy_has_bounded_storage_and_no_server_pin(self):
        convoy = (ROOT / 'MissionScripts/AiScripting/convoyTick.sqf').read_text()
        self.assertIn('count _trail > 128', convoy)
        self.assertIn('(_nearest + 10)', convoy)
        self.assertNotIn('doStop driver _vehicle; _vehicle setDriveOnPath', convoy)
        self.assertIn('private _gapLow', convoy)
        self.assertIn('private _gapHigh', convoy)
        self.assertIn('_frontTrails get (netId _front)', convoy)
        self.assertNotIn('driver _vehicle doFollow leader _group', convoy)
        self.assertIn('!local _group', convoy)
        registration = (ROOT / 'MissionScripts/AiScripting/simpleAiConvoy.sqf').read_text()
        self.assertNotIn('HeadlessPinCrew', registration)
        self.assertIn('Waldo_fnc_ConvoySync', registration)
        self.assertNotIn('execFSM', convoy)

    def test_convoy_halt_dismounts_passengers_not_operating_crew(self):
        base = ROOT / 'MissionScripts/AiScripting'
        registration = (base / 'simpleAiConvoy.sqf').read_text(encoding='utf-8')
        crew = (base / 'convoyCrewLocal.sqf').read_text(encoding='utf-8')
        self.assertIn('_role == "cargo" || {_role == "turret" && {_personTurret}}', registration)
        dismount = crew[crew.index('if (_phase != "HALT")'):]
        for gate in ['local _unit', '!isPlayer _unit', 'abs speed _vehicle < 1',
                     'ACE_isUnconscious', '(_seat select 1) == "cargo" || {(_seat select 1) == "turret" && {_seat select 2}}']:
            self.assertLess(dismount.index(gate), dismount.index('doGetOut'))
        self.assertIn('unassignVehicle _unit', dismount)
        self.assertNotIn('moveOut', dismount)
        self.assertIn('"HALT", _cargo, _old select 7', registration)

    def test_convoy_halt_is_revision_and_owner_checked(self):
        base = ROOT / 'MissionScripts/AiScripting'
        halt = (base / 'convoyHaltServer.sqf').read_text(encoding='utf-8')
        mutation = halt.index('call Waldo_fnc_SimpleAiConvoy')
        for gate in ['!isServer', 'remoteExecutedOwner != groupOwner _group',
                     '(_configuration select 0) != _expected', '(_configuration select 5) != "TRAVEL"']:
            self.assertLess(halt.index(gate), mutation)
        sync = (base / 'convoySync.sqf').read_text(encoding='utf-8')
        self.assertIn('_configuration select 7', sync)
        self.assertIn('Waldo_fnc_ConvoyCrewLocal', sync)

    def test_convoy_preserves_waypoints_and_does_not_treat_a_pause_as_arrival(self):
        tick = (ROOT / 'MissionScripts/AiScripting/convoyTick.sqf').read_text(encoding='utf-8')
        self.assertIn('currentWaypoint _group >= count waypoints _group', tick)
        self.assertIn('count waypoints _group > 1', tick)
        self.assertIn('_settled', tick)
        self.assertIn('serverTime - (_entry select 2) >= 15', tick)
        self.assertIn('_contact && {!_pushThrough || {_pinned}}', tick)
        self.assertNotIn('deleteWaypoint', tick)
        self.assertNotIn('setWaypointStatements', tick)
        self.assertIn('(driver _lead) doFollow leader _group', tick)
        self.assertNotIn('driver _lead doMove (waypointPosition', tick)
        self.assertIn('if (_vehicles isEqualTo []) exitWith', tick)
        self.assertNotIn('if (count _vehicles < 2) exitWith', tick)

    def test_mixed_convoy_uses_actual_steering_capability(self):
        tick = (ROOT / 'MissionScripts/AiScripting/convoyTick.sqf').read_text(encoding='utf-8')
        self.assertIn('private _native = !isAISteeringComponentEnabled _vehicle;', tick)
        self.assertIn('if (!(_pathOwners getOrDefault [_key,false])) then', tick)
        self.assertLess(tick.index('doStop driver _vehicle;'), tick.index('_vehicle setDriveOnPath'))
        self.assertIn('_pathOwners set [_key,true];', tick)
        self.assertIn('if (_native && {_path isNotEqualTo []}) then', tick)
        self.assertIn('driver _vehicle doMove', tick)
        self.assertIn('_vehicle setDriveOnPath (_path apply {_x + [_limit / 3.6]})', tick)
        self.assertIn('_lengths * 0.5 + 5', tick)
        self.assertIn('_maximum min (_topSpeed * 0.8)', tick)
        self.assertNotIn('if (!_contact && {_stretch > 3}) then {_leadLimit = 0}', tick)
        self.assertIn('_path pushBack _point', tick)

    def test_mounted_convoy_response_uses_local_known_targets_and_existing_roe(self):
        crew = (ROOT / 'MissionScripts/AiScripting/convoyCrewLocal.sqf').read_text(encoding='utf-8')
        for gate in ['local _unit', '!_passenger', 'unitCombatMode _unit',
                     'call Waldo_fnc_ConvoyThreat']:
            self.assertLess(crew.index(gate), crew.index('_unit doFire'))
        self.assertNotIn(' reveal ', crew)
        self.assertNotIn('setCombatMode', crew)
        tick = (ROOT / 'MissionScripts/AiScripting/convoyTick.sqf').read_text(encoding='utf-8')
        self.assertLess(tick.index('call Waldo_fnc_ConvoyCrewLocal'), tick.index('!local _group'))

    def test_convoy_contact_requires_danger_and_bounded_local_hit_evidence(self):
        base = ROOT / 'MissionScripts/AiScripting'
        tick = (base / 'convoyTick.sqf').read_text(encoding='utf-8')
        crew = (base / 'convoyCrewLocal.sqf').read_text(encoding='utf-8')
        threat = (base / 'convoyThreat.sqf').read_text(encoding='utf-8')
        release = (base / 'convoyReleaseLocal.sqf').read_text(encoding='utf-8')
        self.assertIn('_report select 2', tick)
        self.assertIn('getSuppression', tick)
        self.assertIn('!local _vehicle', crew)
        self.assertIn('>= 5', crew)
        self.assertIn('removeEventHandler ["Hit", _hitEH]', release)
        self.assertIn('_targets resize 16', threat)
        self.assertIn('_endangered > 0', threat)
        self.assertNotIn('getPos', threat)
        self.assertNotIn(' reveal ', threat)

    def test_convoy_cover_is_finite_owner_local_and_reboarding_is_respected(self):
        base = ROOT / 'MissionScripts/AiScripting'
        crew = (base / 'convoyCrewLocal.sqf').read_text(encoding='utf-8')
        cover = (base / 'convoyDismountLocal.sqf').read_text(encoding='utf-8')
        sync = (base / 'convoySync.sqf').read_text(encoding='utf-8')
        self.assertLess(crew.index('setVariable ["Waldo_Convoy_Dismount"'), crew.index('unassignVehicle _unit'))
        self.assertIn('Waldo_Convoy_Unloaded', crew)
        for guard in ['local _unit', 'serverTime >= _deadline', 'private _budget = 2', '_budget = _budget - 1', 'expectedDestination', 'Waldo_Convoy_DismountApplied']:
            self.assertIn(guard, cover)
        self.assertIn('[_group, _configuration, true] call Waldo_fnc_ConvoyDismountLocal', sync)
        self.assertIn('serverTime < (_job select 2)', source('cortexIsEligible'))

    def test_mixed_convoy_live_fixture_has_weapons_cargo_and_real_route(self):
        audit = ROOT / 'releaseVerificationAndDeployment/fullArmaAudit/WMP_FPA.VR'
        server = (audit / 'featureRangeServer.sqf').read_text(encoding='utf-8')
        block = server[server.index('Waldo_QA_fnc_startMixedConvoyServer ='):server.index('Waldo_QA_fnc_resetEconomyFixturesServer =')]
        for contract in ['B_APC_Tracked_01_rcws_F', 'B_MRAP_01_hmg_F', 'B_Truck_01_transport_F',
                         'createVehicleCrew', 'moveInCargo', 'addWaypoint', 'call Waldo_fnc_SimpleAiConvoy']:
            self.assertIn(contract, block)
        self.assertNotIn('setCurrentWaypoint', block)
        self.assertIn('START / RESET MIXED CONVOY', (audit / 'featureRangeClient.sqf').read_text(encoding='utf-8'))

    def test_convoy_vehicle_markers_protect_separate_passenger_groups(self):
        base = ROOT / 'MissionScripts/AiScripting'
        registration = (base / 'simpleAiConvoy.sqf').read_text(encoding='utf-8')
        release = (base / 'convoyReleaseLocal.sqf').read_text(encoding='utf-8')
        self.assertIn('_x setVariable ["Waldo_Convoy_Active", true, true]', registration)
        self.assertIn('Waldo_Convoy_Group', registration)
        self.assertIn('!(_vehicle in _keepCrew)', release)
        self.assertIn('_vehicle setVariable ["Waldo_Convoy_Active", nil, true]', release)
        self.assertIn('"Waldo_Convoy_Active"', source('cortexIsEligible'))

    def test_known_shot_rejection_releases_without_retry(self):
        self.assertIn('Waldo_fnc_CortexArtilleryRejected', source('cortexArtilleryShot'))
        rejected = source('cortexArtilleryRejected')
        self.assertIn('gunOwner', rejected)
        self.assertIn('["remaining", 0]', rejected)
        self.assertNotIn('doArtilleryFire', rejected)

    def test_garrison_handlers_are_removed_on_release_and_migration(self):
        for name in ['cortexGarrisonRelease', 'cortexLocality', 'cortexStop']:
            text = source(name)
            self.assertIn('Waldo_AIPass_GarrisonHandlerIds', text)
            self.assertIn('removeEventHandler', text)
        for name in ['cortexGarrison', 'cortexDefend']:
            self.assertIn('call Waldo_fnc_CortexClearRelease', source(name))

    def test_ai_setup_palette_and_exact_target_contract(self):
        modules = (ROOT / 'MissionScripts/ZenModules/Zen_initModules.sqf').read_text()
        for name in ['Cortex Control', 'Garrison Buildings', 'Defend Position', 'Clear Building', 'Parachute Passengers', 'Manage Group Control', 'Assign Artillery Spotter',
                     'Configure Artillery Battery', 'Configure Counter-battery Radar', 'Create Convoy']:
            self.assertIn(f'["WMP Cortex", "{name}"', modules)
        zen = (ROOT / 'MissionScripts/ZenModules/RuntimeControl/featureRuntimeZen.sqf').read_text()
        setup = zen[zen.index('case "AI_SPOTTER"'):zen.index('case "AI_ORDERS"')]
        self.assertNotIn('nearestObjects', setup)
        self.assertNotIn('call _resolveTarget', setup)
        server = (ROOT / 'MissionScripts/ZenModules/RuntimeControl/featureRuntimeApply.sqf').read_text()
        for key in ['target', 'role', 'enabled', 'side']:
            self.assertIn(f'["{key}",', setup)
            self.assertIn(f'getOrDefault ["{key}"', server)
        radar = source('cortexRegisterRadar')
        self.assertIn('remoteExecutedOwner != 2', radar)
        self.assertIn('if (_enabled) then {_radars pushBack', radar)
        self.assertIn('(_x select 0) != _object', radar)

    def test_finite_bursts_and_inventory_independent_comms(self):
        self.assertNotIn('assignedItems', source('cortexCanTransmit'))
        self.assertNotIn('assignedItems', source('cortexSpotterFix'))
        self.assertIn('JammingFactor', source('cortexCanTransmit'))
        fired = source('cortexArtilleryFired')
        self.assertIn('get "burstsLeft") - 1', fired)
        self.assertIn('["phase", "FIRING"]', fired)
        step = source('cortexArtilleryMissionStep')
        self.assertIn('get "burstsLeft") <= 0', step)
        self.assertIn('then {_mission get "aim"}', step)
        self.assertIn('LocationResetDistance', step)
        self.assertNotIn('getPosATL', step)
        self.assertIn('LastEmission', step)
        counter = source('cortexCounterBattery')
        self.assertNotIn('CounterBattery_Mode', counter)
        self.assertNotIn('AIPassCounterObserve', counter)
        self.assertIn('CounterBattery_RadarDelay', counter)
        self.assertIn('CounterGeneration', counter)

    def test_repeat_orders_invalidate_old_jobs(self):
        for kind in ['Garrison', 'Defend']:
            text = source(f'cortex{kind}ApplyLocal')
            self.assertIn('["generation", _generation]', text)
            self.assertIn('!= (_job get "generation")', text)
        text = source('cortexGarrisonRelease')
        self.assertRegex(text, r'if \(_x getVariable \["Waldo_AIPass_GarrisonDisabledPath", false\]\) then \{_x enableAI "PATH"\}')

    def test_stop_cancels_startup_and_airborne_work(self):
        stop = source('cortexStop')
        for marker in ['["Waldo_AIPass_InitPending", false]', '["Waldo_AIPass_Dropping", nil]',
                       '["Waldo_AIPass_DropUntil", nil]', 'removeEventHandler ["IncomingMissile", _handler]']:
            self.assertIn(marker, stop)
        self.assertIn('Waldo_AIPass_InitPending', source('cortexInit'))
        self.assertIn('_requested &&', source('cortexInit'))
        self.assertIn('"team" in (_x select 2)', stop)

    def test_convoy_phase_update_does_not_release_same_fleet(self):
        base = ROOT / 'MissionScripts' / 'AiScripting'
        sync = (base / 'convoySync.sqf').read_text(encoding='utf-8')
        crew = (base / 'convoyCrewLocal.sqf').read_text(encoding='utf-8')
        retained = sync.split('if (_retainNavigation) then {', 1)[1].split('} else {', 1)
        self.assertNotIn('call Waldo_fnc_ConvoyReleaseLocal', retained[0])
        self.assertIn('call Waldo_fnc_ConvoyReleaseLocal', retained[1])
        self.assertIn('_newController && {_phase == "TRAVEL"}', crew)
        self.assertNotIn('if (_repairSeat || {_newAssignment})', crew)
        tick = (base / 'convoyTick.sqf').read_text(encoding='utf-8')
        self.assertIn('if (count _state > 0 && {!_sameLine}) then', tick)
        self.assertNotIn('if (count _state > 0) then {[_group, false, _restore, _registered]', tick)

    def test_aircraft_rechecks_authority_and_ground_envelope(self):
        discover = source('cortexDiscover')
        permission = source('cortexAircraftEligible')
        self.assertIn('[_vehicle] call Waldo_fnc_CortexAircraftEligible', discover)
        self.assertIn('[_this] call Waldo_fnc_CortexAircraftEligible', discover)
        for guard in ['local _aircraft', 'CortexIsPaused', 'CortexZeusHeld',
                      'Waldo_AI_ExternalControl', 'bis_fnc_moduleRemoteControl_owner',
                      'Waldo_AIPass_IncludedSides', 'Waldo_AI_ExcludedFactions',
                      'ACE_isUnconscious']:
            self.assertIn(guard, permission)
        self.assertLess(discover.index('getTerrainHeightASL _position'),
                        discover.index('setVelocityModelSpace _candidate'))
        self.assertIn('forEach [0,1,2]', discover)
        self.assertIn('if (_safe &&', discover)

    def test_backblast_blocks_shot_in_current_invocation(self):
        text = source('cortexAntiArmour')
        blocked = text.split('if (_blocked) exitWith {', 1)[1].split('_gunner doTarget', 1)[0]
        self.assertIn('_gunner doMove _spot', blocked)
        self.assertIn('Waldo_Cortex_ActorMove', blocked)
        self.assertRegex(blocked, r'false\s*\};\s*$')
        self.assertLess(text.index('if (_blocked) exitWith'), text.index('_gunner doFire'))

    def test_parachute_restores_original_damage_on_current_owner(self):
        text = source('cortexParachuteJump')
        self.assertIn('isDamageAllowed _unit', text)
        self.assertNotIn('allowDamage true', text)
        self.assertEqual(2, text.count('[_unit, _damageAllowed] remoteExecCall ["allowDamage", _unit]'))

    def test_airborne_land_is_gated_and_requires_landing(self):
        text = source('cortexAirborneDropStep')
        self.assertLess(text.index('call Waldo_fnc_CortexIsEligible'), text.index('// LAND'))
        self.assertIn('if (_landed &&', text)

    def test_lambs_mode_can_change_after_adoption(self):
        text = source('cortexDiscover')
        self.assertLess(text.index('if ((!_lambsWmpMode'), text.index('if (!(_group getVariable ["Waldo_AIPass_Managed"'))
        self.assertIn('["Waldo_AIPass_LambsDisabledByPass", true, true]', text)
        self.assertIn('["Waldo_AIPass_LambsDisabledByPass", nil, true]', source('cortexReleaseGroup'))

    def test_completed_waypoints_are_not_pending(self):
        text = source('cortexGroupTick')
        maintain = source('cortexSupportMaintain')
        # Every temporary-route ownership check accepts only the current or a later waypoint.
        # The number grows as new movement owners adopt the shared contract, so do not freeze it.
        self.assertGreaterEqual(text.count('(_x select 1) >= currentWaypoint _group'), 3)
        self.assertIn('(_x select 1) >= currentWaypoint _group', maintain)
        self.assertNotIn('(_x select 1) < currentWaypoint _group', text + maintain)
        # Rally readiness remains physical and is never inferred from a pending waypoint.
        self.assertIn('_fit findIf {_x distance2D (_lease select 3) > 45} < 0', maintain)

    def test_tuning_dialog_server_and_jip_share_spec(self):
        runtime = ROOT / 'MissionScripts' / 'ZenModules' / 'RuntimeControl'
        self.assertIn('call Waldo_fnc_CortexTuningSpec', source('cortexControlOpenLocal'))
        for name in ['featureRuntimeRequestState']:
            self.assertIn('call Waldo_fnc_CortexTuningSpec', (runtime / f'{name}.sqf').read_text())
        self.assertIn('call Waldo_fnc_CortexTuningSpec', source('cortexTuning'))
        names = re.findall(r'\["(Waldo_AIPass_[^"]+)"', source('cortexTuningSpec'))
        config = (ROOT / 'MissionConfig' / 'aiConfig.sqf').read_text()
        for name in names:
            self.assertIn(f'["{name}",', config)

    def test_runtime_boolean_fallbacks_match_configured_defaults(self):
        config = (ROOT / 'MissionConfig' / 'aiConfig.sqf').read_text(encoding='utf-8')
        defaults = {
            name: value.lower()
            for name, value in re.findall(
                r'\["(Waldo_(?:AIPass|Convoy)_[A-Za-z0-9_]+(?:Enable|Enabled))",\s*(true|false)',
                config,
                re.IGNORECASE,
            )
        }
        self.assertIn('Waldo_AIPass_GrenadeEvasion_Enable', defaults)
        pattern = re.compile(
            r'missionNamespace\s+getVariable\s*\[\s*"(Waldo_(?:AIPass|Convoy)_[A-Za-z0-9_]+(?:Enable|Enabled))"\s*,\s*(true|false)\s*\]',
            re.IGNORECASE,
        )
        mismatches = []
        for path in (ROOT / 'MissionScripts').rglob('*.sqf'):
            for name, value in pattern.findall(path.read_text(encoding='utf-8')):
                if name in defaults and value.lower() != defaults[name]:
                    mismatches.append(f'{path.relative_to(ROOT)}: {name} uses {value.lower()}, configured {defaults[name]}')
        self.assertEqual([], mismatches, '\n'.join(mismatches))

    def test_ai_settings_revision_is_complete_before_worker_changes(self):
        local = source('cortexSettingsLocal')
        self.assertIn('remoteExecutedOwner != 2', local)
        self.assertIn('Waldo_AIPass_SettingsApplied', local)
        self.assertLess(local.index('forEach _updates'), local.index('call Waldo_fnc_AIRebalanceInit'))
        tuning = source('cortexTuning')
        self.assertIn('_snapshot = _spec apply', tuning)
        self.assertIn('[_revision,_snapshot] remoteExecCall', tuning)
        bridge = (ROOT / 'MissionScripts/ZenModules/RuntimeControl/featureRuntimeApply.sqf').read_text(encoding='utf-8')
        legacy = bridge.split('case "AI_CONFIG":')[1].split('case "AI_TUNING":')[0]
        self.assertIn('call Waldo_fnc_CortexTuning', legacy)
        self.assertNotIn('_updates call _publishAll', legacy)

    def test_ai_palette_splits_orders_by_purpose_and_combines_settings(self):
        zen = (ROOT / 'MissionScripts/ZenModules/Zen_initModules.sqf').read_text(encoding='utf-8')
        self.assertIn('Cortex Control', zen)
        self.assertNotIn('WMP AI & Combat', zen)
        for module in ['Dynamic AA - Create', 'Dynamic AA - Remove Nearest', 'Dynamic AO - Create', 'Dynamic AO - Remove']:
            self.assertIn(f'["WMP Cortex", "{module}"', zen)
        self.assertNotIn('"AI Orders"', zen)
        self.assertNotIn('"AI Tuning"', zen)
        for purpose in ['AI_GARRISON', 'AI_DEFEND', 'AI_CLEAR', 'AI_AIRBORNE', 'AI_GROUP']:
            self.assertIn(purpose, zen)
        spec = source('cortexTuningSpec')
        names = re.findall(r'\["(Waldo_(?:AIPass|AIRebalance)_[^"]+)",', spec)
        self.assertEqual(len(names), len(set(names)))
        for name in names:
            self.assertIn(f'["{name}",', (ROOT / 'MissionConfig/aiConfig.sqf').read_text(encoding='utf-8'))

    def test_cortex_custom_ui_preserves_pending_changes_and_authority(self):
        opening = source('cortexControlOpenLocal')
        page = source('cortexControlPageLocal')
        self.assertIn('createDisplay "RscDisplayEmpty"', opening)
        self.assertIn('findDisplay 312', opening)
        self.assertIn('getAssignedCuratorLogic player', opening)
        self.assertIn('Cortex_Revision', opening)
        self.assertIn('Cortex_Original', opening)
        self.assertIn('if !(_y isEqualTo (_original get _x))', opening)
        self.assertIn('["AI_TUNING",_pairs] call Waldo_fnc_FeatureRuntimeApply', opening)
        self.assertIn('Waldo_fnc_UnregisterUiReservationLocal', opening)
        self.assertLess(page.index('_draft set [_key,_value]'), page.index('ctrlDelete _x'))
        self.assertIn('RscControlsGroup', page)
        self.assertIn('sliderPosition _control', page)
        self.assertIn('lbCurSel _control == 1', page)
        self.assertNotIn('remoteExec', page)
        self.assertNotIn('addMissionEventHandler', opening)

    def test_runtime_startup_errors_cannot_recur(self):
        config = (ROOT / 'MissionConfig/aiConfig.sqf').read_text(encoding='utf-8')
        self.assertIn('["Waldo_AIPass_AmmoCapabilityOverrides", createHashMap]', config)
        self.assertNotIn('if (isNil "Waldo_AIPass_AmmoCapabilityOverrides")', config)
        self.assertTrue(config.rstrip().endswith(']'))
        player_init = (ROOT / 'initPlayerLocal.sqf').read_text(encoding='utf-8')
        self.assertLess(player_init.index('if (!hasInterface) exitWith {};'), player_init.index('call Waldo_fnc_SaveLoadout'))
        for name in ['cortexCapabilities', 'cortexArtilleryAmmo']:
            self.assertNotRegex(source(name), r'\bbitAnd\b')
        loader = (ROOT / 'MissionScripts/MissionInit/Configuration/loadFeatureConfigs.sqf').read_text(encoding='utf-8')
        self.assertIn('isNil "_config" ||', loader)

    def test_hc_zero_sender_requires_a_live_claim_and_expected_owner(self):
        helper = (ROOT / 'MissionScripts/Headless/headlessResolveSender.sqf').read_text(encoding='utf-8')
        for guard in ['_claimed != _sender', '_expected != _sender', '_claimed <= 2', '_claimed != _expected', 'entities "HeadlessClient_F"', 'owner _x == _claimed']:
            self.assertIn(guard, helper)
        runtime = ROOT / 'MissionScripts/ZenModules/RuntimeControl'
        self.assertIn('[clientOwner] remoteExecCall', (runtime / 'featureRuntimeSendStateRequest.sqf').read_text(encoding='utf-8'))
        self.assertIn('call Waldo_fnc_HeadlessResolveSender', (runtime / 'featureRuntimeRequestState.sqf').read_text(encoding='utf-8'))
        for name in ['cortexSupportAck','cortexSupportAssaultServer','cortexArtilleryRejected','cortexArtilleryReport','cortexOrderResult']:
            self.assertIn('call Waldo_fnc_HeadlessResolveSender', source(name))
        self.assertIn('_expectedOwner != groupOwner _group', source('cortexOrderResult'))

if __name__ == '__main__':
    unittest.main()
