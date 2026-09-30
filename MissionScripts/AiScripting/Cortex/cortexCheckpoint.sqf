/*
 * Author: WaldoTheWarfighter
 * Publishes only restoration data that changed after an unscheduled AI job.
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
    _saved pushBack ["restoreDisabled", (_drill getOrDefault ["disabled", []]) apply {+_x}];
    _saved pushBack ["restoreCombatModes",(_drill getOrDefault ["combatModes",[]]) apply {+_x}];
    _saved pushBack ["restoreCombatBehaviours",(_drill getOrDefault ["combatBehaviours",[]]) apply {+_x}];
    _saved pushBack ["restoreMovers", +(_drill getOrDefault ["units", []])];
};
if (_saved isNotEqualTo (_group getVariable ["Waldo_AIPass_Checkpoint", []])) then {
    _group setVariable ["Waldo_AIPass_Checkpoint", _saved, true];
};

private _phase = _state getOrDefault ["phase","CALM"];
if (_phase != (_group getVariable ["Waldo_AIPass_PublicPhase",""])) then {_group setVariable ["Waldo_AIPass_PublicPhase",_phase,true]};

private _token = _state getOrDefault ["supportToken",""];
private _arrived = _state getOrDefault ["arrivedAt",-1];
private _status = if (_token == "") then {[]} else {[_token,if (_arrived < 0) then {-1} else {round (serverTime-(time-_arrived))},_state getOrDefault ["responding",false],_state getOrDefault ["assaulting",false]]};
if (_status isNotEqualTo (_group getVariable ["Waldo_AIPass_SupportStatus",[]])) then {_group setVariable ["Waldo_AIPass_SupportStatus",_status,true]};

// Public tactical roles change only at fire-team transitions, not every movement sample.
private _teams=if ((_drill getOrDefault ["supportToken",""]) == "") then {[]} else {
    [_drill get "supportToken",_drill get "supportSequence",_drill get "stage",_drill get "teamTurn",_drill get "teams",_drill getOrDefault ["movers",[]]]
};
if (_teams isNotEqualTo (_group getVariable ["Waldo_Cortex_SupportTeams",[]])) then {_group setVariable ["Waldo_Cortex_SupportTeams",_teams,true]};
