/*
 * Author: WaldoTheWarfighter
 * Applies the Dynamic AA firing gate to the machine that currently owns an air-defence group.
 *
 * WMP, rather than ordinary Arma target acquisition, decides what this group may engage. Targets
 * outside the configured horizontal area or altitude band are explicitly ignored and forgotten.
 * Spawned ground defences have all AI features disabled while the gate is closed; aircraft retain
 * movement AI so a scrambled fighter does not fall out of the sky. Remote-target sharing is disabled
 * for every defence vehicle so another radar, Zeus unit or AI group cannot bypass the WMP detector.
 *
 * Locality and authority:
 * The Dynamic AA server loop is authoritative. This function remotes the actual AI commands to the
 * current group owner, which also covers groups migrated to a headless client. It changes no public
 * mission state and is safe to call repeatedly on every detector pass.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: active <BOOLEAN> - true opens the gate for only argument 2; false closes it completely
 * 2: eligible targets <ARRAY of OBJECTS> (default []) - hostile aircraft already validated by the
 *    server detector against side, horizontal range, floor, ceiling and mission filter
 *
 * Return Value:
 * Boolean - true when the update ran locally or was sent to the current group owner
 *
 * Current callers:
 * Dynamic AA creation, the detector loop, fighter scrambling and Dynamic AA teardown.
 *
 * Example:
 * [_group, false] call Waldo_fnc_DynamicAASetGroupState;
 * Result: the group closes and forgets targets, or opens only for the supplied eligible aircraft.
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_active", false, [false]],
    ["_targets", [], [[]]]
];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (isNull _group) exitWith {false};
if !(local _group) exitWith {
    if !(isServer) exitWith {false};
    private _groupOwner = groupOwner _group;
    if (_groupOwner <= 0 || {_groupOwner == clientOwner}) exitWith {false};
    [_group, _active, _targets] remoteExecCall ["Waldo_fnc_DynamicAASetGroupState", _groupOwner];
    true
};

private _eligibleTargets = _targets select {!isNull _x && {alive _x} && {_x isKindOf "Air"}};
private _knownTargets = (_group targets []) select {!isNull _x};

// Remove engine knowledge before changing combat state. This is deliberately repeated because
// datalink or another AI may have reintroduced a target since the previous detector pass.
{
    private _target = _x;
    if (_active && {_target in _eligibleTargets}) then {
        _group ignoreTarget [_target, false];
    } else {
        _group ignoreTarget _target;
        _group forgetTarget _target;
    };
} forEach (_knownTargets + _eligibleTargets);

{
    private _unit = _x;
    private _vehicle = vehicle _unit;
    if (_vehicle != _unit) then {
        _vehicle setVehicleReceiveRemoteTargets false;
        _vehicle setVehicleReportRemoteTargets false;
    };
    if (_active) then {
        _unit enableAI "ALL";
        _unit enableAI "TARGET";
        // Strict detector ownership: ordinary Arma auto-targeting would allow the crew to acquire
        // low aircraft and ground units after one eligible aircraft activated the site.
        _unit disableAI "AUTOTARGET";
        _unit enableAI "WEAPONAIM";
        _unit enableAI "SUPPRESSION";
    } else {
        _unit doTarget objNull;
        _unit doWatch objNull;
        if (_vehicle isKindOf "Air") then {
            // Keep MOVE and flight-control AI alive; only its ability to acquire/fire is suppressed.
            _unit disableAI "TARGET";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "WEAPONAIM";
            _unit disableAI "SUPPRESSION";
        } else {
            // Static and mobile ground systems must have an absolute closed state. enableAI "ALL"
            // above restores the crew when the server next supplies an eligible aircraft.
            _unit disableAI "ALL";
        };
    };
} forEach units _group;

_group enableAttack _active;
_group setCombatMode (["BLUE", "RED"] select _active);
_group setBehaviourStrong (["SAFE", "COMBAT"] select _active);
if (_active) then {
    {
        _group ignoreTarget [_x, false];
        _group reveal [_x, 4];
    } forEach _eligibleTargets;
    private _targetCount = count _eligibleTargets;
    if (_targetCount > 0) then {
        {
            _x doTarget (_eligibleTargets select (_forEachIndex mod _targetCount));
        } forEach units _group;
    };
};
true
