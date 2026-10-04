/*
 * Author: WaldoTheWarfighter
 * Passenger, naval landing, pending calm remount, active coordinated-support, post-contact movement
 * and active withdrawal intent survive migration without replaying old owner jobs. Invalidates old jobs,
 * restores interrupted transient behaviour and resumes a bounded support assignment,
 * investigation, search or withdrawal after WMP or ACE migration. A Zeus hold or the
 * matching infantry-morale/vehicle-withdrawal gate cancels restoration so migration cannot revive
 * superseded work or incorrectly couple the two withdrawal types.
 * Locality/authority: current group owner unless stated otherwise below.
 * Repeat/JIP: durable restoration data is public; local jobs are never replayed verbatim. A calm
 * remount keeps its original deadline and vehicle, and yields to Zeus or a newer assignment.
 * Combat-mode restoration checks the applied value before restoring, preserving newer ROE changes.
 * Aircraft occupants are restored from any earlier ground lease but are not adopted into ground
 * transitions; their dedicated flight controllers remain the sole movement owner.
 * Arguments: 0: group <GROUP>, default grpNull; 1: gained locality <BOOL>, default false.
 * Return Value: Nothing unless a value is explicitly returned below.
 * Current callers: group Local handler and discovery.
 * Example: [_group, local _group] call Waldo_fnc_CortexLocality;
 * Result: the new owner releases stale transient controls and resumes one valid durable intent.
 */
