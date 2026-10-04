/*
 * Author: WaldoTheWarfighter
 * Hands a group back to its own orders and removes everything the pass applied to it.
 *
 * Ends any flank drill (re-enabling only the AI features the drill itself disabled), rejoins the
 * search team, removes pass waypoints, restores behaviour and speed without ordering passengers to board,
 * and releases both scoped SPLIT-mode and blanket WMP-mode LAMBS ownership. Explicit building
 * orders remain in place during ordinary cleanup; a detected Zeus takeover releases them before
 * restoring the rest of Cortex state so no old controller competes with the curator.
 * Locality and authority: call where the group is local; state and flags are machine-local.
 *
 * Review contract: Only the current group owner restores the public LAMBS flag. Changed restoration checkpoints are public and consumed on ownership adoption.
 *
 * A Zeus takeover yields movement, formation, behaviour and speed to the curator while still restoring
 * Cortex-owned AI feature switches and removing Cortex waypoints. Repeat/JIP: only tracked changes are
 * restored; repeated cleanup is harmless and never boards passengers.
 * Public remount intent is cancelled even when owner migration left no local behaviour map.
 * A public actor marker likewise releases only PATH restrictions proven to belong to Cortex.
 * A crew owner also restores any forced speed borrowed for an onboard dismount safe stop.
 * Naval cleanup restores the exact boat forced speed and removes only the token-matched WMP plan.
 * Arguments:
 * 0: group <GROUP>
 * 1: forget <BOOL> - also clear the managed flag so discovery may pick the group up again
 *    (optional, default: true)
 * 2: transition reason <STRING> - published with the CALM handover. Empty selects
 *    ZEUS_TAKEOVER when an external hold is active, otherwise RELEASED (optional, default: "").
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group] call Waldo_fnc_CortexReleaseGroup;
 * Result: the group behaves exactly as it would without the pass.
 *
 * Current callers: Cortex eligibility/stop cleanup, Zeus and AI-order handovers, surrender,
 * defence, garrison and building-clear order entry.
 */

params [["_group", grpNull, [grpNull]], ["_forget", true, [false]], ["_reason", "", [""]]];
if (isNull _group) exitWith {};
private _state = _group getVariable ["Waldo_AIPass_State", createHashMap];
private _yieldToExternal=local _group && {[_group] call Waldo_fnc_CortexZeusHeld};
if (_reason == "") then {_reason=["RELEASED","ZEUS_TAKEOVER"] select _yieldToExternal};
private _externalTakeover=_yieldToExternal || {_reason == "ZEUS_TAKEOVER"};
if ((_state getOrDefault ["navalOperation",[]]) isNotEqualTo []
    || {(_group getVariable ["Waldo_Cortex_NavalOperation",[]]) isNotEqualTo []}) then {
    [_group,_state] call Waldo_fnc_CortexNavalRelease;
};
// Defence in depth for every caller, including a release delivered after locality migration. The
// curator client normally retires these public tokens before dispatch, but cleanup must never depend
// on that client-side write arriving first.
if (_externalTakeover) then {
    _group setVariable ["Waldo_Cortex_CombinedRole",nil,true];
    _group setVariable ["Waldo_Cortex_CombinedApplied",nil,true];
    _group setVariable ["Waldo_Cortex_CombinedOpportunity",nil,true];
};
// Explicit building controllers are movement owners too. Zeus replacement orders must terminate the
// delegated LAMBS loop or native building job before general Cortex state is restored.
if (_externalTakeover) then {
    [_group,false] call Waldo_fnc_CortexLambsBuildingRelease;
    [_group,false] call Waldo_fnc_CortexClearRelease;
    [_group,false] call Waldo_fnc_CortexGarrisonRelease;
};
private _markedSupportHold=(units _group) findIf {_x getVariable ["Waldo_Cortex_SupportPathHold",false]} >= 0;
if (local _group && {count _state > 0 || {_markedSupportHold} || {(_group getVariable ["Waldo_Cortex_Remount",[]]) isNotEqualTo []}}) then {
    if (count (_state getOrDefault ["drill", createHashMap]) > 0) then {[_group, _state, ["RELEASE","ZEUS"] select _externalTakeover] call Waldo_fnc_CortexFlankEnd};
    [_group, _state, false, _externalTakeover, _reason] call Waldo_fnc_CortexRestoreCalm;
};
if (local _group) then {[_group,"",false] call Waldo_fnc_CortexLambsLease};
// Release an interrupted cross-group dismount without stranding the vehicle at forced speed zero.
private _releasedVehicles=[];
{
    private _vehicle=vehicle _x;
    if (_vehicle != _x && {!(_vehicle in _releasedVehicles)}
        && {local _vehicle} && {effectiveCommander _vehicle in units _group}) then {
        _releasedVehicles pushBack _vehicle;
        private _saved=_vehicle getVariable ["Waldo_Cortex_DismountForcedSpeed",[]];
        if (_saved isNotEqualTo []) then {_vehicle forceSpeed (_saved param [0,-1])};
        _vehicle setVariable ["Waldo_Cortex_DismountForcedSpeed",nil];
        _vehicle setVariable ["Waldo_Cortex_DismountStopRequest",nil,true];
    };
} forEach units _group;
if (local _group && {_group getVariable ["Waldo_AIPass_LambsDisabledByPass", false]}) then {
    _group setVariable ["lambs_danger_disableGroupAI", _group getVariable ["Waldo_AIPass_LambsBaseline", false], true];
    _group setVariable ["Waldo_AIPass_LambsDisabledByPass", nil, true];
    _group setVariable ["Waldo_AIPass_LambsBaseline", nil, true];
};
_group setVariable ["Waldo_AIPass_State", nil];
if (_forget) then {_group setVariable ["Waldo_AIPass_Managed", nil]};
