/*
 * Author: WaldoTheWarfighter
 * Changes one Cortex manoeuvre stage and publishes a bounded transition ledger for diagnostics.
 * Locality/authority: call only on the local group owner which owns the supplied drill HashMap.
 * Repeat/JIP: identical stages are ignored. The current transition and the newest 64 entries
 * are public for Zeus/JIP observers; no scheduled work or per-unit handler is installed.
 * Arguments:
 * 0: group <GROUP, default grpNull>
 * 1: drill <HASHMAP, default empty HashMap> - active flank, advance or coordinated-bound state
 * 2: next stage <STRING, default ""> - START, MOVE, PAUSE, HOLD or ENDED
 * 3: reason <STRING, default ""> - concrete trigger or final outcome
 * Return Value: Boolean - true when the stage changed and was published
 * Current callers: CortexFlankStart, CortexAdvanceStart, CortexSupportBoundStart,
 * CortexFlankStep and CortexFlankEnd.
 * Example:
 * [_group, _drill, "MOVE", "BOUND_ISSUED"] call Waldo_fnc_CortexDrillSetStage;
 * Result: the owner enters MOVE and Zeus can distinguish a live bound from an idle controller.
 */

params [
    ["_group",grpNull,[grpNull]],
    ["_drill",createHashMap,[createHashMap]],
    ["_next","",[""]],
    ["_reason","",[""]]
];
if (isNull _group || {!local _group} || {count _drill == 0} || {_next == ""}) exitWith {false};
private _previous=_drill getOrDefault ["stage",""];
if (_previous == _next) exitWith {false};
_drill set ["stage",_next];
private _entry=[
    serverTime,
    _drill getOrDefault ["token",""],
    _drill getOrDefault ["type",""],
    _previous,
    _next,
    _reason,
    _drill getOrDefault ["index",-1],
    _drill getOrDefault ["teamTurn",-1]
];
private _history=_group getVariable ["Waldo_Cortex_DrillTransitions",[]];
_history pushBack _entry;
if (count _history > 64) then {_history deleteRange [0,count _history-64]};
_group setVariable ["Waldo_Cortex_DrillTransition",_entry,true];
_group setVariable ["Waldo_Cortex_DrillTransitions",_history,true];
true