params [["_group", grpNull, [grpNull]], ["_gained", false, [true]]];
if (isNull _group) exitWith {};
private _withdrawalIntent = _group getVariable ["Waldo_Cortex_WithdrawalIntent",[]];
private _transitionIntent = _group getVariable ["Waldo_Cortex_TransitionIntent",[]];
private _remountIntent = _group getVariable ["Waldo_Cortex_Remount",[]];
private _supportLease = _group getVariable ["Waldo_AIPass_SupportLease",[]];
private _supportStatus = _group getVariable ["Waldo_AIPass_SupportStatus",[]];
private _navalIntent = _group getVariable ["Waldo_Cortex_NavalOperation",[]];
[_group,true] call Waldo_fnc_CortexHearingLocal;
{
        private _unit = _x;
        // Event-handler IDs are machine-local. Retire this owner's listener on both
        // loss and gain; the old drill is cancelled, never replayed on the new owner.
        private _fragHandler = _unit getVariable ["Waldo_Cortex_FragHandler",-1];
        if (_fragHandler >= 0) then {_unit removeEventHandler ["FiredMan",_fragHandler]};
        _unit setVariable ["Waldo_Cortex_FragHandler",-1];
        {_unit removeEventHandler _x} forEach (_unit getVariable ["Waldo_AIPass_GarrisonHandlerIds", []]);
        _unit setVariable ["Waldo_AIPass_GarrisonHandlerIds", nil];
        _unit setVariable ["Waldo_AIPass_GarrisonHandlers", nil];
        _unit setVariable ["Waldo_AIPass_DuckUntil", nil];
        _unit setVariable ["Waldo_Cortex_ActorMove",nil];
} forEach units _group;
if (!_gained) then {[_group,false,true] call Waldo_fnc_CortexLambsBuildingRelease};
_group setVariable ["Waldo_AIPass_Epoch", (_group getVariable ["Waldo_AIPass_Epoch", 0]) + 1];
_group setVariable ["Waldo_AIPass_State", nil];
_group setVariable ["Waldo_AIPass_Managed", nil];
{_group setVariable [_x, nil]} forEach ["Waldo_AIPass_GarrisonApplied", "Waldo_AIPass_DefendApplied", "Waldo_AIPass_ClearApplied"];
_group setVariable ["Waldo_AIPass_Adopted", _gained];
if (!_gained || {!local _group}) exitWith {};
// Recovery is cancelled by adoption, not silently resumed from stale diagnostics.
if ((_group getVariable ["Waldo_Cortex_DrillRecovery",[]]) isNotEqualTo []) then {
    _group setVariable ["Waldo_Cortex_DrillRecovery",["MIGRATED",[],-1],true];
};
private _restore = createHashMapFromArray (_group getVariable ["Waldo_AIPass_Checkpoint", []]);
private _groupModeLease = _restore getOrDefault ["restoreGroupCombatMode",[]];
if (count _groupModeLease == 2 && {combatMode _group == (_groupModeLease select 1)}) then {
    _group setCombatMode (_groupModeLease select 0);
};
private _groupSpeedLease = _restore getOrDefault ["restoreGroupSpeedMode",[]];
if (count _groupSpeedLease == 2 && {speedMode _group == (_groupSpeedLease select 1)}) then {
    _group setSpeedMode (_groupSpeedLease select 0);
};
{
    _x params ["_unit", "_feature"];
    if (local _unit) then {_unit enableAI _feature};
} forEach (_restore getOrDefault ["restoreDisabled", []]);
{
    if (alive _x && {local _x} && {group _x == _group}) then {_x doFollow leader _group};
} forEach (_restore getOrDefault ["restoreMovers", []]);
{
    _x params ["_unit","_mode",["_ownedMode","BLUE"]];
    if (local _unit && {unitCombatMode _unit == _ownedMode}) then {_unit setUnitCombatMode _mode};
} forEach (_restore getOrDefault ["restoreCombatModes",[]]);
{
    _x params ["_unit","_previous","_owned"];
    if (local _unit && {behaviour _unit == _owned}) then {_unit setCombatBehaviour _previous};
} forEach (_restore getOrDefault ["restoreCombatBehaviours",[]]);
// Keep restoration intent, not engine commands, across HC ownership changes.
// A new assignment or Zeus takeover invalidates the old passenger episode.
private _passengers=(_restore getOrDefault ["dismounted",[]]) select {
    _x params ["_unit","_vehicle"];
    alive _unit && {group _unit == _group} && {alive _vehicle} && {vehicle _unit == _unit}
        && {isNull assignedVehicle _unit || {assignedVehicle _unit == _vehicle}}
};
// Do not publish an artificial CALM between owners when a durable SEARCH/INVESTIGATE or RETREAT
// episode will resume immediately below. With no resumable semantic work, force a CALM record so
// diagnostics and JIP cannot retain the old owner's stale public phase.
private _transitionResumeEligible=count _transitionIntent == 6 && {serverTime < (_transitionIntent select 3)}
    && {[_group] call Waldo_fnc_CortexIsEligible} && {!([_group] call Waldo_fnc_CortexZeusHeld)}
    && {_withdrawalIntent isEqualTo []};
