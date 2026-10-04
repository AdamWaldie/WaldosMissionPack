/*
 * Author: WaldoTheWarfighter
 * Remount cleanup preserves a newer vehicle assignment from Zeus or another controller.
 * Returns a group to CALM and undoes everything the pass changed for the engagement.
 * Ends an active drill synchronously before consuming its restoration data; queued
 * steps then find no matching drill and cannot revive the old movement.
 *
 * Restores recorded changes: a retreat combat-mode lease goes back to its prior value only while
 * the group still has Cortex's applied value; behaviour goes back to the value
 * recorded at first contact only if the pass changed it and the group is still in COMBAT (a squad
 * that was SAFE before an actual firefight comes back AWARE, not SAFE); speed goes
 * back only if the pass changed it. Pass waypoints are removed so the group resumes its own
 * waypoints, the search or investigation team and soldiers holding ground from a drill rejoin
 * formation, stances still matching the recorded Cortex value go back to AUTO, and infantry
 * dismounted by the pass remount their
 * vehicle. Morale is kept and recovers slowly.
 * Locality and authority: call where the group is local.
 *
 * Review contract: Investigation can change SAFE to AWARE; cleanup restores that recorded behaviour as well as a COMBAT change. Only the local group owner performs restoration.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP> - from Waldo_fnc_CortexGroupState
 *
 * 2: allow remount <BOOL>, true; false during stop, ownership restoration or external takeover.
 * 3: yield to external order <BOOL>, false; when true Cortex removes its owned controls and
 *    preserves identifiable replacement commands, behaviour and speed.
 * 4: transition reason <STRING>, "RESTORED"; published with the CALM handover.
 * 5: force transition record <BOOL>, false; used only when a new owner must replace a stale public
 *    phase even though its fresh local state already begins in CALM.
 * Repeat/JIP: removes only WMP transient orders and restores recorded values.
 * Explicitly tracked Cortex holds and their public actor markers restore PATH and resume formation
 * even if local state vanished during migration or combat relabelled doStop as ATTACK/FIRE.
 * Search teams never restore PATH because Cortex did not disable it for that action;
 * ordinary cleanup ends their stale search move, while external takeover preserves a replacement
 * MOVE or other command. Commands which cannot be a combat-side effect of a hold survive.
 * Pending remount intent is public for owner migration; GroupTick retries for up to 60 seconds.
 * Any finite LAMBS movement handover is released before its local support token is erased.
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group, _state] call Waldo_fnc_CortexRestoreCalm;
 * Result: the group carries on with its mission as it was before contact.
 *
 * Current callers: CortexGroupTick, CortexReleaseGroup, CortexLocality and CortexOnboardContact.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_allowRemount",true,[true]], ["_yieldToExternal",false,[true]], ["_reason","RESTORED",[""]], ["_forcePhase",false,[true]]];
if (isNull _group || {!local _group}) exitWith {};
// A pending drill step may not run until after a checkpoint or ownership change.
// Restore its movement restrictions now, before clearing the checkpoint below.
if (count (_state getOrDefault ["drill",createHashMap]) > 0) then {
    [_group,_state,"CALM"] call Waldo_fnc_CortexFlankEnd;
};
private _releaseOwnedHold={
    params ["_unit",["_restorePath",true],["_returnSearchTeam",false]];
    if (local _unit && {group _unit == _group}) then {
        if (_restorePath) then {
            _unit enableAI "PATH";
            _unit setVariable ["Waldo_Cortex_SupportPathHold",nil,true];
        };
        private _command=toUpperANSI currentCommand _unit;
        private _ownedHold=_command in ["","STOP","ATTACK","FIRE","SUPPRESS"];
        if (_ownedHold || {_returnSearchTeam && {!_yieldToExternal}}) then {
            _unit doFollow leader _group;
        };
    };
};
private _supportHeld=_state getOrDefault ["supportHeld",[]];
{
    if (_x getVariable ["Waldo_Cortex_SupportPathHold",false]) then {_supportHeld pushBackUnique _x};
} forEach units _group;
{[_x,true,false] call _releaseOwnedHold} forEach _supportHeld;
_state deleteAt "supportHeld";
_state deleteAt "supportBoundSequence";
// Withdrawals, calm restoration and external handovers retire the shared assignment.
private _supportLease=_group getVariable ["Waldo_AIPass_SupportLease",[]];
if (count _supportLease == 6 && {(_state getOrDefault ["supportToken",""]) == (_supportLease select 0)}) then {
    [_group,_supportLease select 0,false,_supportLease,clientOwner] remoteExecCall ["Waldo_fnc_CortexSupportAck",2];
};
[_group,"SUPPORT",false] call Waldo_fnc_CortexLambsLease;
private _movementOwner=(_state getOrDefault ["movementLease",[]]) param [0,""];
if (_movementOwner != "") then {[_group,_movementOwner,false] call Waldo_fnc_CortexLambsLease};
{_state deleteAt _x} forEach ["supportHeld","supportBoundSequence","supportToken","responding","assaulting","respondingTo","respondUntil"];
private _leader = leader _group;
// Zeus may deliberately replace Cortex's disabled autonomous-attack state while taking over.
// The external handover owns that setting, just as it owns replacement movement and ROE.
if (!_yieldToExternal && {_state getOrDefault ["attackChanged",false]}) then {_group enableAttack (_state getOrDefault ["baseAttack",true])};
private _retreatModeLease = _state getOrDefault ["retreatCombatMode",[]];
if (!_yieldToExternal && {count _retreatModeLease == 2} && {combatMode _group == (_retreatModeLease select 1)}) then {
    _group setCombatMode (_retreatModeLease select 0);
};
[_group] call Waldo_fnc_CortexGroupMoveClear;
// Search movement never disables PATH. Do not enable a mission-disabled feature while
// returning a search team. During an ordinary handback its Cortex MOVE is explicitly
// retired; during a Zeus takeover a MOVE may already be the curator's replacement order.
{if (alive _x) then {[_x,false,true] call _releaseOwnedHold}} forEach (_state getOrDefault ["searchTeam", []]);
// Drill holders are explicit Cortex PATH holds. Retire that ownership on every release,
// including Zeus takeover, while preserving a newer individual command.
{if (alive _x) then {[_x,true,false] call _releaseOwnedHold}} forEach (_state getOrDefault ["holders", []]);
{
    if (local _x && {_x getVariable ["Waldo_AIPass_StanceSet", false]}) then {
        if (toUpperANSI (unitPos _x) == (_x getVariable ["Waldo_Cortex_AppliedStance",""])) then {_x setUnitPos "AUTO"};
        _x setVariable ["Waldo_Cortex_AppliedStance",nil,true];
        _x setVariable ["Waldo_AIPass_StanceSet", nil, true];
    };
    if (local _x) then {
        private _target = _x getVariable ["Waldo_AIPass_VehicleTarget",objNull];
        if (!isNull _target && {assignedTarget _x == _target}) then {_x doTarget objNull};
        _x setVariable ["Waldo_AIPass_VehicleTarget",nil,true];
        _x setVariable ["Waldo_AIPass_TargetHold",nil];
        _x setVariable ["Waldo_Cortex_ActorMove",nil];
    };
} forEach units _group;
if (!_yieldToExternal && {_state getOrDefault ["behaviourChanged", false]} && {behaviour _leader in ["COMBAT", "AWARE"]}) then {
    private _base = _state getOrDefault ["baseBehaviour", "AWARE"];
    // After a real firefight a squad stays alert rather than slinging weapons, as the engine does.
    if (_base == "SAFE" && {_state getOrDefault ["hadContact", false]}) then {_base = "AWARE"};
    _group setBehaviour _base;
};
if (!_yieldToExternal && {_state getOrDefault ["speedChanged", false]}) then {
    _group setSpeedMode (_state getOrDefault ["baseSpeed", "NORMAL"]);
};
{
    _x params ["_unit", "_vehicle"];
    if (_allowRemount && {[_group,"Waldo_AIPass_Vehicles_Enable",true] call Waldo_fnc_CortexFeatureEnabled} && {group _unit == _group} && {isNull assignedVehicle _unit || {assignedVehicle _unit == _vehicle}} && {[_group, "Waldo_AIPass_VehicleRemount_Enable", true] call Waldo_fnc_CortexFeatureEnabled} && {[_unit, _vehicle, true] call Waldo_fnc_CortexPassengerReady}) then {
        _unit assignAsCargo _vehicle;
        [_unit] orderGetIn true;
    };
} forEach (_state getOrDefault ["dismounted", []]);
// Retain boarding intent until seats are actually occupied. The public record lets
// a new HC owner continue the bounded attempt; it never moves units into seats.
private _boarding = _state getOrDefault ["dismounted", []];
if (_allowRemount && {_boarding isNotEqualTo []}) then {
    _group setVariable ["Waldo_Cortex_Remount",[serverTime+60,+_boarding],true];
};
if (!_allowRemount) then {
    {private _unit=_x select 0; if (local _unit && {vehicle _unit == _unit} && {assignedVehicle _unit == (_x select 1)}) then {[_unit] orderGetIn false; unassignVehicle _unit}} forEach ((_group getVariable ["Waldo_Cortex_Remount",[0,[]]]) select 1);
    _group setVariable ["Waldo_Cortex_Remount",nil,true];
};
{_state deleteAt _x} forEach [
    "consolidateIssued", "baseAttack", "attackChanged", "areaInvestigation", "enemyPos", "behaviourChanged", "speedChanged", "searchTeam", "dismounted", "onboardContactUntil", "reinforceRequested", "reinforceDispatchedAt",
    "withdrawn", "contactLeader", "lastSeen", "holders", "baseBehaviour", "baseSpeed", "armourSeen",
    "armourRequested", "antiArmourRelocation", "coordinated", "coordinatedPendingUntil", "retreatCombatMode", "retreatRetryAt", "movementLease", "retreatStart", "retreatTarget", "retreatProgress", "reserveCommitted", "arrivedAt", "assaulting", "hadContact"
];
_group setVariable ["Waldo_Cortex_Withdrawal",nil,true];
_group setVariable ["Waldo_Cortex_WithdrawalIntent",nil,true];
_group setVariable ["Waldo_Cortex_TransitionIntent",nil,true];
_group setVariable ["Waldo_AIPass_Checkpoint", [], true];
[_group,_state,"CALM",_reason,time,_forcePhase] call Waldo_fnc_CortexSetPhase;
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {diag_log format ["[WMP CORTEX] %1 CALM restored", _group]};
