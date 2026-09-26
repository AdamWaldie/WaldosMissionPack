/*
 * Author: WaldoTheWarfighter
 * Publishes only restoration data that changed after an unscheduled AI job.
 * Locality/authority: current group owner unless stated otherwise below.
 * Repeat/JIP: durable restoration data is public; local jobs are never replayed verbatim.
 * Arguments: 0: group <GROUP>, default grpNull.
 * Return Value: Nothing unless a value is explicitly returned below.
 * Current callers: scheduler and locality restoration.
 * Example: [_group] call Waldo_fnc_AIPassCheckpoint;
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
} forEach ["baseBehaviour", "behaviourChanged", "hadContact", "baseSpeed", "speedChanged", "searchTeam", "holders", "dismounted"];
private _drill = _state getOrDefault ["drill", createHashMap];
if (count _drill > 0) then {
    _saved pushBack ["restoreDisabled", (_drill getOrDefault ["disabled", []]) apply {+_x}];
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
