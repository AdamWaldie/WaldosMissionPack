/*
 * Author: WaldoTheWarfighter
 * Ends a drill (flank or bounding advance). Restores owned unit and group combat-mode overrides only
 * while the current mode still matches the value Cortex applied; later external changes survive.
 *
 * Restores the leader attack-assignment setting and only the AI features the drill disabled. A drill that completed, or stopped because the
 * enemy is close, leaves its members holding the ground they took: they are recorded as "holders" and
 * rejoin formation later (Waldo_fnc_CortexGroupTick, Waldo_fnc_CortexRestoreCalm,
 * Waldo_fnc_CortexRetreat). Any other ending (losses, the squad leaving contact, Zeus taking the
 * group, or release) orders members to follow the leader again at once. A failed coordinated
 * bound instead holds its gained ground until the next server sequence; it must not regroup
 * backwards before a retry. PATH holds transfer to supportHeld and a public actor marker so the
 * new owner can release the exact Cortex-owned restriction after migration.
 * The drill's type-specific cooldown starts: advances may resume sooner than wide flanks. Cleanup
 * releases a TACTICAL_DRILL movement lease only; a newer
 * withdrawal, vehicle, artillery or coordinated-assault owner survives a delayed drill callback.
 * Locality and authority: call where the group is local.
 *
 * Repeat/JIP: an empty drill is a no-op; the ending reason is published for observers and JIP.
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: reason <STRING> - COMPLETE, CLOSE, ABORT, LOSSES, STALLED, TIME_LIMIT, RELEASE, ZEUS, CALM,
 *    ROE_CHANGED, SPEED_CHANGED, GRENADE_UNRESOLVED, RECOVERY_FAILED or SCHEDULER_STALLED
 * Unresolved stragglers change COMPLETE/CLOSE to PARTIAL; main actors hold while stragglers rejoin.
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group, _state, "COMPLETE"] call Waldo_fnc_CortexFlankEnd;
 * Result: the element stays on the enemy's flank instead of running back to the leader.
 *
 * Current callers: Waldo_fnc_CortexFlankStep and Waldo_fnc_CortexReleaseGroup.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_reason", "", [""]]];
private _drill = _state getOrDefault ["drill", createHashMap];
if (count _drill == 0) exitWith {};
private _groupModeLease = _drill getOrDefault ["groupCombatMode",[]];
if (count _groupModeLease == 2 && {combatMode _group == (_groupModeLease select 1)}) then {
    _group setCombatMode (_groupModeLease select 0);
};
private _groupSpeedLease = _drill getOrDefault ["groupSpeedMode",[]];
if (count _groupSpeedLease == 2 && {speedMode _group == (_groupSpeedLease select 1)}) then {
    _group setSpeedMode (_groupSpeedLease select 0);
};
{
    _x params ["_unit", "_feature"];
    if (alive _unit && {local _unit}) then {_unit enableAI _feature};
} forEach (_drill getOrDefault ["disabled", []]);
{
    _x params ["_unit","_mode",["_ownedMode","BLUE"]];
    if (local _unit && {unitCombatMode _unit == _ownedMode}) then {_unit setUnitCombatMode _mode};
} forEach (_drill getOrDefault ["combatModes",[]]);
{
    _x params ["_unit","_previous","_owned"];
    if (local _unit && {behaviour _unit == _owned}) then {_unit setCombatBehaviour _previous};
} forEach (_drill getOrDefault ["combatBehaviours",[]]);
private _members = (_drill getOrDefault ["units", []]) select {alive _x && {local _x} && {group _x == _group}};
// Retire only the temporary throw listener belonging to this cancelled/completed drill.
// Keep the projectile record: cancellation does not remove a live explosive from the world.
{
    private _flight = _x getVariable ["Waldo_Cortex_FragFlight",[]];
    if (count _flight == 5 && {(_flight select 0) == (_drill getOrDefault ["token",""])}) then {
        private _handler = _x getVariable ["Waldo_Cortex_FragHandler",-1];
        if (_handler >= 0) then {_x removeEventHandler ["FiredMan",_handler]};
        _x setVariable ["Waldo_Cortex_FragHandler",-1];
    };
} forEach _members;
private _stragglers = ((_drill getOrDefault ["recovery",[]]) apply {_x select 0}) select {_x in _members};
private _supportToken=_drill getOrDefault ["supportToken",""];
private _lease=_group getVariable ["Waldo_AIPass_SupportLease",[]];
private _holdFailedBound=_supportToken != ""
    && {_reason in ["STALLED","TIME_LIMIT","RECOVERY_FAILED"]}
    && {_state getOrDefault ["assaulting",false]}
    && {count _lease == 6} && {(_lease select 0) == _supportToken}
    && {serverTime < (_lease select 2)}
    && {[_group] call Waldo_fnc_CortexIsEligible};
private _hold = _reason in ["COMPLETE","CLOSE"];
if (_hold && {_stragglers isNotEqualTo []}) then {_reason = "PARTIAL"};
_group setVariable ["Waldo_Cortex_DrillRecovery",[_reason,_stragglers,_drill getOrDefault ["index",-1]],true];
if (_holdFailedBound) then {
    // A failed movement remains a failure. Preserve physical gains while the server
    // yields the turn; doFollow here creates repeated outward/return journeys.
    private _held=_state getOrDefault ["supportHeld",[]];
    {
        doStop _x;
        if (_x checkAIFeature "PATH") then {
            _x disableAI "PATH";
            _x setVariable ["Waldo_Cortex_SupportPathHold",true,true];
            _held pushBackUnique _x;
        };
    } forEach _members;
    _state set ["supportHeld",_held];
} else {
if (_hold) then {
    private _holders = _state getOrDefault ["holders", []];
    {doStop _x; _holders pushBackUnique _x} forEach (_members-_stragglers);
    {_x doFollow leader _group} forEach _stragglers;
    _state set ["holders", _holders];
} else {
    private _leader = leader _group;
    // Zeus has already supplied the replacement movement. Restore Cortex-owned
    // feature switches above, but do not replace that order with formation return.
    if (_reason != "ZEUS") then {{_x doFollow _leader} forEach _members};
};
};
if (_supportToken != "") then {
    _group setVariable ["Waldo_Cortex_SupportBoundResult",[_supportToken,_drill get "supportSequence",_reason],true];
} else {
    if (_reason != "ZEUS" && {_state getOrDefault ["attackChanged",false]}) then {_group enableAttack (_state getOrDefault ["baseAttack",true])};
    _state deleteAt "attackChanged";
    _state deleteAt "baseAttack";
};
private _type = _drill getOrDefault ["type", "FLANK"];
_group setVariable ["Waldo_Cortex_DrillResult",[_type,_reason,time],true];
[_group,_drill,"ENDED",_reason] call Waldo_fnc_CortexDrillSetStage;
_state deleteAt "drill";
private _movementLease = _state getOrDefault ["movementLease",[]];
if (count _movementLease == 2 && {(_movementLease select 0) == "TACTICAL_DRILL"}) then {
    [_group,"TACTICAL_DRILL",false] call Waldo_fnc_CortexLambsLease;
    _state deleteAt "movementLease";
};
private _cooldownName = ["Waldo_AIPass_Flank_Cooldown", "Waldo_AIPass_Advance_Cooldown"] select (_type == "ADVANCE");
private _cooldownDefault = [90, 20] select (_type == "ADVANCE");
[_state, toLowerANSI _type, missionNamespace getVariable [_cooldownName, _cooldownDefault]] call Waldo_fnc_CortexCooldown;
if (_reason == "COMPLETE") then {
    private _counter = ["Waldo_AIPass_FlanksCompleted", "Waldo_AIPass_AdvancesCompleted"] select (_type == "ADVANCE");
    missionNamespace setVariable [_counter, (missionNamespace getVariable [_counter, 0]) + 1];
};
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {diag_log format ["[WMP CORTEX] %1 %2 end reason=%3", _group, _type, _reason]};
