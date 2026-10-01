/*
 * Author: WaldoTheWarfighter
 * Gives one finite Cortex movement operation exclusive group-level movement ownership when
 * LAMBS_Danger is loaded in SPLIT mode, then restores the group's previous LAMBS setting.
 *
 * Locality/authority: call only where the group is local. The lease and LAMBS group switch are
 * public so a new server/headless-client owner can renew or release the same ownership record.
 * WMP mode already owns the group through Waldo_AIPass_LambsDisabledByPass, so a scoped lease is
 * unnecessary there. LAMBS_Turrets, LAMBS_Suppression and LAMBS_RPG are config layers and are never
 * disabled by this function.
 * Repeat/JIP: reacquiring the same owner renews its deadline without changing the saved baseline;
 * another owner is refused until release or expiry. Release restores only the state captured by
 * Cortex and leaves the blanket WMP-mode switch in force. Repeated release is harmless.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: owner <STRING> - stable Cortex movement owner, for example SUPPORT
 * 2: acquire <BOOL> - true to acquire/renew, false to release
 * 3: expires <NUMBER> - serverTime deadline (optional, default serverTime + 30)
 *
 * Return Value:
 * Boolean - true when ownership was acquired/released, false for invalid locality or a competing owner
 *
 * Current callers: CortexSupportApply, CortexSupportMaintain, CortexDiscover and CortexReleaseGroup.
 *
 * Example:
 * [_group, "SUPPORT", true, serverTime + 180] call Waldo_fnc_CortexLambsLease;
 * Result: LAMBS group manoeuvres pause for that finite Cortex support move and resume afterwards.
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_owner", "", [""]],
    ["_acquire", true, [false]],
    ["_expires", serverTime + 30, [0]]
];
if (isNull _group || {!local _group}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded", false]) exitWith {true};

private _lease = _group getVariable ["Waldo_Cortex_LambsLease", []];
private _blanket = _group getVariable ["Waldo_AIPass_LambsDisabledByPass", false];
private _wmpMode = toUpperANSI (missionNamespace getVariable ["Waldo_AIPass_LambsMode", "SPLIT"]) == "WMP";

if (_acquire) exitWith {
    if (_wmpMode || {_blanket}) exitWith {true};
    if (_owner == "") exitWith {false};
    private _same = count _lease == 3 && {(_lease select 0) == _owner};
    private _expired = count _lease == 3 && {serverTime >= (_lease select 2)};
    if (_lease isNotEqualTo [] && {!_same} && {!_expired}) exitWith {false};
    private _baseline = if (_same) then {_lease select 1} else {
        if (_expired) then {_lease select 1} else {_group getVariable ["lambs_danger_disableGroupAI", false]}
    };
    _group setVariable ["Waldo_Cortex_LambsLease", [_owner, _baseline, _expires max (serverTime + 1)], true];
    _group setVariable ["lambs_danger_disableGroupAI", true, true];
    true
};

if (_lease isEqualTo []) exitWith {true};
if (_owner != "" && {(_lease select 0) != _owner}) exitWith {false};
private _baseline = _lease select 1;
_group setVariable ["Waldo_Cortex_LambsLease", nil, true];
if (_wmpMode || {_blanket}) then {
    _group setVariable ["lambs_danger_disableGroupAI", true, true];
} else {
    _group setVariable ["lambs_danger_disableGroupAI", _baseline, true];
};
true
