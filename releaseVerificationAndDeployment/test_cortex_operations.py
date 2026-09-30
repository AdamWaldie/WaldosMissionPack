"""Cortex operational regression contracts. Engine acceptance is in cortexQA, not simulated here."""
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'MissionScripts/AiScripting/Cortex'
def source(name): return (BASE / (name + '.sqf')).read_text(encoding='utf-8')
class CortexOperations(unittest.TestCase):
    def test_cortex_control_deduplicates_settings_and_diagnostics_explain_once(self):
        page=source('cortexControlPageLocal')
        self.assertIn('private _seenKeys = createHashMap',page)
        self.assertIn('_seenKeys getOrDefault [_key,false]',page)
        self.assertIn('} forEach _pageRows;',page)
        opened=source('cortexControlOpenLocal')
        self.assertIn('private _seenKeys = createHashMap',opened)
        self.assertIn('_display setVariable ["Cortex_Spec",_spec]',opened)
        diagnostics=(ROOT/'MissionScripts/AiScripting/aiGetDiagnostics.sqf').read_text(encoding='utf-8')
        self.assertIn('Expected evidence:',diagnostics)
        self.assertIn('not an action trigger or success result',diagnostics)
        self.assertNotIn('Trigger/inspection:',diagnostics)
        self.assertIn('private _seenTuningKeys=createHashMap',diagnostics)
        self.assertIn('_tuningSpec pushBack _x',diagnostics)
        client=(ROOT/'releaseVerificationAndDeployment/cortexQA/runClient.sqf').read_text(encoding='utf-8')
        self.assertIn('UI-01b-canonical-settings',client)
        self.assertIn('UI-02b-unique-page-',client)
        self.assertIn('arrayIntersect _editorKeys',client)

    def test_cortex_control_distinguishes_master_gates_from_feature_switches(self):
        spec=source('cortexTuningSpec')
        for label in [
            'Apply WMP skill profiles',
            'Enable Cortex automatic tactics',
            'Enable Cortex vehicle tactics',
            'Enable spotter artillery support',
            'Proactive attack-run countermeasures',
            'Missile-threat countermeasures',
            'Selected WMP skill profile',
        ]:
            self.assertIn(label,spec)
        self.assertIn('_name find "AttackRunFlares" >= 0',spec)
        self.assertNotIn('"Skill profiles",',spec)
        self.assertNotIn('"Cortex behaviours",',spec)

    def test_replacement_clear_retires_old_movement_after_validation(self):
        text=source('cortexClearBuilding')
        marker='if (!_resume && {_previous isNotEqualTo []}) then {[_group] call Waldo_fnc_CortexClearRelease};'
        self.assertIn(marker,text)
        self.assertLess(text.index('if (_positions isEqualTo [])'),text.index(marker))
        self.assertLess(text.index('if (_team isEqualTo [])'),text.index(marker))
        self.assertLess(text.index(marker),text.index('_group setVariable ["Waldo_AIPass_ClearOrder", [_building'))

    def test_door_audit_uses_clearance_and_measures_animation_and_entry(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runBuildingComparison.sqf').read_text(encoding='utf-8').split('// Exercise door handling',1)[1]
        self.assertIn('call Waldo_fnc_CortexClearBuilding',text)
        self.assertIn('CLEAR-door-lock-preserved',text)
        self.assertIn('CLEAR-door-unlocked-physical-entry',text)
        self.assertIn('vectorDistance (AGLToASL _position) <= 1.5',text)
        self.assertNotIn('call Waldo_fnc_CortexBuildingDoor',text)
        self.assertNotIn('call BIS_fnc_door',text)
        self.assertNotIn('animateSource [',text)

    def test_garrison_does_not_command_players_or_incapacitated_members(self):
        for name in ['cortexGarrison','cortexGarrisonApplyLocal','cortexGarrisonRelease']:
            text=source(name)
            self.assertIn('!isPlayer',text)
            self.assertIn('INCAPACITATED',text)
        release=source('cortexGarrisonRelease')
        self.assertLess(release.index('enableAI "PATH"'),release.index('if (alive _x && {!isPlayer'))

    def test_building_door_helper_preserves_locks_and_requires_local_proximity(self):
        text=source('cortexBuildingDoor')
        self.assertIn('!local _unit',text)
        self.assertIn('_lock isEqualTo 0',text)
        self.assertIn('vectorDistance _position <= 12',text)
        self.assertIn('serverTime+2',text)
        self.assertIn('isNil {_building getVariable "Waldo_Cortex_DoorDefinitions"}',text)
        self.assertLess(text.index('private _requested=false'),text.index('private _lock='))
        self.assertIn('call BIS_fnc_door',text)
        self.assertNotIn('animateSource',text)
        self.assertNotIn('setPos',text)
        self.assertNotIn('setVariable [format ["bis_disabled',text)

    def test_clearance_releases_casualty_and_transferred_member_reservations(self):
        text=source('cortexClearBuilding')
        release=text.split('// Release reservations before selection',1)[1].split('private _now',1)[0]
        self.assertIn('!alive _x',release)
        self.assertIn('group _x != _group',release)
        self.assertIn('isPlayer _x',release)
        self.assertIn('lifeState _x == "INCAPACITATED"',release)
        self.assertIn('_assigned set [_forEachIndex,[]]',release)
        self.assertIn('if (_restore) then {',text)
        release=source('cortexClearRelease')
        self.assertIn('params [["_group", grpNull, [grpNull]],["_restore",true,[true]]]',release)
        tick=source('cortexGroupTick')
        self.assertIn('[_group,false] call Waldo_fnc_CortexClearRelease',tick)

    def test_clearance_timeout_cannot_clear_rooms_or_abort_other_workers(self):
        text=source('cortexClearBuilding')
        timeout=text.split('if (_now-_lastProgress > _retryDelay)',1)[1].split('_state set [0,_cursor]',1)[0]
        self.assertNotIn('_cleared pushBack',timeout)
        self.assertNotIn('movementFailed',text)
        self.assertIn('_unreachable pushBackUnique _positionIndex',timeout)
        self.assertIn('_failures pushBackUnique _pairId',timeout)
        self.assertIn('count _failures >= _failureThreshold',timeout)
        self.assertIn('_x setDestination [_unitTarget,"LEADER PLANNED",true]',timeout)
        self.assertIn('_x distance2D _old >= 1',text)
        self.assertIn('_retries < 3',timeout)
        self.assertIn('count (_job get "cleared") == count (_job get "positions")',text)

    def test_clearance_release_resumes_formation_after_do_stop(self):
        clear=source('cortexClearBuilding')
        release=source('cortexClearRelease')
        self.assertIn('_x doFollow _leader',clear)
        self.assertIn('_x doFollow _leader',release)
        self.assertNotIn('_x commandFollow _leader',clear)
        self.assertNotIn('_x commandFollow _leader',release)

    def test_holding_release_restores_leader_but_yields_to_zeus_replacement(self):
        garrison=source('cortexGarrisonRelease')
        defend=source('cortexDefendRelease')
        tick=source('cortexGroupTick')
        for release in [garrison,defend]:
            self.assertIn('["_restore",true,[true]]',release)
            self.assertIn('if (_restore) then {_x doFollow _leader}',release)
        self.assertIn('[_group,false] call Waldo_fnc_CortexGarrisonRelease',tick)
        self.assertIn('[_group,false] call Waldo_fnc_CortexDefendRelease',tick)

    def test_clearance_rotates_failed_position_between_workers(self):
        text=source('cortexClearBuilding')
        self.assertIn('private _failedBy',text)
        self.assertIn('private _failureThreshold=(count (_job get "pairs")) min 2 max 1',text)
        self.assertIn('(_job get "pending") pushBackUnique _positionIndex',text)
        self.assertIn('private _pairId=format ["PAIR_%1",_pairIndex]',text)
        self.assertIn('for "_exitIndex" from 0 to 15 do',text)
        self.assertIn('private _ranked=_entries apply',text)

    def test_clearance_uses_independent_workers_and_continuous_room_routes(self):
        text=source('cortexClearBuilding')
        self.assertIn('private _pairs=_team apply {[_x]}',text)
        self.assertIn('private _team = +_available',text)
        self.assertIn('private _entryCapacity = ((((count _positions) min 4) * 2) max 2) min 8',text)
        self.assertIn('private _pending=+_routeOrder',text)
        self.assertIn('private _pairRoutes=_pairs apply {[]}',text)
        self.assertIn('_pairStates pushBack [0,false',text)
        self.assertIn('_entries resize ((count _entries) min 4)',text)
        self.assertIn('_approachingEntry=false',text)
        self.assertIn('_approachingEntry=true',text)
        self.assertIn('_triedEntries pushBackUnique _entryIndex',text)
        self.assertIn('_cursor=_cursor+1',text)

    def test_clearance_workers_claim_without_node_crowding(self):
        text=source('cortexClearBuilding')
        self.assertIn('private _point=_pair select (_moverIndex mod count _pair)',text)
        self.assertIn('private _supportTarget=[]',text)
        self.assertIn('_previousPositionIndex=_positionIndex',text)
        self.assertIn('private _unitTarget=if (_unit == _point',text)
        self.assertIn('_failureThreshold=(count (_job get "pairs")) min 2 max 1',text)
        self.assertNotIn('"ROTATE"',text)

    def test_clearance_reinforces_casualties_from_uncommitted_squad_members(self):
        text=source('cortexClearBuilding')
        self.assertIn('private _reserves=(units _group) select',text)
        self.assertIn('_pair set [_slot,_replacement]',text)
        self.assertIn('Waldo_Cortex_ClearReinforcements',text)
        self.assertIn('lifeState _member == "INCAPACITATED"',text)

    def test_clearance_egresses_before_terminal_handover(self):
        text=source('cortexClearBuilding')
        self.assertIn('(_job getOrDefault ["phase","CLEAR"]) == "EGRESS"',text)
        self.assertIn('[_unit,_entry getPos [10,_outward]]',text)
        self.assertIn('_job set ["phase","EGRESS"]',text)
        self.assertIn('_job set ["egressAssignments",_egressAssignments]',text)
        self.assertIn('_job set ["egressFailed",true]',text)
        self.assertIn('!(_job getOrDefault ["egressFailed",false])',text)

    def test_clearance_preserves_live_behaviour_and_combat_mode(self):
        clear=source('cortexClearBuilding')
        release=source('cortexClearRelease')
        self.assertNotIn('_group setBehaviour "COMBAT"',clear)
        self.assertNotIn('_group setBehaviour (_job get "baseBehaviour")',clear)
        self.assertNotIn('_group setBehaviour (_order select 3)',release)
        self.assertNotIn('setCombatMode',clear)
        self.assertNotIn('setCombatMode',release)

    def test_zeus_takeover_cleanup_does_not_replace_curator_movement(self):
        release=source('cortexReleaseGroup')
        restore=source('cortexRestoreCalm')
        flank_end=source('cortexFlankEnd')
        self.assertIn('private _yieldToExternal=local _group && {[_group] call Waldo_fnc_CortexZeusHeld}',release)
        self.assertIn('["RELEASE","ZEUS"] select _yieldToExternal',release)
        self.assertIn('[_group, _state, false, _yieldToExternal] call Waldo_fnc_CortexRestoreCalm',release)
        self.assertIn('["_yieldToExternal",false,[true]]',restore)
        self.assertIn('if (!_yieldToExternal) then',restore)
        self.assertIn('if (_reason != "ZEUS") then',flank_end)

    def test_garrison_reassigns_unreachable_positions_without_wall_clock_failure(self):
        order=source('cortexGarrison')
        apply=source('cortexGarrisonApplyLocal')
        release=source('cortexGarrisonRelease')
        self.assertIn('Waldo_Cortex_GarrisonCandidates',order)
        self.assertIn('Waldo_Cortex_GarrisonCandidates',release)
        self.assertIn('_reassignments < 2',apply)
        self.assertIn('_x setVariable ["Waldo_AIPass_GarrisonPos",_replacement,true]',apply)
        self.assertIn('!(_key in _attempted)',apply)
        self.assertIn('for "_index" from 0 to 31 do',apply)
        self.assertIn('Garrison trying alternate entrance',apply)
        self.assertIn('private _target = _destination',apply)
        self.assertIn('private _approach = false',apply)
        self.assertIn('private _replacementApproach=false',apply)
        self.assertIn('private _replacementTarget=_replacementDestination',apply)
        self.assertIn('_entries resize ((count _entries) min 4)',apply)
        self.assertIn('if (_nextEntry < count _entries) then',apply)
        self.assertIn('["deadline", time + 240]',apply)
        self.assertNotIn('_job set ["deadline",(_job get "deadline") max (time+60)]',apply)

    def test_defence_recovery_uses_per_unit_physical_progress(self):
        text=source('cortexDefendApplyLocal')
        self.assertIn('_routes pushBack [_x,getPosATL _x,time,0]',text)
        self.assertIn('_unit distance2D _lastPosition >= 1',text)
        self.assertIn('time-_lastProgress >= 15',text)
        self.assertIn('_retries < 3',text)
        self.assertIn('_unit setDestination [_assignment select 0,"LEADER PLANNED",true]',text)
        self.assertNotIn('["deadline", time + 90]',text)

    def test_clearance_renews_safety_lease_only_on_observed_progress(self):
        text=source('cortexClearBuilding')
        self.assertIn('private _madeProgress=count _cleared != _before',text)
        self.assertIn('_job set ["deadline",(_job get "deadline") max (serverTime+120)]',text)
        self.assertIn('_job set ["lastProgressAt",serverTime]',text)
        self.assertNotIn('_job set ["deadline",serverTime+120]',text)

    def test_clearance_preserves_failure_evidence_after_release(self):
        clear=source('cortexClearBuilding')
        release=source('cortexClearRelease')
        diagnostics=(ROOT/'MissionScripts/AiScripting/aiGetDiagnostics.sqf').read_text(encoding='utf-8')
        self.assertIn('_group setVariable ["Waldo_Cortex_ClearEvidence",[+(_job get "cleared")',clear)
        self.assertIn('_group setVariable ["Waldo_Cortex_ClearEvidence",[+(_order param [1,[]])',release)
        self.assertIn('_group getVariable ["Waldo_Cortex_ClearEvidence",[]]',diagnostics)
        self.assertIn('_clearEvidence param [3,[]]',diagnostics)

    def test_building_scale_cases_use_fresh_groups_and_observed_room_visits(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runBuildingComparison.sqf').read_text(encoding='utf-8')
        cases=text.split('// Fresh groups distinguish',1)[1]
        self.assertIn('[2,"Land_i_House_Small_01_V1_F"]',cases)
        self.assertIn('[6,"Land_i_House_Big_01_V1_F"]',cases)
        self.assertIn('[12,"Land_i_House_Big_02_V1_F"]',cases)
        self.assertIn('call Waldo_fnc_CortexClearBuilding',cases)
        self.assertIn('vectorDistance (AGLToASL _room) <= 1.5',cases)
        self.assertIn('private _clearingMembers=+_members',cases)
        self.assertNotIn('_members select [1,2]',text)
        self.assertNotIn('setPos',cases)
        self.assertNotIn('call Waldo_fnc_CortexGarrison',cases)

    def test_cqb_casualty_uses_real_reserve_and_physical_movement(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runBuildingComparison.sqf').read_text(encoding='utf-8')
        case=text.split('// A casualty inside the clearing element',1)[1].split('// Exercise door handling',1)[0]
        self.assertIn('for "_i" from 0 to 9 do',case)
        self.assertIn('_casualty setDamage 1',case)
        self.assertIn('Waldo_Cortex_ClearReinforcements',case)
        self.assertIn('CLEAR-casualty-reserve-assigned',case)
        self.assertIn('CLEAR-casualty-reserve-physical-movement',case)
        self.assertNotIn('setPos',case)
        self.assertNotIn('moveIn',case)

    def test_building_entry_controls_cover_four_distinct_models(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runBuildingComparison.sqf').read_text(encoding='utf-8').split('missionNamespace setVariable ["Waldo_CortexQA_Actors"',1)[0]
        for building in ['Land_i_House_Small_03_V1_F','Land_i_House_Small_01_V1_F','Land_i_House_Big_01_V1_F','Land_i_House_Big_02_V1_F']:
            self.assertIn(building,text)

    def test_remount_retry_preserves_active_boarding_command(self):
        text=source('cortexGroupTick')
        self.assertIn('if (assignedVehicle _unit != _vehicle) then {_unit assignAsCargo _vehicle}',text)
        self.assertIn('if (toUpperANSI (currentCommand _unit) != "GET IN") then {[_unit] orderGetIn true}',text)

    def test_replacement_boarding_audit_requires_owned_exit_and_physical_arrival(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runVehicleDrills.sqf').read_text(encoding='utf-8')
        case=text.split('if (_replacementOrder) then {',1)[1].split('["Vehicle calm remount:',1)[0]
        self.assertIn('assignAsCargo _replacement',case)
        self.assertNotIn('moveInCargo',case)
        self.assertNotIn('call Waldo_fnc_CortexRestoreCalm',case)
        self.assertIn('REMOUNT-replacement-assignment-preserved',case)
        self.assertIn('REMOUNT-replacement-physically-boarded',case)
        self.assertIn('_ownedExit && {_replacementBoarded}',case)
        self.assertIn('assignedVehicle _x != _replacement',case)

    def test_remount_preserves_replacement_vehicle_assignment(self):
        tick=source('cortexGroupTick')
        restore=source('cortexRestoreCalm')
        self.assertIn('assignedVehicle (_x select 0) == (_x select 1)',tick)
        for text in [tick,restore]:
            self.assertIn('assignedVehicle _unit == (_x select 1)',text)
        self.assertIn('isNull assignedVehicle _unit || {assignedVehicle _unit == _vehicle}',restore)

    def test_passenger_exit_records_ownership_before_engine_commands(self):
        text=source('cortexVehicles')
        self.assertLess(text.index('_state set ["dismounted", _dismounted]'),text.index('[_unit] orderGetIn false'))
        self.assertLess(text.index('[_unit] orderGetIn false'),text.index('doGetOut _unit'))

    def test_support_fixture_preserves_occlusion_and_assigned_destination(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runSupport.sqf').read_text(encoding='utf-8')
        self.assertLess(text.index('createVehicle ["Land_CncWall4_F"'),text.index('private _listeners='))
        self.assertIn('HEARING-fixture-no-prior-contact',text)
        self.assertIn('_rally=+(_assignedLease select 3)',text)
        self.assertIn('_x distance2D (_helperStarts select (_helpers find _x)) < 15',text)
        self.assertIn('_x distance2D _rally > 45',text)
        self.assertIn('forEach _soundTrace',text)

    def test_countermeasure_inventory_is_per_vehicle_and_live(self):
        text=source('cortexFireCountermeasure')
        self.assertNotIn('CountermeasureCache',text)
        self.assertIn('_vehicle weaponsTurret _turret',text)
        self.assertIn('toLowerANSI',text)
        self.assertIn('Fired events establish actual fire',text)

    def test_artillery_baseline_retains_counter_owner(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runServer.sqf').read_text(encoding='utf-8')
        for gun in ['_gun','_counterGun','_emitter']:
            self.assertIn('['+gun+'] call _retainServerGun',text)
        self.assertIn('server-owner-retained',text)
        self.assertIn('local gunner _counterGun',text)

    def test_ai_diagnostics_feature_depth_and_queue_scope(self):
        diagnostic=(ROOT/'MissionScripts/AiScripting/aiGetDiagnostics.sqf').read_text(encoding='utf-8')
        for feature in ['Regroup','Contact','PostContact','Flank','StreetCrossing','FireControl','Morale','Surrender','GrenadeEvasion','AntiArmour','Vehicles','ContactReports','Reinforce','Artillery','CounterBattery','Airborne','AircraftFlares','Investigate','Assault','Advance','CoordinatedAssault','Stance','AmmoShare','VehicleGunnery','ArtillerySmoke','AircraftBreak','VehicleDismount','VehicleRemount','VehicleWithdraw','CoverValidation','Hearing','MountedFire','Cover','AvoidInfantry','ContactHalt','Unload']:
            self.assertIn('["'+feature+'",',diagnostic)
        self.assertIn('private _parents=+(_dependencies',diagnostic)
        self.assertIn('oldestDueSeconds=',diagnostic)
        self.assertIn('staleOwnerJobs=',diagnostic)
        self.assertIn('tuning [label,current,default]',diagnostic)
        self.assertNotIn('call Waldo_fnc_CortexIsEligible',diagnostic)

    def test_ai_diagnostics_are_bounded_read_only_snapshots(self):
        diagnostic=(ROOT/'MissionScripts/AiScripting/aiGetDiagnostics.sqf').read_text(encoding='utf-8')
        self.assertNotIn('call Waldo_fnc_CortexZeusHeld',diagnostic)
        self.assertNotIn('setVariable',diagnostic)
        self.assertNotIn('smart-ai-pass',diagnostic)
        self.assertIn('call Waldo_fnc_CortexTuningSpec',diagnostic)
        self.assertIn('(_localGroups select [0,20])',diagnostic)
        self.assertIn('(units _group) select [0,8]',diagnostic)
        self.assertIn('HC private action/queue state is unavailable here, not zero',diagnostic)
        self.assertIn('confirmedShots=',diagnostic)
        self.assertIn('haltReason=',diagnostic)
        self.assertIn('(_orderedGroups select [0,20])',diagnostic)
        self.assertIn('3D-assignment-distance-or-minus1',diagnostic)
        self.assertIn('cortex-order-snapshot-scope',diagnostic)

    def test_full_feature_focus_never_omits_an_all_suite(self):
        import re
        runner=(ROOT/'releaseVerificationAndDeployment/cortexQA/runServer.sqf').read_text(encoding='utf-8')
        selections=re.findall(r'if \(_focus in (\[[^\]]+\])\)',runner)
        for selection in selections:
            if '"all"' in selection:
                self.assertIn('"features"',selection)
        self.assertNotIn('if (_focus == "all")',runner)
        self.assertGreater(runner.index('if (_focus in ["all","features","coordinated"])'),runner.index('cortexQAFire.sqf'))

    def test_other_feature_batch_and_independent_artillery(self):
        runner=(ROOT/'releaseVerificationAndDeployment/cortexQA/runServer.sqf').read_text(encoding='utf-8')
        for focus in ['mechanics','reactions','support','airborne','vehicles','fire','landing','cover','contact','profiles','scheduler','performance','lifecycle','aircraft','deceleration','gunnery','artillerysmoke','crossing','convoyseats','avoidance']:
            import re
            self.assertRegex(runner,r'if \(_focus in \[[^\]]*"features"[^\]]*"'+focus+r'"[^\]]*\]\)')
        artillery=runner.split('if (_focus in ["all","features","artillery"]) then {',1)[1].split('if (_focus in ["all","features","convoyseats"',1)[0]
        self.assertNotIn('_u1',artillery)
        self.assertIn('private _spotter=',artillery)
        self.assertIn('deleteVehicle _spotter',artillery)
        self.assertIn('deleteGroup _gunGroup',artillery)

    def test_failed_coordinated_bound_holds_until_new_sequence(self):
        end=source('cortexFlankEnd')
        self.assertIn('_reason in ["STALLED","TIME_LIMIT","RECOVERY_FAILED"]',end)
        hold=end.split('if (_holdFailedBound) then {',1)[1].split('} else {',1)[0]
        self.assertIn('_state set ["supportHeld",_held]',hold)
        self.assertIn('_x disableAI "PATH"',hold)
        self.assertNotIn('_x doFollow',hold)
        self.assertIn('[_supportToken,_drill get "supportSequence",_reason]',end)
        maintain=source('cortexSupportMaintain')
        self.assertIn('if (_newMove || {!_coordinating})',maintain)
        self.assertIn('private _newMove=_moving && {(_state getOrDefault ["supportBoundSequence",-1]) != (_role select 1)}',maintain)

    def test_coordinated_clean_approach_is_additive(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCoordinated.sqf').read_text(encoding='utf-8')
        self.assertIn('[[1408,1410,0],[1608,1410,0]]',qa)
        self.assertIn('[[1500,1470,0]]',qa)
        self.assertIn('["_localScreens",false,[true]]',qa)
        runner=(ROOT/'releaseVerificationAndDeployment/cortexQA/runServer.sqf').read_text(encoding='utf-8')
        self.assertIn('if (_focus == "coordinatedbounds")',runner)
        self.assertIn('if (_focus in ["all","features","coordinatedclean"])',runner)
        self.assertIn('[_cleanCheck,_phase,_wait,[],true,true]',runner)
        self.assertIn('["CLEAN-"+_id,_passed,_detail]',runner)

    def test_coordinated_rally_screen_is_removed_before_assault_measurement(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCoordinated.sqf').read_text(encoding='utf-8')
        self.assertIn('COORD-assault-corridor-clear',qa)
        self.assertIn('{deleteVehicle _x} forEach _movementScreens;',qa)
        self.assertLess(qa.index('COORD-assault-corridor-clear'),qa.index('Movement diagnostic: coordinated bounds'))
        self.assertIn('private _outside = _x findIf {_x distance2D _area > 45};',qa)
        self.assertIn('_outside >= 0',qa)

    def test_literal_qa_tuning_requests_have_transport_entries(self):
        import re
        spec = set(re.findall(r'\["(Waldo_[^"]+)"', source('cortexTuningSpec')))
        for path in (ROOT/'releaseVerificationAndDeployment/cortexQA').glob('*.sqf'):
            text = path.read_text(encoding='utf-8')
            for match in re.finditer(r'\[createHashMapFromArray\s*\[', text):
                depth, quoted, end = 1, False, match.start()+1
                # Match the call's outer array; unrelated HashMaps must not consume
                # later code and falsely treat state/diagnostic keys as settings.
                while end < len(text) and depth:
                    char = text[end]
                    if char == '"':
                        if quoted and end+1 < len(text) and text[end+1] == '"':
                            end += 2
                            continue
                        quoted = not quoted
                    elif not quoted:
                        depth += (char == '[') - (char == ']')
                    end += 1
                if not re.match(r'\s*call\s+Waldo_fnc_CortexTuning\b', text[end:]):
                    continue
                requested = set(re.findall(r'\["(Waldo_[^"]+)"', text[match.start():end]))
                self.assertFalse(requested-spec, f'{path.name}: unknown runtime settings {requested-spec}')

    def test_advance_contact_delay_is_in_authoritative_transport(self):
        self.assertIn('"Waldo_AIPass_Advance_MinContactSeconds"', source('cortexTuningSpec'))
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('-requested-contact-delay', qa)

    def test_movement_roe_restores_only_the_owned_value(self):
        step = source('cortexFlankStep')
        self.assertIn('if (unitCombatMode _unit == "RED")', step)
        self.assertIn('_combatModes pushBack [_unit,"RED","YELLOW"]', step)
        for name in ['cortexFlankStep', 'cortexFlankEnd', 'cortexLocality']:
            self.assertIn('unitCombatMode _unit == _ownedMode', source(name))
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('-combat-mode-restored', qa)

    def test_coordinated_bound_uses_matching_role_objective_before_personal_contact(self):
        text = source('cortexFlankStep')
        self.assertIn('if (_support) then {+(_supportRole select 4)}', text)
        self.assertLess(text.index('!_supportValid'), text.index('private _enemyPos ='))
        self.assertIn('(_supportRole select 0) == _supportToken', text)
        self.assertIn('(_supportRole select 1) == (_drill get "supportSequence")', text)

    def test_tactical_holds_use_configured_pause_without_grenade_state_gate(self):
        text = source('cortexFlankStep')
        for stage in ['FINAL','CONSOLIDATE','CLEAR']:
            block = text.split('case "'+stage+'": {')[1].split('case ')[0]
            self.assertIn('Waldo_AIPass_Flank_BoundPause', block)
        self.assertIn('!_support &&', text)
        self.assertIn('_drill set ["grenadeActionUntil",[_now,_now+2] select _queued]', text)
        self.assertNotIn('case "GRENADE": {', text)

    def test_support_reserves_separate_rally_areas_in_durable_leases(self):
        step = source('cortexSupportStep')
        self.assertIn('for "_slot" from 0 to 5 do', step)
        self.assertIn('(_other select 3) distance2D _centre < 109', step)
        self.assertIn('!surfaceIsWater _centre', step)
        self.assertIn('if (_rally isNotEqualTo []) then {', step)
        self.assertIn('_job get "expiry",_rally,_job get "at"', step)
        self.assertNotIn('_job get "expiry",+(_job get "rally")', step)
        fixture=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCoordinated.sqf').read_text()
        self.assertIn('COORD-distinct-rally-areas', fixture)
        self.assertIn('_x distance2D _area > 45', fixture)

    def test_movement_handoff_does_not_reset_covering_group_roe(self):
        step=source('cortexFlankStep')
        self.assertNotIn('_group setCombatMode',step)
        self.assertNotIn('call _clearAttack',step)
        self.assertIn('_unit setUnitCombatMode "YELLOW"',step)
        stance=source('cortexStance')
        self.assertIn('in ["START","MOVE"]',stance)
        self.assertIn('+(_drill getOrDefault ["movers"',stance)
        self.assertIn('grenadeThrower',stance)

    def test_coordinated_moving_fire_is_measured_at_discharge(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCoordinated.sqf').read_text()
        fired=qa.split('addEventHandler ["FiredMan",{')[1].split('    }];')[0]
        self.assertIn('abs speed _unit > 2',fired)
        self.assertIn('Waldo_Cortex_SupportTeams',fired)
        self.assertIn('_unit in (_teams select 5)',fired)
        self.assertIn('Waldo_CortexQA_MovingShots',fired)
        self.assertIn('COORD-no-prolonged-empty-range-idle',qa)
        self.assertIn('COORD-full-fire-team-physical-bounds',qa)
        self.assertIn('COORD-no-engine-attack-overrides',qa)
        self.assertIn('currentCommand _x == "ATTACK"',qa)

    def test_handover_visuals_do_not_keep_stale_rally_labels(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCoordinated.sqf').read_text()
        for description,label in [('QA FRESH ORDINARY ORDER','ORDINARY ORDER'),
                                  ('QA ZEUS REPLACEMENT','ZEUS ORDER'),
                                  ('QA UNOPPOSED HANDOVER DIAGNOSTIC','UNOPPOSED ORDER')]:
            stage=qa.split('setWaypointDescription "'+description+'";')[1].split('} forEach _teams;')[0]
            self.assertIn('Waldo_CortexQA_Label',stage)
            self.assertIn(label,stage)

    def test_support_release_retires_only_owned_stop_not_new_bound(self):
        maintain=source('cortexSupportMaintain')
        self.assertIn('if (!_coordinating && {_x != leader _group} && {currentCommand _x == "STOP"})',maintain)
        for name in ['cortexSupportMaintain','cortexRestoreCalm']:
            text=source(name)
            self.assertIn('group _x == _group',text)
            self.assertIn('currentCommand _x == "STOP"',text)

    def test_feature_fixtures_are_staged_and_dispatched(self):
        from check_cortex_coverage import audit
        data,errors,pending=audit(ROOT)
        self.assertEqual(errors,[])
        self.assertEqual(len(data['cases']),56)
        self.assertIn('COORD',pending)
        crossing=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCrossing.sqf').read_text()
        for marker in ['CROSS-engine-road-prerequisite','CROSS-natural-contact-prerequisite',
                       'CROSS-real-smoke-projectile','CROSS-all-members-physical-far-side']:
            self.assertIn(marker,crossing)
        self.assertNotIn(' reveal ',crossing.split('*/',1)[1])

    def test_coordinated_handoffs_do_not_stack_fixed_tactical_pauses(self):
        text = source('cortexFlankStep')
        self.assertIn('private _teamPause=if (_support) then {0} else', text)
        self.assertIn('private _pause = if (_support) then {0} else', text)
        self.assertIn('if (_arrived) then {', text)
        self.assertNotIn('case "GRENADE": {', text)
        self.assertIn('private _teamPause=if (_support) then {0} else', text)

    def test_native_waypoint_return_uses_bounded_recovery_without_editing_waypoints(self):
        text = source('cortexFlankStep')
        guard = text.split('private _returnedToWaypoint =')[1].split('if (_now-(_last select 3) > _timeout)')[0]
        for required in ['currentWaypoint _group ==', 'isEqualTo (_waypoint select 1)',
                         'expectedDestination _unit', '(_retry select 0) < 2',
                         '_now-(_retry select 1) >= 8']:
            self.assertIn(required, guard)
        self.assertNotIn('setWaypoint', text)
        self.assertNotIn('deleteWaypoint', text)
        self.assertLess(text.index('Waldo_fnc_CortexIsEligible'), text.index('private _returnedToWaypoint'))

    def test_bound_handoff_does_not_issue_competing_formation_orders(self):
        text = source('cortexFlankStep')
        issue = text.split('private _issue = {')[1].split('private _result =')[0]
        self.assertNotIn('_unit doFollow', issue)
        self.assertNotIn('setUnitCombatMode "BLUE"', issue)
        self.assertIn('_unit doMove _spot', issue)
        self.assertIn('_combatModes pushBack [_unit,"RED","YELLOW"]', issue)

    def test_cancelled_throw_does_not_block_assault_progression(self):
        throw = source('cortexThrowGrenade')
        self.assertIn('setVariable ["Waldo_Cortex_FragCancelled",_drillToken]', throw)
        self.assertIn('exitWith {call _cancel}', throw)
        self.assertIn('if (_thrown) exitWith {};', throw)
        self.assertNotIn('if (_thrown) exitWith {call _cancel}', throw)
        step = source('cortexFlankStep')
        self.assertNotIn('getVariable ["Waldo_Cortex_FragCancelled",""]) == _token', step)
        self.assertNotIn('"GRENADE_UNRESOLVED" call _end', step)
        self.assertIn('_drill set ["stage","PAUSE"]', step)

    def test_flank_routes_avoid_friendly_support_fire_corridors(self):
        start = source('cortexFlankStart')
        for marker in ['private _supportOrigins = []', 'knowsAbout _target > 0.5',
                       'private _crossesFireLane = {', '_lateral < 18',
                       '[1,110,90]', '!([_candidate] call _crossesFireLane)']:
            self.assertIn(marker, start)
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runMultiManoeuvre.sqf').read_text()
        self.assertIn('private _fireLaneCrossings=[0,0]',qa)
        self.assertIn('-no-support-fire-lane-crossing',qa)
        self.assertIn('_lateral < 18',qa)

    def test_previous_holders_cannot_follow_over_replacement_drill(self):
        text = source('cortexGroupTick')
        self.assertIn('_ownedMovers = _activeDrill getOrDefault ["units",[]]', text)
        self.assertIn('!(_x in _ownedMovers)', text)
        self.assertIn('if (_holders isNotEqualTo [] && {!(_state getOrDefault ["assaulting",false])})', text)
        self.assertLess(text.index('!(_x in _ownedMovers)'), text.index('{_x doFollow _leader} forEach _rejoin'))

    def test_coordinated_report_fire_requires_live_matching_lease(self):
        text = source('cortexFireControl')
        for guard in ['(_role select 0) == (_lease select 0)', 'serverTime < (_lease select 2)',
                      '"supportToken"', 'Waldo_AIPass_CoordinatedAssault_Enable',
                      '_enemies isEqualTo [] && {_reported isEqualTo []}',
                      'Waldo_fnc_CortexLineOfFireClear']:
            self.assertIn(guard, text)
        self.assertNotIn(' reveal ', text)
        self.assertIn('private _suppressPos = +_reported;', text)

    def test_moving_behaviour_override_survives_checkpoint_and_cleans_up(self):
        step = source("cortexFlankStep")
        self.assertIn('_unit setCombatBehaviour "AWARE"', step)
        self.assertIn('_disabled pushBack [_unit,"AUTOCOMBAT"]', step)
        self.assertIn('_combatBehaviours pushBack [_unit,"COMBAT","AWARE"]', step)
        self.assertIn('"restoreCombatBehaviours"', source("cortexCheckpoint"))
        for name in ["cortexFlankStep", "cortexFlankEnd", "cortexLocality"]:
            self.assertIn('behaviour _unit == _owned', source(name))
            self.assertIn('_unit setCombatBehaviour _previous', source(name))

    def test_recovery_qa_measures_continuation_after_separation(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        event=qa.split('if (!_observedRecovery && {_blockedActor in _recoveryActors}) then {')[1].split('};')[0]
        self.assertIn('getPosATL _x', event)
        self.assertIn('_restOrigins =', event)
        self.assertIn('-continued-with-blocked-actor', qa)
        self.assertIn('-physical-rejoin', qa)

    def test_rejoining_actors_keep_movement_ownership_during_halts(self):
        for name in ['cortexFireControl', 'cortexAntiArmour']:
            text = source(name)
            self.assertIn('getOrDefault ["recovery",[]]', text)
            self.assertIn('!(_x in _recovering)', text)
        text = source('cortexFireControl')
        self.assertIn('in ["START","MOVE"]', text)
        self.assertIn('Waldo_fnc_CortexCombatEffective', text)

    def test_stragglers_remain_tracked_and_cannot_count_as_complete(self):
        step = source('cortexFlankStep')
        self.assertIn('count (_units - _blocked) >= 2', step)
        self.assertIn('ceil (count _originalElement * 0.6)', step)
        self.assertIn('_teams select (_drill getOrDefault ["teamTurn",0])', step)
        self.assertIn('_teams findIf {_actor in _x}', step)
        self.assertIn('(_teams select _teamIndex) select {_x in _main}', step)
        self.assertNotIn('ceil (count _units * 0.6)', step)
        self.assertIn('_attempts < 6', step)
        self.assertIn('_units = _units - _recovering', step)
        end = source('cortexFlankEnd')
        self.assertIn('_reason = "PARTIAL"', end)
        self.assertIn('forEach (_members-_stragglers)', end)
        self.assertIn('{_x doFollow leader _group} forEach _stragglers', end)

    def test_manoeuvre_elements_reinforce_and_rebalance_after_casualties(self):
        step=source('cortexFlankStep')
        for marker in ['private _fitSquad=', 'private _rankCandidates=',
                       'Waldo_Cortex_DrillReinforcements', 'TEAM_1_REBALANCE',
                       'TEAM_2_REBALANCE', '_drill set ["stage","START"]',
                       'private _ownedPathUnits=']:
            self.assertIn(marker,step)
        self.assertIn('_x checkAIFeature "PATH" || {_x in _ownedPathUnits}',step)
        self.assertNotIn('addEventHandler ["Killed"',step)
        self.assertIn('["desiredStrength",count _element]',source('cortexFlankStart'))
        self.assertIn('["teamSizes",[count _element,count _coverElement]]',source('cortexAdvanceStart'))
        self.assertIn('["teamSizes",[count _first,count _second]]',source('cortexSupportBoundStart'))

    def test_bound_retry_is_finite_and_does_not_fabricate_progress(self):
        text = source('cortexFlankStep')
        retry = text.split('private _retry = _retries select _forEachIndex;')[1].split('if (_now-(_last select 3) > _timeout)')[0]
        self.assertIn('(_retry select 0) < 2', retry)
        self.assertIn('_now-(_retry select 1) >= 8', retry)
        self.assertIn('checkAIFeature "PATH"', retry)
        self.assertNotIn('_last set', retry)
        self.assertNotIn('setPos', retry)
        self.assertNotIn('_arrived = true', retry)

    def test_anti_armour_respects_movement_and_holding_ownership(self):
        text = source('cortexAntiArmour')
        self.assertIn('!(_x in _moving)', text)
        self.assertIn('Waldo_fnc_CortexCombatEffective', text)
        blocked = text.split('// Holding/clearing owns the destination')[1]
        for guard in ['checkAIFeature "PATH"', 'checkAIFeature "MOVE"',
                      'Waldo_AIPass_Garrison', 'Waldo_AIPass_Defend', 'Waldo_AIPass_ClearBuilding']:
            self.assertLess(blocked.index(guard), blocked.index('_gunner doMove'))

    def test_calm_ends_drill_before_discarding_restoration_checkpoint(self):
        text = source('cortexRestoreCalm')
        end = text.index('[_group,_state,"CALM"] call Waldo_fnc_CortexFlankEnd')
        self.assertLess(end, text.index('call Waldo_fnc_CortexGroupMoveClear'))
        self.assertLess(end, text.index('setVariable ["Waldo_AIPass_Checkpoint", [], true]'))
        cleanup = source('cortexFlankEnd')
        self.assertIn('_unit enableAI _feature', cleanup)
        self.assertIn('_state deleteAt "drill"', cleanup)

    def test_master_stop_cancels_explicit_orders_on_their_owner(self):
        text = source('cortexStop')
        cleanup = text.split('if (local _x) then {\n')[1].split('};')[0]
        for function in ['CortexDefendRelease', 'CortexGarrisonRelease', 'CortexClearRelease']:
            self.assertIn('call Waldo_fnc_' + function, cleanup)
        for name, assignment in [('cortexDefendRelease', 'Defend'), ('cortexGarrisonRelease', 'Garrison')]:
            self.assertIn('setVariable ["Waldo_AIPass_' + assignment + '", nil, true]', source(name))
        qa = (ROOT/'releaseVerificationAndDeployment/cortexQA/runLifecycle.sqf').read_text(encoding='utf-8')
        self.assertIn('LIFE-no-old-order-resurrection', qa)
        self.assertIn('_drift <= 12', qa)

    def test_refused_migration_preserves_existing_owner_registry(self):
        text = (ROOT/'MissionScripts/Headless/headlessMigrateGroup.sqf').read_text(encoding='utf-8')
        refusal = text.split('if (_targetOwner != 2 && {_serverOwned}) exitWith {')[1].split('private _recordFailure')[0]
        self.assertNotIn('call _removeRegistryEntry', refusal)
        self.assertNotIn('setGroupOwner', refusal)
        self.assertIn('MIGRATE_BLOCKED', refusal)
        self.assertIn('if (_finalOwner == 2) then {[] call _removeRegistryEntry}', text)

    def test_reinforcement_readiness_requires_physical_squad_arrival(self):
        text=source('cortexSupportMaintain')
        arrival=text.split('// Contact can begin before the rally is reached.')[1]
        self.assertIn('count _fit >= 3', arrival)
        self.assertIn('_fit findIf {_x distance2D (_lease select 3) > 45} < 0', arrival)
        self.assertNotIn('currentWaypoint', arrival)
        self.assertIn('supportToken', arrival)

    def test_contact_does_not_revoke_reserved_rally(self):
        text=source('cortexGroupTick')
        enter=text.split('private _enterContact = {')[1].split('private _beginContact = {')[0]
        self.assertNotIn('CortexGroupMoveClear', enter)
        self.assertNotIn('set ["responding", false]', enter)
        self.assertIn('!(_state getOrDefault ["responding", false]) && {!(_state getOrDefault ["assaulting", false])}', text)
        maintain=source('cortexSupportMaintain')
        arrival=maintain.split('// Contact can begin before the rally is reached.')[1]
        self.assertNotIn('"CALM"', arrival)
        self.assertIn('"supportToken"', arrival)

    def test_empty_coordinated_dispatch_does_not_consume_engagement(self):
        server=source('cortexSupportAssaultServer')
        self.assertIn('if (_sent > 0) then {_job set ["assaultIssued",true];', server)
        requester=source('cortexCoordinatedAssault')
        self.assertIn('if (_status select 3) then {_acknowledged = true}', requester)
        self.assertIn('if (_acknowledged) exitWith {_state set ["coordinated",true]; 0}', requester)
        self.assertIn('[_state,"coordinated",10] call Waldo_fnc_CortexCooldown', requester)

    def test_combined_roles_use_owned_fire_team_drills_and_restore_holds(self):
        coordinator=source('cortexSupportCoordinateStep')
        self.assertNotIn('allUnits',coordinator)
        self.assertNotIn('allGroups',coordinator)
        self.assertIn('if (_old isNotEqualTo _role)',coordinator)
        self.assertIn('(_result select 0) == _token',coordinator)
        self.assertIn('serverTime+15',coordinator)
        self.assertIn('private _failuresByToken=',coordinator)
        self.assertIn('_outcome in ["COMPLETE","PARTIAL"]',coordinator)
        self.assertIn('_retired pushBackUnique _token',coordinator)
        self.assertIn('if (_failures >= 2)',coordinator)
        self.assertNotIn('_job set ["coordinationAborted",true]',coordinator)
        self.assertIn('private _boundLength=(_remaining*0.35) max 45 min 70',coordinator)
        start=source('cortexSupportBoundStart')
        self.assertIn('["teams",[_first,_second]]',start)
        self.assertIn('["SUPPORT_BOUND","FINAL"] select _final',start)
        self.assertIn('Waldo_fnc_CortexFlankStep',start)
        self.assertIn('"supportHeld"',source('cortexCheckpoint'))
        for name in ['cortexRetreat','cortexRestoreCalm']:
            self.assertIn('"supportHeld"',source(name))
            self.assertIn('Waldo_fnc_CortexSupportAck',source(name))
        step=source('cortexFlankStep')
        self.assertIn('(_supportRole select 1) == (_drill get "supportSequence")',step)
        self.assertIn('Waldo_AIPass_CoordinatedAssault_Enable',step)
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCoordinated.sqf').read_text(encoding='utf-8')
        for check in ['COORD-inter-squad-role-exchange','COORD-inter-squad-physical-cover','COORD-intra-squad-physical-cover']:
            self.assertIn(check,qa)
        self.assertIn('abs speed _x > 2',qa)
        self.assertIn('_shots-(_shotCounts select _i)',qa)

    def test_assault_attack_setting_is_captured_and_restored(self):
        apply=source('cortexSupportApply')
        self.assertIn('if (_attackAllowed && {!("baseAttack" in _state)})', apply)
        self.assertIn('set ["baseAttack",attackEnabled _group]', apply)
        self.assertIn('if (_attackAllowed && {attackEnabled _group})', apply)
        maintain=source('cortexSupportMaintain')
        self.assertEqual(2, maintain.count('call _restoreAttack;'))
        self.assertIn('enableAttack (_state getOrDefault ["baseAttack",true])', maintain)
        self.assertIn('"baseAttack", "attackChanged"', source('cortexCheckpoint'))
        self.assertIn('enableAttack (_state getOrDefault ["baseAttack",true])', source('cortexRestoreCalm'))

    def test_zeus_takeover_releases_explicit_orders_without_waypoint(self):
        text=source('cortexGroupTick').split('if !([_group] call Waldo_fnc_CortexIsEligible)')[1].split('// Survivor regroup')[0]
        self.assertIn('if ([_group] call Waldo_fnc_CortexZeusHeld) then', text)
        for name in ['CortexGarrisonRelease','CortexDefendRelease','CortexClearRelease']:
            self.assertIn('call Waldo_fnc_'+name, text)
        self.assertNotIn('getVariable ["Waldo_AIPass_ZeusWaypoints"', text)

    def test_garrison_duck_cleanup_preserves_later_stance(self):
        apply=source('cortexGarrisonApplyLocal')
        release=source('cortexGarrisonRelease')
        self.assertIn('if (unitPos _unit == (_unit getVariable ["Waldo_Cortex_GarrisonDuckStance", ""]))', apply)
        self.assertIn('if (unitPos _x == (_x getVariable ["Waldo_Cortex_GarrisonDuckStance", ""]))', release)
        self.assertIn('!([group _unit] call Waldo_fnc_CortexIsEligible)', apply)
        delayed=apply.split('params ["_unit", "_until"];')[1].split('}, [_unit, _until]')[0]
        self.assertIn('&& {[group _unit] call Waldo_fnc_CortexIsEligible}', delayed)
        for text in [apply, release]:
            self.assertIn('setVariable ["Waldo_Cortex_GarrisonDuckStance",nil,true]', text)

    def test_surrender_releases_orders_before_captive_handover(self):
        text=source('cortexSurrender')
        for guard in ['!local _group','Waldo_fnc_CortexIsEligible','Waldo_AIPass_Surrender_Enable']:
            self.assertLess(text.index(guard),text.index('createVehicle'))
        for release in ['CortexGarrisonRelease','CortexDefendRelease','CortexClearRelease','CortexReleaseGroup']:
            self.assertLess(text.index(release),text.index('call ace_captives_fnc_setSurrendered'))
        self.assertIn('Waldo_fnc_CortexCombatEffective',text)

    def test_grenade_evasion_regroup_does_not_overwrite_new_actions(self):
        callback=source('cortexGrenadeCheck').split('params ["_unit","_group","_spot","_hold"];')[1]
        for guard in ['group _unit != _group','vehicle _unit != _unit','Waldo_fnc_CortexCombatEffective','Waldo_AIPass_ZeusHold','expectedDestination _unit','_unit in (_drill']:
            self.assertLess(callback.index(guard),callback.index('doFollow'))

    def test_queued_grenade_rechecks_takeover_and_frag_safety(self):
        text=source('cortexThrowGrenade')
        callback=text.split('params ["_unit", "_muzzle", "_magazine"')[1]
        for guard in ['Waldo_fnc_CortexCombatEffective','Waldo_fnc_CortexIsEligible','Waldo_AIPass_ZeusHold','_magazine in magazines _unit','_distance < 8','_distance > 40','nearEntities ["CAManBase",12]']:
            self.assertIn(guard,callback)
        self.assertLess(callback.index('Waldo_AIPass_ZeusHold'),callback.index('forceWeaponFire'))
        self.assertLess(callback.index('!= _drillToken'),callback.index('forceWeaponFire'))

    def test_retreat_releases_drill_before_capturing_attack_control(self):
        text=source('cortexRetreat')
        self.assertLess(text.index('call Waldo_fnc_CortexFlankEnd'),text.index('set ["baseAttack"'))
        self.assertIn('_group enableAttack false',text)
        self.assertIn('_state set ["behaviourChanged",true]',text)
        self.assertIn('_state set ["baseBehaviour",behaviour _leader]',text)

    def test_cover_stance_bounds_rays_and_rotates_units(self):
        text=source('cortexStance')
        self.assertIn('if (_sampled >= 2) exitWith {}', text)
        self.assertIn('set ["stanceCursor",(_index+1) mod _count]', text)
        self.assertIn('setVariable ["Waldo_AIPass_StanceAt", _now + 10]', text)
        self.assertEqual(3,text.count('call _blocked;'))

    def test_cover_stance_requires_clearance_above_protection(self):
        text=source('cortexStance')
        self.assertIn('case (_lowBlocked && {!_middleBlocked}): {"MIDDLE"}', text)
        self.assertIn('case ((_lowBlocked || {_middleBlocked}) && {!_highBlocked}): {"UP"}', text)
        self.assertNotIn('case ([0.5] call _blocked): {"DOWN"}', text)
        self.assertIn('default {"AUTO"}', text)

    def test_stance_cleanup_preserves_external_override(self):
        for name in ['cortexRestoreCalm','cortexGroupTick']:
            self.assertIn('if (toUpperANSI (unitPos _x) == (_x getVariable ["Waldo_Cortex_AppliedStance",""])) then {_x setUnitPos "AUTO"}', source(name))
        stance=source('cortexStance')
        self.assertIn('_currentStance != (_unit getVariable ["Waldo_Cortex_AppliedStance",""])', stance)
        self.assertIn('setVariable ["Waldo_Cortex_AppliedStance",_stance,true]', stance)

    def test_support_movement_has_priority_over_new_drills(self):
        for name in ['cortexFlankStart', 'cortexAdvanceStart']:
            text = source(name)
            guard = 'if (_state getOrDefault ["responding", false] || {_state getOrDefault ["assaulting", false]}) exitWith {false};'
            self.assertIn(guard, text)
            self.assertLess(text.index(guard), text.index('_group enableAttack false'))

    def test_assault_contact_does_not_force_combat_mode(self):
        text = source('cortexGroupTick').split('private _beginContact = {')[1].split('switch (_state get "phase")')[0]
        guard = 'if (!(_state getOrDefault ["assaulting", false]) && {behaviour _leader in ["SAFE", "AWARE"]}) then {'
        self.assertIn(guard, text)
        self.assertLess(text.index(guard), text.index('_group setBehaviour "COMBAT"'))
        self.assertNotIn('disableAI "AUTOCOMBAT"', text)

    def test_stalled_bounds_cannot_complete_or_advance(self):
        text = source('cortexFlankStep')
        move = text.split('case "MOVE":')[1].split('case "PAUSE":')[0]
        self.assertIn('["TIME_LIMIT","STALLED"] select _stalled', move)
        self.assertIn('_result = _reason call _end', move)
        self.assertIn('if (_arrived) then', move)
        self.assertNotIn('if (_arrived ||', move)
        end = source('cortexFlankEnd')
        self.assertIn('if (_reason == "COMPLETE") then', end)
        self.assertIn('Waldo_Cortex_DrillResult', end)

    def test_drill_attack_assignment_restores_after_transfer(self):
        for name in ['cortexFlankStart','cortexAdvanceStart']:
            self.assertIn('attackEnabled _group',source(name))
            self.assertIn('_group enableAttack false',source(name))
        for name in ['cortexFlankEnd','cortexRestoreCalm']:
            self.assertIn('_group enableAttack (_state getOrDefault ["baseAttack",true])',source(name))
        self.assertIn('"baseAttack", "attackChanged"',source('cortexCheckpoint'))

    def test_every_ai_setting_has_an_acceptance_case(self):
        import re, json
        data=json.loads((ROOT/'releaseVerificationAndDeployment/cortexQA/coverage.json').read_text(encoding='utf-8'))
        actual=set(re.findall(r'^\s*\["(Waldo_[^"]+)"\s*,',(ROOT/'MissionConfig/aiConfig.sqf').read_text(encoding='utf-8'),re.M))
        declared=[key for case in data['cases'] for key in case['settings']]
        self.assertEqual(actual,set(declared))
        self.assertEqual(len(declared),len(set(declared)))
        self.assertEqual(len(data['cases']),len({case['id'] for case in data['cases']}))
        for case in data['cases']:
            self.assertTrue(case['setup'] and case['expected'])
            self.assertNotEqual(case['status'],'passed')

    def test_preflight_runs_before_order_state_changes(self):
        text = source('cortexOrderLocal')
        self.assertLess(text.index('call Waldo_fnc_CortexOrderReason'),text.index('setVariable ["Waldo_AIPass_ZeusWaypoints"'))
        self.assertIn('_oldHold',text)
        self.assertIn('false, clientOwner, "The squad changed owner',text)
    def test_exclude_cleans_all_posted_orders_immediately(self):
        text=source('cortexOrderLocal').split('case "EXCLUDE":')[1].split('case "RETURN":')[0]
        for name in ['ClearRelease','GarrisonRelease','DefendRelease','ReleaseGroup']:
            self.assertIn('Waldo_fnc_Cortex'+name,text)
    def test_no_building_garrison_cannot_report_success(self):
        text=source('cortexGarrison')
        self.assertLess(text.index('Refuse an empty search'),text.index('call Waldo_fnc_CortexClearRelease'))
    def test_selection_requires_choice_and_has_no_distance_cutoff(self):
        text=(ROOT/'MissionScripts/ZenModules/RuntimeControl/featureRuntimeZen.sqf').read_text(encoding='utf-8')
        self.assertIn('private _groups = [grpNull]',text)
        self.assertNotIn('_leader distance2D _modulePos <= 250',text)
        self.assertIn('call Waldo_fnc_CortexOrderReason',text)
    def test_snapshot_cannot_rollback_applied_ai_revision(self):
        text=(ROOT/'MissionScripts/ZenModules/RuntimeControl/featureRuntimeReceiveState.sqf').read_text(encoding='utf-8')
        self.assertIn('Waldo_AIPass_SettingsApplied',text)
        self.assertIn('_staleAI && {_name in _aiNames}',text)
    def test_expected_revision_is_sent_and_checked_on_server(self):
        self.assertIn('__expectedRevision',source('cortexControlOpenLocal'))
        text=(ROOT/'MissionScripts/ZenModules/RuntimeControl/featureRuntimeApply.sqf').read_text(encoding='utf-8')
        self.assertIn('_values deleteAt "__expectedRevision"',text)
        self.assertIn('if !(_expected isEqualTo',text)
    def test_engine_suite_uses_real_commands_and_ui_handlers(self):
        server=(ROOT/'releaseVerificationAndDeployment/cortexQA/runServer.sqf').read_text(encoding='utf-8')
        client=(ROOT/'releaseVerificationAndDeployment/cortexQA/runClient.sqf').read_text(encoding='utf-8')
        for function in ['CortexOrderDispatch','HeadlessMigrateGroup','SimpleAiConvoy','CortexArtilleryFire']:
            self.assertIn('call Waldo_fnc_'+function,server)
        self.assertIn('addEventHandler ["Fired"',server)
        self.assertIn('ctrlActivate true',client)
        self.assertNotIn('setVariable ["Waldo_AIPass_Aggression"',client)

    def test_cortex_exports_preserve_legacy_function_aliases(self):
        import re
        text=(ROOT/'MissionScripts/WaldosFunctions.sqf').read_text(encoding='utf-8')
        exports=dict(re.findall(r'class (\w+) \{file = "([^"]+)";',text))
        legacy={name:path for name,path in exports.items() if name.startswith('AIPass')}
        self.assertGreater(len(legacy),90)
        for name,path in legacy.items():
            self.assertEqual(path,exports['Cortex'+name[6:]])
            self.assertTrue((ROOT/path.replace('\\','/')).is_file(),path)
        for path in (ROOT/'MissionScripts/AiScripting/Cortex').glob('*.sqf'):
            self.assertNotIn('Waldo_fnc_AIPass',path.read_text(encoding='utf-8'))

    def test_headless_overlay_reads_one_coherent_snapshot(self):
        text=(ROOT/'MissionScripts/Headless/headlessDebugDisplayLocal.sqf').read_text(encoding='utf-8')
        self.assertNotIn('getVariable ["Waldo_Headless_ManagedGroups"',text)
        self.assertIn('TRANSFERRING',text)
        self.assertIn('private _mismatch = !_pending',text)

    def test_focused_convoy_keeps_contact_scenarios(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runServer.sqf').read_text(encoding='utf-8')
        self.assertNotIn('if (_focus != "convoy")',text)
        for case in ['AMB-01-real-enemy-fire','AMB-04-pinned-halt','AMB-07-operating-crew']:
            self.assertIn(case,text)
        for suite in ['cortexQACombat.sqf','cortexQAMechanics.sqf']:
            self.assertIn(suite,text)

    def test_garrison_recovery_does_not_require_finished_move(self):
        text=source('cortexGarrisonApplyLocal')
        self.assertIn('time-_lastProgress >= 12',text)
        self.assertIn('_retries < 2',text)
        self.assertIn('setDestination [_target,"LEADER PLANNED",true]',text)
        self.assertIn('private _nextEntry=_entryIndex+1',text)
        self.assertIn('private _target = _destination',text)
        self.assertIn('private _approach = false',text)
        self.assertIn('_entries resize ((count _entries) min 4)',text)
        self.assertIn('private _replacementEntries=',text)
        self.assertNotIn('_job set ["deadline",(_job get "deadline") max (time+60)]',text)
        self.assertNotIn('if (_openedDoor) then {_route set [3,time]',text)
        self.assertNotIn('unitReady _x',text)

    def test_building_comparison_is_additive_and_measures_arrival(self):
        server=(ROOT/'releaseVerificationAndDeployment/cortexQA/runServer.sqf').read_text(encoding='utf-8')
        self.assertIn('ORD-04b-garrison-arrival',server)
        self.assertIn('DIAG-open-door-garrison',server)
        self.assertIn('cortexQABuildings.sqf',server)
        comparison=(ROOT/'releaseVerificationAndDeployment/cortexQA/runBuildingComparison.sqf').read_text(encoding='utf-8')
        self.assertIn('_unit distance _target <= 2',comparison)
        self.assertNotIn('setPos',comparison)

    def test_consolidation_orders_follow_and_does_not_call_timeout_arrival(self):
        text=source('cortexGroupTick')
        self.assertIn('_x doFollow _leader',text)
        self.assertIn('["CONSOLIDATING", "INCOMPLETE"] select _expired',text)
        self.assertIn('_gathered == count _members',text)
        self.assertIn('call Waldo_fnc_CortexClearRelease',text)
        self.assertNotIn('distance2D _leader > 60',text)

    def test_bound_progress_uses_its_own_explicit_index(self):
        text=source('cortexFlankStep')
        self.assertNotIn('_units apply {[_x distance2D (_spots select _forEachIndex)',text)
        self.assertIn('{_progress pushBack [_x distance2D (_spots select _forEachIndex),_now,getPosATL _x,_now]} forEach _units',text)

    def test_new_visual_suites_are_staged_and_additive(self):
        server=(ROOT/'releaseVerificationAndDeployment/cortexQA/runServer.sqf').read_text(encoding='utf-8')
        launcher=(ROOT/'releaseVerificationAndDeployment/launch_pr_review_audit.ps1').read_text(encoding='utf-8')
        for suite in ['Reactions','Support','Airborne']:
            self.assertIn('cortexQA'+suite+'.sqf',server)
            self.assertIn('cortexQA/run'+suite+'.sqf',launcher)
        for case in ['ORD-04b-garrison-arrival','CNV-08-destination-halt','AMB-04-pinned-halt','ART-04-finite-burst']:
            self.assertIn(case,server)

    def test_convoy_resume_keeps_local_trails_and_does_not_project_recovery(self):
        text=(ROOT/'MissionScripts/AiScripting/convoyTick.sqf').read_text()
        self.assertIn('["frontTrails", _resumeTrails]',text)
        self.assertIn('["followers", _resumeFollowers]',text)
        self.assertNotIn('_front getPos [_desiredGap',text)
        self.assertNotIn('if (!_contact && {_stretch > 3}) then {_leadLimit = 0}',text)
        matrix=(ROOT/'releaseVerificationAndDeployment/cortexQA/runConvoyMatrix.sqf').read_text()
        for case in ['BASELINE-WHEELED','BASELINE-TRACKED','BASELINE-MIXED','-resume-forward-progress','-resume-no-turnaround','-stop-fraction']:
            self.assertIn(case,matrix)

    def test_infantry_explicit_fire_respects_group_and_unit_roe(self):
        for name in ['cortexFireControl','cortexAntiArmour']:
            text=source(name)
            self.assertIn('combatMode _group in ["YELLOW","RED"]',text)
            self.assertIn('unitCombatMode _x in ["YELLOW","RED"]',text)

    def test_convoy_spacing_does_not_trim_navigation_to_a_short_stop(self):
        text=(ROOT/'MissionScripts/AiScripting/convoyTick.sqf').read_text()
        self.assertNotIn('_frontDistance > _desiredGap * 0.7',text)
        self.assertNotIn('_frontDistance < _gap',text)
        self.assertIn('private _limit = (_frontSpeed + (_gap-_desiredGap)*0.4) max 0;',text)

    def test_convoy_snapshot_preserves_navigation_before_release(self):
        text=(ROOT/'MissionScripts/AiScripting/convoySync.sqf').read_text()
        self.assertLess(text.index('private _navigation ='),text.index('[_group, true, _configuration select 7'))
        self.assertIn('_keepCrew isEqualTo (_configuration select 4)',text)
        self.assertIn('setVariable ["Waldo_Convoy_LocalState",_navigation]',text)

    def test_convoy_matrix_checks_physical_column_and_halt_notifies_curators(self):
        matrix=(ROOT/'releaseVerificationAndDeployment/cortexQA/runConvoyMatrix.sqf').read_text()
        self.assertIn('-single-file',matrix)
        self.assertIn('_maxLateral <= 8',matrix)
        text=(ROOT/'MissionScripts/AiScripting/simpleAiConvoy.sqf').read_text()
        self.assertIn('getAssignedCuratorUnit',text)
        self.assertIn('pushBackUnique owner _curator',text)
        self.assertIn('CORTEX CONVOY STOPPED',text)
        self.assertLess(text.index('== "HALT"}) exitWith {true}'),text.index('CORTEX CONVOY STOPPED'))

    def test_remount_retries_physical_boarding_and_cancels_on_contact(self):
        restore=source('cortexRestoreCalm')
        tick=source('cortexGroupTick')
        self.assertIn('[serverTime+60,+_boarding]',restore)
        self.assertIn('serverTime >= _deadline',tick)
        self.assertIn('vehicle (_x select 0) != (_x select 1)',tick)
        self.assertIn('_visible isNotEqualTo [] || {_ordered}',tick)
        self.assertIn('orderGetIn false; unassignVehicle _unit',tick)
        self.assertNotIn('moveInCargo',tick)

    def test_stalled_convoy_halt_preserves_passengers_and_validates_vehicle(self):
        tick=(ROOT/'MissionScripts/AiScripting/convoyTick.sqf').read_text(encoding='utf-8')
        halt=(ROOT/'MissionScripts/AiScripting/convoyHaltServer.sqf').read_text(encoding='utf-8')
        api=(ROOT/'MissionScripts/AiScripting/simpleAiConvoy.sqf').read_text(encoding='utf-8')
        self.assertEqual(tick.count('if (_attempts > 3)'),2)
        self.assertNotIn('doFollow driver _front',tick)
        self.assertIn('_blockedVehicle in (_configuration select 4)',halt)
        self.assertIn('_reason != "STALLED" && {alive _unit}',api)
        self.assertNotIn('setPos',tick)
        self.assertNotIn('disableCollisionWith',tick)

    def test_convoy_can_acquire_forward_trail_beyond_initial_capture_radius(self):
        text=(ROOT/'MissionScripts/AiScripting/convoyTick.sqf').read_text(encoding='utf-8')
        self.assertIn('if (_nearest < 0)',text)
        self.assertIn('(_delta vectorDotProduct _heading) > _length*0.5',text)
        self.assertIn('_nearest + ([1,0] select _joining)',text)
        self.assertIn('if (count _state > 0 && {!_sameLine})',text)
        self.assertNotIn('driver _lead doMove (waypointPosition',text)

    def test_convoy_retains_actual_seat_for_crew_and_both_cargo_group_layouts(self):
        text=(ROOT/'MissionScripts/AiScripting/convoyCrewLocal.sqf').read_text(encoding='utf-8')
        self.assertIn('_assignedOccupant != _unit',text)
        for role in ['assignAsDriver','assignAsCommander','assignAsGunner','assignAsCargoIndex','assignAsTurret']:
            self.assertIn(role,text)
        self.assertNotIn('moveIn',text)
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runConvoySeats.sqf').read_text(encoding='utf-8')
        self.assertIn('forEach [_convoy,_cargoGroup]',qa)
        self.assertIn('addEventHandler ["GetOutMan"',qa)
        self.assertIn('SEATS-travel-no-exits',qa)
        self.assertIn('SEATS-halt-operating-crew-retained',qa)
        self.assertIn('{deleteVehicle _x} forEach _actors',qa)

    def test_deceleration_old_owner_cannot_clear_new_worker(self):
        base=ROOT/'MissionScripts/AiScripting'
        init=(base/'helicopterDecelerationInit.sqf').read_text(encoding='utf-8')
        self.assertIn('GenerationLocal",0])+1',init)
        self.assertIn('GenerationLocal",0]] spawn Waldo_fnc_HelicopterDecelerationTrackLocal',init)
        for name in ['helicopterDecelerationTrackLocal.sqf','helicopterDecelerationCorrectLocal.sqf']:
            text=(base/name).read_text(encoding='utf-8')
            self.assertIn('["_generation",-1,[0]]',text)
            cleanup=text[text.rindex('if (!isNull _aircraft'):]
            self.assertIn('local _aircraft',cleanup)
            self.assertIn('== _generation',cleanup)
        tracker=(base/'helicopterDecelerationTrackLocal.sqf').read_text(encoding='utf-8')
        after_sleep=tracker.split('uiSleep _sampleInterval;',1)[1]
        self.assertLess(after_sleep.index('!= _generation'),after_sleep.index('private _speed'))

    def test_deceleration_releases_changed_order_before_impulse(self):
        text=(ROOT/'MissionScripts/AiScripting/helicopterDecelerationCorrectLocal.sqf').read_text(encoding='utf-8')
        for marker in ['waypointPosition _wp','waypointType _wp','waypointScript _wp','waypointSpeed _wp',
                       'currentPilot _aircraft == _entryPilot','Waldo_AI_ExternalControl','ORDER_CHANGED']:
            self.assertIn(marker,text)
        self.assertIn('&& {call _ownsOrder}',text)
        self.assertLess(text.index('&& {call _ownsOrder}'),text.index('_aircraft addForce'))

    def test_deceleration_impulse_uses_elapsed_simulation_time(self):
        text=(ROOT/'MissionScripts/AiScripting/helicopterDecelerationCorrectLocal.sqf').read_text(encoding='utf-8')
        self.assertIn('time - _lastImpulseTime',text)
        self.assertIn('min 0.1',text)
        self.assertIn('min ((_climbRate - _maximumClimbRate) max 0)',text)
        self.assertNotIn('_acceleration * _interval',text)

    def test_deceleration_observes_before_braking_order(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runDeceleration.sqf').read_text(encoding='utf-8')
        self.assertLess(text.index('private _startSpeed=abs speed'), text.index('_wp setWaypointPosition'))
        self.assertLess(text.index('_id+": braking"'), text.index('private _startSpeed=abs speed'))
        for name in ['helicopterDecelerationTrackLocal','helicopterDecelerationCorrectLocal']:
            code=(ROOT/'MissionScripts/AiScripting'/f'{name}.sqf').read_text(encoding='utf-8')
            self.assertIn('Waldo_HelicopterDeceleration_IncludeVTOL',code)

    def test_new_qa_suites_are_additive_and_staged(self):
        server=(ROOT/'releaseVerificationAndDeployment/cortexQA/runServer.sqf').read_text(encoding='utf-8')
        launcher=(ROOT/'releaseVerificationAndDeployment/launch_pr_review_audit.ps1').read_text(encoding='utf-8')
        for name in ['Deceleration','Aircraft','Lifecycle','Coordinated','Profiles','Scheduler','ArtillerySmoke','Contact','Avoidance','Landing','Cover','Gates','Gunnery','Seats','Buildings','ConvoyMatrix','Combat','Mechanics','Reactions','Support','Airborne','Vehicles','Fire']:
            self.assertIn('cortexQA'+name+'.sqf',server)
            self.assertIn('cortexQA'+name+'.sqf',launcher)
        matrix=(ROOT/'releaseVerificationAndDeployment/cortexQA/runConvoyMatrix.sqf').read_text(encoding='utf-8')
        self.assertIn('{deleteVehicle (_x select 0)} forEach _fixtureCrew',matrix)
        self.assertIn('-operating-crew-retained',matrix)

    def test_drill_steps_cannot_adopt_a_replacement_action(self):
        step=source('cortexFlankStep')
        self.assertLess(step.index('private _token ='),step.index('private _end ='))
        self.assertIn('_token != (_drill getOrDefault ["token",""])',step)
        for name in ['cortexFlankStart','cortexAdvanceStart']:
            code=source(name)
            self.assertIn('["token",_token]',code)
            self.assertIn('["drillToken",_token]',code)
            self.assertIn('Waldo_Cortex_DrillSerial',code)
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('-stale-step-no-mutation',qa)
        self.assertIn('_before isEqualTo _after',qa)

    def test_drill_failure_distinguishes_progress_timeout_and_qa_expiry(self):
        step=source('cortexFlankStep')
        self.assertIn('["TIME_LIMIT","STALLED"] select _stalled',step)
        self.assertIn('(_last select 0)-_remaining >= 0.5',step)
        self.assertIn('Waldo_Cortex_DrillFailure',step)
        self.assertIn('currentCommand _unit,expectedDestination _unit',step)
        self.assertIn('_now-(_last select 3) > _timeout',step)
        self.assertIn('_unit distance2D (_last select 2) >= 0.5',step)
        self.assertNotIn('_combatModes pushBack [_unit,"RED","BLUE"]',step)
        self.assertNotIn('_group setCombatMode',step)
        self.assertIn('_unit disableAI "AUTOTARGET"',step)
        self.assertIn('_disabled pushBack [_unit,"AUTOTARGET"]',step)
        self.assertIn('_disabled pushBack [_unit,"TARGET"]',step)
        for capability in ['WEAPONAIM', 'FIREWEAPON']:
            self.assertNotIn(f'_unit disableAI "{capability}"',step)
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('-observation-completed',qa)
        coordinated=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCoordinated.sqf').read_text()
        for marker in ['COORD-base-actual-supporting-fire','COORD-team-%1-actual-fire','from 0 to 5','from 1 to 5']:
            self.assertIn(marker,coordinated)

    def test_successive_advance_exchanges_only_after_arrival(self):
        start=source('cortexAdvanceStart')
        step=source('cortexFlankStep')
        self.assertIn('["teams",[_element,_coverElement]]',start)
        self.assertIn('["units", _onFoot]',start)
        self.assertIn('_drill set ["teamTurn",1]',step)
        self.assertIn('if (_arrived) then',step)
        self.assertIn('forEach (_fit - _units)',step)
        self.assertIn('[-8,8] select',step)
        fire=source('cortexFireControl')
        self.assertIn('_drill getOrDefault ["movers",_drill getOrDefault ["units",[]]]',fire)
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        for marker in ['-both-elements-bounded','-cover-held-during-bounds','-actual-covering-fire']:
            self.assertIn(marker,qa)

    def test_assault_transition_covers_advance_and_crosses_fixed_objective(self):
        step=source('cortexFlankStep')
        hold=step[step.index('    case "HOLD":'):]
        self.assertNotIn('== "FLANK"',hold.split('private _assault =')[1].split('private _assaultDirection')[0])
        self.assertIn('_enemyPos getPos [20, _assaultDirection]',hold)
        self.assertIn('["assaultObjective",+_enemyPos]',hold)
        self.assertIn('_drill get "assaultDirection"',step)
        self.assertIn('if (_assaulting && {!_assaultEnabled})',step)
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('-physical-clear-through',qa)
        self.assertIn('vectorDotProduct _forward) < 10',qa)
        self.assertIn('count _clearThroughTeams >= ([1,2] select _advance)',qa)

    def test_assault_frag_is_opportunistic_and_never_blocks_movement(self):
        step=source('cortexFlankStep')
        hold=step[step.index('    case "HOLD":'):]
        self.assertNotIn('"FRAG"',hold)
        self.assertIn('case "ASSAULT": {',step)
        self.assertNotIn('case "GRENADE": {',step)
        self.assertNotIn('"GRENADE_UNRESOLVED" call _end',step)
        self.assertIn('_drill set ["stage","PAUSE"]',step)
        self.assertIn('_drill set ["grenadeActionUntil",[_now,_now+2] select _queued]',step)
        grenade=source('cortexThrowGrenade')
        self.assertIn('addEventHandler ["FiredMan"',grenade)
        self.assertIn('removeEventHandler ["FiredMan",_thisEventHandler]',grenade)
        self.assertIn('[_unit,_handler],10',grenade)

    def test_combat_grenade_qa_measures_projectile_and_hold(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        for marker in ['FLANK-GRENADE','-actual-frag-deployed','-physical-grenade-hold','-no-crossing-live-frag',
                       '_records pushBack [_projectile,time,getPosATL _unit]', '_grenadeHoldDrift <= 3',
                       'time-(_x select 1) < 8']:
            self.assertIn(marker,qa)
        self.assertIn('["Waldo_AIPass_Assault_Enable",_case != "ADVANCE-CLOSE"]',qa)

    def test_grenade_hold_times_actual_deployment_and_cleans_owned_listener(self):
        self.assertIn('_flight set [4,time]',source('cortexThrowGrenade'))
        self.assertNotIn('((_flight select 4)+8)',source('cortexFlankStep'))
        end=source('cortexFlankEnd')
        self.assertIn('(_flight select 0) == (_drill getOrDefault ["token",""])',end)
        self.assertIn('removeEventHandler ["FiredMan",_handler]',end)

    def test_pending_assault_frag_rechecks_gate_and_migration_retires_listener(self):
        grenade=source('cortexThrowGrenade')
        callback=grenade[grenade.index('params ["_unit", "_muzzle"'):]
        self.assertIn('Waldo_AIPass_Assault_Enable',callback)
        self.assertLess(callback.index('Waldo_AIPass_Assault_Enable'),callback.index('forceWeaponFire'))
        locality=source('cortexLocality')
        self.assertIn('removeEventHandler ["FiredMan",_fragHandler]',locality)
        self.assertLess(locality.index('Waldo_Cortex_FragHandler'),locality.index('if (!_gained'))

    def test_reaction_qa_keeps_previous_cancellations_and_adds_assault_disable(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runReactions.sqf').read_text()
        self.assertIn('["CAPTIVE","ZEUS","DRILL-REPLACED","ASSAULT-DISABLED"]',qa)
        self.assertIn('_shots == 0',qa)
        self.assertIn('_after == _before',qa)
        self.assertIn('["Waldo_AIPass_Assault_Enable",false]',qa)

    def test_assault_qa_requires_cover_element_to_consolidate_physically(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('-physical-consolidation',qa)
        self.assertIn('(_members - _element) apply {[_x,getPosATL _x]}',qa)
        self.assertIn('_x distance2D _clearedObjective > 35',qa)
        self.assertIn('_x distance2D leader _group > 35',qa)
        self.assertIn('(_x select 0) distance2D (_x select 1) < 30',qa)

    def test_flank_consolidates_support_through_existing_movement_job(self):
        step=source('cortexFlankStep')
        self.assertIn('private _allUnits = +_units;',step)
        self.assertIn('private _fit = +_allUnits;',step)
        self.assertLess(step.index('private _allUnits = +_units;'),step.index('private _fit = +_allUnits;'))
        self.assertNotIn('private _fit = +_units;',step)
        self.assertIn('_points pushBack [_rally,"CONSOLIDATE"]',step)
        self.assertIn('_drill set ["units",_allUnits + _support]',step)
        self.assertIn('_teams = [+_allUnits,+_support]',step)
        self.assertIn('_drill set ["teamTurn",1]',step)
        self.assertIn('case "CONSOLIDATE": {',step)
        self.assertIn('_drill set ["finishFlank",true]',step)
        self.assertIn('else {+_centroid}',step)
        self.assertIn('getOrDefault ["consolidating",false]) exitWith {_result = "COMPLETE" call _end}',step)
        self.assertIn('getPos [12,_drill get "assaultDirection"]',step)

    def test_bound_progresses_on_physical_role_quorum_and_recovers_laggards(self):
        step=source('cortexFlankStep')
        self.assertIn('private _minimumArrivals = (ceil (count _originalElement * 0.6)) max 2;',step)
        self.assertIn('_now - (_drill get "boundStart") >= 6',step)
        self.assertIn('count _arrivedUnits >= _minimumArrivals',step)
        self.assertIn('private _stragglers = _units - _arrivedUnits;',step)
        self.assertIn('_recovery pushBack [_straggler,0,_now]',step)
        self.assertIn('Bound role complete',step)
        self.assertNotIn('setPos',step)

    def test_late_combat_result_preserves_deadline_and_measures_consolidation(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('-late-physical-consolidation',qa)
        self.assertIn('_ending = +_lateResult',qa)
        self.assertIn('["LATE: STILL RUNNING","LATE: ENDED"] select _lateEnded',qa)
        self.assertLess(qa.index('-observation-completed'),qa.index('_ending = +_lateResult'))

    def test_grenade_thrower_is_not_retasked_by_fire_or_antiarmour(self):
        for name in ['cortexFireControl','cortexAntiArmour']:
            code=source(name)
            self.assertIn('getOrDefault ["grenadeActionUntil",-1]',code)
            self.assertIn('pushBackUnique (_drill getOrDefault ["grenadeThrower",objNull])',code)

    def test_combat_mode_fixture_waits_and_reports_expected_and_actual_modes(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('-fixture-combat-mode',qa)
        self.assertLess(qa.index('private _modeReady'),qa.index('private _originalModes'))
        self.assertIn('_members findIf {unitCombatMode _x != _fixtureCombatMode}',qa)
        self.assertIn('_originalModes apply {[netId (_x select 0),_x select 1]}',qa)

    def test_consolidation_handover_requires_support_movement(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('FLANK-ZEUS-CONSOLIDATE',qa)
        self.assertIn('_interruptionActors = +(_live getOrDefault ["movers",[]])',qa)
        self.assertIn('_x in _interruptionActors && {_x distance2D (_origins select _forEachIndex) >= 8}',qa)
        self.assertIn('_stageReady && {_travel}',qa)

    def test_assault_approach_leaves_margin_for_frag_exclusion(self):
        step=source('cortexFlankStep')
        self.assertIn('_enemyPos getPos [20, _assaultDirection + 180]',step)
        grenade=source('cortexThrowGrenade')
        self.assertIn('nearEntities ["CAManBase",12]',grenade)

    def test_assault_checks_carriers_across_both_arrived_elements(self):
        step=source('cortexFlankStep')
        assault=step[step.index('case "ASSAULT": {'):step.index('case "CONSOLIDATE": {')]
        self.assertIn('private _throwers = _fit select',assault)
        self.assertIn('call Waldo_fnc_CortexThrowGrenade) exitWith',assault)
        self.assertNotIn('selectRandom',assault)

    def test_advance_grenade_case_requires_first_element_actual_throw(self):
        qa=(ROOT/'releaseVerificationAndDeployment/cortexQA/runCombat.sqf').read_text()
        self.assertIn('ADVANCE-GRENADE',qa)
        self.assertIn('_singleCarrier = (_teams select 0) select 0',qa)
        self.assertIn('_unit removeMagazine _x',qa)
        self.assertIn('-first-element-carrier-fired',qa)
        self.assertIn('count (_singleCarrier getVariable ["Waldo_CortexQA_FragShots",[]]) > 0',qa)

    def test_event_jobs_adopt_before_reserving_and_queuing(self):
        for name, reservation in [
            ('cortexRegroupOnKill', '_group setVariable ["Waldo_AIPass_RegroupQueued", true]'),
            ('cortexAirborneCheck', '_aircraft setVariable ["Waldo_AIPass_DropUntil", time + 30')]:
            text = source(name)
            adoption = text.index('[_group,true] call Waldo_fnc_CortexLocality')
            self.assertLess(adoption, text.index(reservation))
            self.assertLess(adoption, text.index('] call Waldo_fnc_CortexQueueJob'))

    def test_attack_run_flares_are_separate_gated_owner_job(self):
        text=source('cortexAttackRunFlares')
        for requirement in ['local _aircraft','CortexIsEligible','CortexAircraftEligible','Waldo_Cortex_AttackRunFlares_Enable','isTouchingGround','vectorDotProduct','closest','APPROACH','DEPARTURE','serverTime+30','CortexFireCountermeasure']:
            self.assertIn(requirement,text)
        self.assertNotIn('reveal ',text)
        self.assertNotIn('setVelocity',text)
        self.assertNotIn('addWaypoint',text)
        for name in ['featureRuntimeApply','featureRuntimeRequestState']:
            transport=(ROOT/'MissionScripts/ZenModules/RuntimeControl'/f'{name}.sqf').read_text()
            self.assertIn('Waldo_Cortex_AttackRunFlares_Enable',transport)

    def test_attack_flare_audit_preserves_missile_cases_and_uses_real_flight(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runAircraft.sqf').read_text()
        for item in ['AIR-paired-real-threats','O_Heli_Attack_02_dynamicLoadout_F','O_Plane_CAS_02_dynamicLoadout_F','-physical-flight','-approach-release','-departure-release','-ammunition-consumed','-no-cortex-release','addEventHandler ["Fired"']:
            self.assertIn(item,text)
        self.assertNotIn('call Waldo_fnc_CortexAttackRunFlares',text)
        self.assertNotIn('call Waldo_fnc_CortexFireCountermeasure',text)
        stop=source('cortexStop')
        self.assertLess(stop.index('Waldo_Cortex_AttackFlareJob'),stop.index('if (!isNull _group) then',stop.index('private _jobs')))

    def test_onboard_reports_are_expiring_owner_validated_cargo_only(self):
        text=source('cortexOnboardContact')
        for item in ['groupOwner _reporter == _owner','group effectiveCommander _vehicle == _reporter','serverTime < _expiry','CortexPassengerReady','CortexIsEligible','CortexRestoreCalm']:
            self.assertIn(item,text)
        self.assertLess(text.index('_state set ["dismounted"'),text.index('doGetOut'))
        self.assertNotIn(' reveal ',text)
        self.assertNotIn('doMove',text)
        tick=source('cortexGroupTick')
        self.assertIn('_nearTier && {!_ordered} && {!_lambsCombat} && {_visible isEqualTo []}',tick)

    def test_countermeasure_inventory_includes_modded_person_turrets(self):
        for name in ['cortexFireCountermeasure','cortexVehicles']:
            text=source(name)
            self.assertIn('allTurrets [_vehicle, true]',text)
            self.assertNotIn('allTurrets [_vehicle, false]',text)

    def test_passenger_migration_retains_intent_without_immediate_boarding(self):
        text=source('cortexLocality')
        self.assertIn('_adopted set ["dismounted",_passengers]',text)
        self.assertIn('assignedVehicle _unit == _vehicle',text)
        self.assertIn('_adopted set ["onboardContactUntil",serverTime+30]',text)
        self.assertNotIn('orderGetIn true',text)

    def test_passenger_audit_checks_readiness_and_fixture_motion(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runVehicleDrills.sqf').read_text()
        self.assertLess(text.index('DISMOUNT-fixture-controller-ready'),text.index('private _enemyGroup=createGroup'))
        for item in ['DISMOUNT-fixture-stationary-held','DISMOUNT-fixture-safe-stop-observed','REMOUNT-group-membership-independent','REMOUNT-original-groups-retained']:
            self.assertIn(item,text)

    def test_stationary_passenger_comparison_is_explicit_and_additive(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runVehicleDrills.sqf').read_text()
        self.assertIn('if (_stationary) then {(driver _truck) disableAI "PATH"}',text)
        self.assertIn('DISMOUNT-crew-report-physical-exit',text)
        self.assertIn('_driverDetected && {_enabledStartedMounted} && {_dismounted} && {_ownedExit}',text)
        self.assertIn('DISMOUNT-contact-physical-exit',text)
        self.assertIn('[false,true],[true,true],[false,true,false,true]',text)

    def test_contact_transition_audit_requires_physical_search_and_resumption(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runContact.sqf').read_text()
        for case in ['CONTACT-natural-reacquisition','TRANS-contact-postcontact-sequence','TRANS-search-physical-approach','TRANS-regroup-physical-cohesion','TRANS-calm-new-orders-physical-arrival','TRANS-no-old-search-order-resurrection']:
            self.assertIn(case,text)
        self.assertIn('_searchTravel >= 15 && {_searchApproach}',text)
        self.assertNotIn('_state set ["phase"',text)
        self.assertNotIn('call Waldo_fnc_CortexRestoreCalm',text)

    def test_calm_cleanup_retires_onboard_contact_deadline(self):
        text=source('cortexRestoreCalm')
        cleanup=text[text.index('{_state deleteAt _x} forEach [',text.index('private _boarding')):]
        self.assertIn('"onboardContactUntil"',cleanup)

    def test_attack_flare_ammo_check_counts_only_actual_countermeasure_magazines(self):
        text=(ROOT/'releaseVerificationAndDeployment/cortexQA/runAircraft.sqf').read_text()
        self.assertIn('_firedMagazines pushBackUnique (_x select 4)',text)
        self.assertIn('if ((_x select 0) in _firedMagazines)',text)
        self.assertIn('_magazinesBefore getOrDefault [_x,0]',text)
