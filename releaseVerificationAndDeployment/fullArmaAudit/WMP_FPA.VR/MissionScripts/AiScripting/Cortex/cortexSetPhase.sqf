/*
 * Author: WaldoTheWarfighter
 * Atomically changes a Cortex group phase and publishes a bounded transition history.
 * Locality/authority: call only on the machine which owns the group and its local state HashMap.
 * Repeat/JIP: an identical current phase is ignored unless a locality adoption explicitly forces a
 * continuity record. The current public phase, newest transition and at most 32 history entries are
 * changed together for Zeus, diagnostics and JIP observers; no handler or scheduled work is added.
 * Arguments:
 * 0: group <GROUP, default grpNull>
 * 1: state <HASHMAP, default empty HashMap> - owner-local Cortex group state
 * 2: next phase <STRING, default ""> - CALM, INVESTIGATE, CONTACT, SECURITY, SEARCH, REGROUP or RETREAT
 * 3: reason <STRING, default "UNSPECIFIED"> - concrete trigger for the transition
 * 4: phase start <NUMBER, default time> - owner-local mission time, preserved during migration resume
 * 5: force continuity record <BOOL, default false> - publish an ownership handover even when the
 *    resumed semantic phase has the same name as the last public phase
 * Return Value: Boolean - true when the phase changed
 * Current callers: CortexGroupTick, CortexRestoreCalm, CortexRetreat, CortexVehicles and CortexLocality.
 * Example:
 * [_group,_state,"CONTACT","VISIBLE_CONTACT",time] call Waldo_fnc_CortexSetPhase;
 * Result: CONTACT and phaseStart change together and observers receive CALM -> CONTACT evidence.
 */

params [
    ["_group",grpNull,[grpNull]],
    ["_state",createHashMap,[createHashMap]],
    ["_next","",[""]],
    ["_reason","UNSPECIFIED",[""]],
    ["_phaseStart",time,[0]],
    ["_force",false,[true]]
];
if (isNull _group || {!local _group} || {count _state == 0}) exitWith {false};
private _validPhases=["CALM","INVESTIGATE","CONTACT","SECURITY","SEARCH","REGROUP","RETREAT"];
if !(_next in _validPhases) exitWith {false};
private _localPrevious=_state getOrDefault ["phase","CALM"];
private _previous=if (_force) then {_group getVariable ["Waldo_AIPass_PublicPhase",_localPrevious]} else {_localPrevious};
if !(_previous in _validPhases) then {_previous=_localPrevious};
if (_localPrevious == _next && {!_force}) exitWith {false};
_state set ["phase",_next];
_state set ["phaseStart",_phaseStart];
_group setVariable ["Waldo_AIPass_PublicPhase",_next,true];
private _entry=[serverTime,_previous,_next,_reason,clientOwner];
private _history=_group getVariable ["Waldo_Cortex_PhaseTransitions",[]];
_history pushBack _entry;
if (count _history > 32) then {_history deleteRange [0,count _history-32]};
_group setVariable ["Waldo_Cortex_PhaseTransition",_entry,true];
_group setVariable ["Waldo_Cortex_PhaseTransitions",_history,true];
true
