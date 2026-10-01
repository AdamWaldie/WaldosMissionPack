/*
 * Author: WaldoTheWarfighter
 * Publishes restoration data and bounded post-contact movement intent after an unscheduled AI job.
 * A missing or stale public phase is repaired through CortexSetPhase with an explicit continuity
 * record; the checkpoint never changes observable phase state outside the common transition path.
 * Locality/authority: current group owner unless stated otherwise below.
 * Repeat/JIP: durable restoration data is public; local jobs are never replayed verbatim.
 * Arguments: 0: group <GROUP>, default grpNull.
 * Return Value: Nothing unless a value is explicitly returned below.
 * Current callers: scheduler and locality restoration.
 * Example: [_group] call Waldo_fnc_CortexCheckpoint;
 */
params [["_group", grpNull, [grpNull]]];
if (isNull _group || {!local _group}) exitWith {};
private _state = _group getVariable ["Waldo_AIPass_State", createHashMap];
private _saved = [];
{
    private _value = _state get _x;
    if (!isNil "_value") then {
        if (_value isEqualType []) then {_value = _value apply {if (_x isEqualType []) then {+_x} else {_x}}};
        _saved pushBack [_x, _value];
    };
} forEach ["supportHeld", "baseAttack", "attackChanged", "retreatCombatMode", "baseBehaviour", "behaviourChanged", "hadContact", "baseSpeed", "speedChanged", "searchTeam", "holders", "dismounted"];
private _drill = _state getOrDefault ["drill", createHashMap];
if (count _drill > 0) then {
    private _groupModeLease = _drill getOrDefault ["groupCombatMode",[]];
    if (_groupModeLease isNotEqualTo []) then {_saved pushBack ["restoreGroupCombatMode",+_groupModeLease]};
    private _groupSpeedLease = _drill getOrDefault ["groupSpeedMode",[]];
    if (_groupSpeedLease isNotEqualTo []) then {_saved pushBack ["restoreGroupSpeedMode",+_groupSpeedLease]};
    _saved pushBack ["restoreDisabled", (_drill getOrDefault ["disabled", []]) apply {+_x}];
    _saved pushBack ["restoreCombatModes",(_drill getOrDefault ["combatModes",[]]) apply {+_x}];
    _saved pushBack ["restoreCombatBehaviours",(_drill getOrDefault ["combatBehaviours",[]]) apply {+_x}];
    _saved pushBack ["restoreMovers", +(_drill getOrDefault ["units", []])];
};
if (_saved isNotEqualTo (_group getVariable ["Waldo_AIPass_Checkpoint", []])) then {
    _group setVariable ["Waldo_AIPass_Checkpoint", _saved, true];
};

private _phase = _state getOrDefault ["phase","CALM"];
if (_phase != (_group getVariable ["Waldo_AIPass_PublicPhase",""])) then {
    [_group,_state,_phase,"CHECKPOINT_REPAIR",_state getOrDefault ["phaseStart",time],true] call Waldo_fnc_CortexSetPhase;
};

// Engine MOVE commands are local to their issuing owner. Preserve the small amount of
// semantic state needed to rebuild an unfinished investigation or search after migration;
// never serialize a scheduled callback or claim that an accepted command completed.
private _transitionIntent = [];
if (_phase in ["INVESTIGATE","SEARCH"]) then {
    private _target = _state getOrDefault ["enemyPos",[]];
    if (count _target >= 2) then {
        private _duration = missionNamespace getVariable [
            ["Waldo_AIPass_PostContact_SearchSeconds","Waldo_AIPass_Investigate_Seconds"] select (_phase == "INVESTIGATE"),
            [45,60] select (_phase == "INVESTIGATE")
        ];
        private _startedAt = serverTime-((time-(_state getOrDefault ["phaseStart",time])) max 0);
        _transitionIntent = [_phase,+_target,_startedAt,_startedAt+_duration,_state getOrDefault ["areaInvestigation",""],+(_state getOrDefault ["searchTeam",[]])];
    };
};
if (_transitionIntent isNotEqualTo (_group getVariable ["Waldo_Cortex_TransitionIntent",[]])) then {
    _group setVariable ["Waldo_Cortex_TransitionIntent",_transitionIntent,true];
};

private _token = _state getOrDefault ["supportToken",""];
private _arrived = _state getOrDefault ["arrivedAt",-1];
private _status = if (_token == "") then {[]} else {[_token,if (_arrived < 0) then {-1} else {round (serverTime-(time-_arrived))},_state getOrDefault ["responding",false],_state getOrDefault ["assaulting",false]]};
if (_status isNotEqualTo (_group getVariable ["Waldo_AIPass_SupportStatus",[]])) then {_group setVariable ["Waldo_AIPass_SupportStatus",_status,true]};

// Public tactical roles change only at fire-team transitions, not every movement sample.
private _teams=if ((_drill getOrDefault ["supportToken",""]) == "") then {[]} else {
    [_drill get "supportToken",_drill get "supportSequence",_drill get "stage",_drill get "teamTurn",_drill get "teams",_drill getOrDefault ["movers",[]]]
};
if (_teams isNotEqualTo (_group getVariable ["Waldo_Cortex_SupportTeams",[]])) then {_group setVariable ["Waldo_Cortex_SupportTeams",_teams,true]};