if (_transitionResumeEligible) then {
    private _resumePhase=_transitionIntent select 0;
    private _resumeAreaMode=_transitionIntent select 4;
    _transitionResumeEligible=switch (_resumePhase) do {
        case "INVESTIGATE": {
            private _sourceGate=["Waldo_AIPass_ContactReports_Enable","Waldo_AIPass_Hearing_Enable"] select (_resumeAreaMode == "SOUND");
            [_group,"Waldo_AIPass_Investigate_Enable",true] call Waldo_fnc_CortexFeatureEnabled
                && {_resumeAreaMode == "" || {[_group,_sourceGate,true] call Waldo_fnc_CortexFeatureEnabled}}
        };
        case "SEARCH": {[_group,"Waldo_AIPass_PostContact_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
        default {false};
    };
};
private _withdrawalKind=_withdrawalIntent param [0,""];
private _withdrawalGateOpen=switch (_withdrawalKind) do {
    case "INFANTRY": {[_group,"Waldo_AIPass_Morale_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
    case "VEHICLE": {
        [_group,"Waldo_AIPass_Vehicles_Enable",true] call Waldo_fnc_CortexFeatureEnabled
            && {[_group,"Waldo_AIPass_VehicleWithdraw_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
    };
    default {false};
};
private _withdrawalResumeEligible=count _withdrawalIntent == 7
    && {(_withdrawalIntent select 0) in ["INFANTRY","VEHICLE"]}
    && {count (_withdrawalIntent select 2) >= 2}
    && {count (_withdrawalIntent select 3) >= 2}
    && {serverTime-(_withdrawalIntent select 4) < 120}
    && {[_group] call Waldo_fnc_CortexIsEligible}
    && {_withdrawalGateOpen}
    && {!([_group] call Waldo_fnc_CortexZeusHeld)};
[_group, _restore, false, false, "OWNERSHIP_ADOPTED",!(_transitionResumeEligible || {_withdrawalResumeEligible})] call Waldo_fnc_CortexRestoreCalm;
// The public token is semantic state only. CortexNavalAssault validates its unchanged deadline,
// plan owner and boat before issuing any replacement-owner command on the normal group tick.
if (count _navalIntent == 5 && {serverTime < (_navalIntent select 4)}
    && {[_group] call Waldo_fnc_CortexIsEligible} && {!([_group] call Waldo_fnc_CortexZeusHeld)}) then {
    private _adopted=[_group] call Waldo_fnc_CortexGroupState;
    _adopted set ["navalOperation",+_navalIntent];
    _group setVariable ["Waldo_AIPass_Checkpoint", [], true];
};
if ((_group getVariable ["Waldo_Cortex_NavalOperation",[]]) isNotEqualTo []) exitWith {};
// Aircrew have dedicated flight, countermeasure and attack controllers. A Local event handler may
// survive from the group's earlier ground phase, but ownership migration must never reconstruct
// infantry transitions, remounts or building movement while any living member occupies an aircraft.
if ((units _group) findIf {
    alive _x && {vehicle _x != _x} && {vehicle _x isKindOf "Air"}
} >= 0) exitWith {};
// A delegated building task is the active movement owner. Replay it only after old-owner calm
// restoration has finished, then stop: remount, post-contact and withdrawal intents from an older
// episode must not compete with the reconstructed building controller.
private _buildingIntent=_group getVariable ["Waldo_Cortex_BuildingIntent",[]];
if (count _buildingIntent >= 3 && {isClass (configFile >> "CfgPatches" >> "lambs_wp")}
    && {[_group] call Waldo_fnc_CortexIsEligible} && {!([_group] call Waldo_fnc_CortexZeusHeld)}) exitWith {
    _group setVariable ["Waldo_Cortex_Remount",nil,true];
    _group setVariable ["Waldo_Cortex_TransitionIntent",nil,true];
    _group setVariable ["Waldo_Cortex_WithdrawalIntent",nil,true];
    _buildingIntent params ["_buildingKind","_buildingTarget","_buildingRadius"];
    if (_buildingKind == "GARRISON") then {
        [_group,_buildingTarget,_buildingRadius] call Waldo_fnc_CortexGarrison;
    };
    if (_buildingKind == "CQB" && {_buildingTarget isEqualType objNull} && {!isNull _buildingTarget}) then {
        [_group,_buildingTarget,createHashMapFromArray [["radius",_buildingRadius]]] call Waldo_fnc_CortexClearBuilding;
    };
};
// The server-owned lease/status pair is the durable assignment. Reuse the normal support
// acceptance path so every feature gate, vehicle exclusion, LAMBS handover and movement flag keeps
// exactly one implementation. The new owner reconstructs semantics; it never replays an old job.
private _supportAdoptable=_withdrawalIntent isEqualTo [] && {_transitionIntent isEqualTo []}
    && {count _supportLease == 6} && {count _supportStatus == 4}
    && {(_supportLease select 0) == (_supportStatus select 0)}
    && {serverTime < (_supportLease select 2)} && {_supportStatus select 2}
    && {!([_group] call Waldo_fnc_CortexZeusHeld)};
if (_supportAdoptable) then {
    [createHashMapFromArray [
        ["group",_group],["lease",_supportLease],["waitUntil",serverTime],["adopt",true]
    ]] call Waldo_fnc_CortexSupportApply;
};
if (([_group] call Waldo_fnc_CortexGroupState) getOrDefault ["supportToken",""] != "") exitWith {
    _group setVariable ["Waldo_AIPass_Checkpoint", [], true];
};
if (_passengers isNotEqualTo [] && {[_group] call Waldo_fnc_CortexIsEligible}) then {
    private _adopted=[_group] call Waldo_fnc_CortexGroupState;
    _adopted set ["dismounted",_passengers];
    _adopted set ["onboardContactUntil",serverTime+30];
};
// Restore semantic boarding intent after old-owner cleanup, never its engine command. Preserve
// the original deadline so repeated transfers cannot make remount immortal. A replacement vehicle
// assignment or Zeus takeover wins and removes that actor from this attempt.
if (count _remountIntent == 2 && {serverTime < (_remountIntent select 0)}
    && {[_group] call Waldo_fnc_CortexIsEligible} && {!([_group] call Waldo_fnc_CortexZeusHeld)}) then {
    if ([_group,"Waldo_AIPass_Vehicles_Enable",true] call Waldo_fnc_CortexFeatureEnabled
        && {[_group,"Waldo_AIPass_VehicleRemount_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
        private _pendingRemount = (_remountIntent select 1) select {
            _x params ["_unit","_vehicle"];
            alive _unit && {local _unit} && {group _unit == _group} && {alive _vehicle}
                && {vehicle _unit == _unit}
                && {isNull assignedVehicle _unit || {assignedVehicle _unit == _vehicle}}
        };
        if (_pendingRemount isNotEqualTo []) then {
            _group setVariable ["Waldo_Cortex_Remount",[_remountIntent select 0,+_pendingRemount],true];
        };
    };
};
// Rebuild semantic post-contact intent, not the old owner's commands or callbacks. The original
// deadline continues across migration, preventing transfer churn from extending an episode.
if (_transitionResumeEligible) then {
    _transitionIntent params ["_transitionPhase","_target","_startedAt","_deadline","_areaMode","_savedTeam"];
    private _transitionGateOpen = switch (_transitionPhase) do {
        case "INVESTIGATE": {
            private _sourceGate = ["Waldo_AIPass_ContactReports_Enable","Waldo_AIPass_Hearing_Enable"] select (_areaMode == "SOUND");
            [_group,"Waldo_AIPass_Investigate_Enable",true] call Waldo_fnc_CortexFeatureEnabled
                && {_areaMode == "" || {[_group,_sourceGate,true] call Waldo_fnc_CortexFeatureEnabled}}
        };
        case "SEARCH": {[_group,"Waldo_AIPass_PostContact_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
        default {false};
    };
    if (_transitionGateOpen && {_transitionPhase in ["INVESTIGATE","SEARCH"]} && {count _target >= 2}) then {
        private _adopted = [_group] call Waldo_fnc_CortexGroupState;
        private _leader = leader _group;
        private _team = _savedTeam select {alive _x && {group _x == _group} && {local _x} && {vehicle _x == _x}};
        if (_transitionPhase == "SEARCH" && {_team isEqualTo []}) then {
            private _riflemen = (units _group) select {alive _x && {local _x} && {_x != _leader} && {vehicle _x == _x} && {([_x] call Waldo_fnc_CortexUnitRole) == "RIFLE"}};
            _team = _riflemen select [0,2];
            // Casualties may leave no separate search pair. Keep the physical check alive with
            // the leader instead of treating migration as successful completion.
            if (_team isEqualTo [] && {alive _leader} && {local _leader} && {vehicle _leader == _leader}) then {_team = [_leader]};
        };
        if (_team isNotEqualTo []) then {
            {_x doMove (_target getPos [4+_forEachIndex*4,random 360])} forEach _team;
        } else {
            [_group,_target getPos [30,_target getDir _leader],25] call Waldo_fnc_CortexGroupMove;
        };
        _adopted set ["baseBehaviour",behaviour _leader];
        _adopted set ["baseSpeed",speedMode _group];
        _adopted set ["behaviourChanged",false];
        _adopted set ["speedChanged",false];
        if (behaviour _leader == "SAFE") then {_group setBehaviour "AWARE"; _adopted set ["behaviourChanged",true]};
        [_group,_adopted,_transitionPhase,"OWNERSHIP_RESUME",time-((serverTime-_startedAt) max 0),true] call Waldo_fnc_CortexSetPhase;
        _adopted set ["enemyPos",+_target];
        _adopted set ["searchTeam",_team];
        if (_areaMode != "") then {_adopted set ["areaInvestigation",_areaMode]};
        _group setVariable ["Waldo_Cortex_TransitionIntent",[_transitionPhase,+_target,_startedAt,_deadline,_areaMode,+_team],true];
    } else {
        _group setVariable ["Waldo_Cortex_TransitionIntent",nil,true];
    };
} else {
    _group setVariable ["Waldo_Cortex_TransitionIntent",nil,true];
};
// The old owner's scheduled callbacks are invalid, but physical withdrawal intent is durable.
// Resume only a structurally valid, unfinished episode and let the common retreat controller
// reacquire all temporary settings. Its resume path does not repeat smoke or artillery effects.
if (_withdrawalResumeEligible) then {
    private _adopted = [_group] call Waldo_fnc_CortexGroupState;
    if ((_withdrawalIntent select 0) == "INFANTRY") then {
        [_group,_adopted,_withdrawalIntent] call Waldo_fnc_CortexRetreat;
    };
    if ((_withdrawalIntent select 0) == "VEHICLE") then {
        private _startedAt = _withdrawalIntent select 4;
        private _elapsed = (serverTime-_startedAt) max 0;
        private _target = +(_withdrawalIntent select 2);
        if !([_group,"VEHICLE_WITHDRAW",true,serverTime+((120-_elapsed) max 3)] call Waldo_fnc_CortexLambsLease) exitWith {
            _group setVariable ["Waldo_Cortex_Withdrawal",["EXTERNAL_BUSY",_withdrawalIntent select 6,_withdrawalIntent select 5],true];
        };
        [_group,_target,40] call Waldo_fnc_CortexGroupMove;
        _adopted set ["movementLease",["VEHICLE_WITHDRAW",time+((120-_elapsed) max 3)]];
        _adopted set ["enemyPos",+(_withdrawalIntent select 3)];
        _adopted set ["retreatStart",+(_withdrawalIntent select 1)];
        _adopted set ["retreatTarget",_target];
        _adopted set ["retreatProgress",[time,_withdrawalIntent select 6,_withdrawalIntent select 5]];
        [_group,_adopted,"RETREAT","VEHICLE_OWNERSHIP_RESUME",time-_elapsed,true] call Waldo_fnc_CortexSetPhase;
        _group setVariable ["Waldo_Cortex_WithdrawalIntent",_withdrawalIntent,true];
    };
};
// A pending shoot-and-scoot request is durable, but its queued callback belonged to the old owner.
// Resume it only after calm restoration has removed the old owner's waypoint and transient state;
// otherwise that cleanup would immediately delete the newly resumed relocation.
private _scootVehicles = [];
{
    private _vehicle = vehicle _x;
    if (_vehicle != _x && {!(_vehicle in _scootVehicles)}) then {
        _scootVehicles pushBack _vehicle;
        private _scootToken = _vehicle getVariable ["Waldo_Cortex_ArtilleryScootToken",""];
        if (_scootToken != "") then {[_vehicle,_scootToken] call Waldo_fnc_CortexArtilleryScoot};
    };
} forEach units _group;
_group setVariable ["Waldo_AIPass_Checkpoint", [], true];
// Clear stale remnant reservations and airborne jobs; the normal discovery path reassesses them.
_group setVariable ["Waldo_AIPass_RegroupQueued", nil];
_group setVariable ["Waldo_AIPass_RegroupHost", nil];
_group setVariable ["Waldo_AIPass_Dropping", nil];
