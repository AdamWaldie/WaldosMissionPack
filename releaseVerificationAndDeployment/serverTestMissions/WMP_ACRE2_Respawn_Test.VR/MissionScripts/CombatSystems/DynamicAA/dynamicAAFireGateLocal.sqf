/*
 * Author: WaldoTheWarfighter
 * Installs and updates an absolute local projectile gate on one Dynamic AA vehicle. The normal AI
 * gate prevents acquisition, but Arma can briefly retain or reacquire a ground/out-of-zone target
 * while another valid aircraft has opened the site. This last-line gate allows a projectile only
 * when its firing gunner or guided projectile is targeting an aircraft in the server-approved list.
 * It never chooses targets and does not alter ammunition, so repeated activation cannot refill a site.
 *
 * Locality and authority: called on the vehicle/group owner from the server-authoritative detector.
 * The approved target list is local and replaced every detector pass. The Fired handler is versioned
 * and reinstalled after locality migration; blocked projectiles are deleted where they are local.
 * Setup is repeat-safe and carries no JIP state because the detector replays it continuously.
 *
 * Arguments:
 * 0: AA vehicle <OBJECT>
 * 1: gate active <BOOL>
 * 2: server-approved aircraft <ARRAY of OBJECTS> (default [])
 *
 * Return Value: Boolean - true when updated locally or sent to the vehicle owner.
 * Current caller: Waldo_fnc_DynamicAASetGroupState on every detector pass.
 * Example: [_tigris, true, [_hostileHelicopter]] call Waldo_fnc_DynamicAAFireGateLocal;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_active", false, [false]],
    ["_eligibleTargets", [], [[]]]
];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (isNull _vehicle) exitWith {false};
if !(local _vehicle) exitWith {
    [_vehicle, _active, _eligibleTargets] remoteExecCall ["Waldo_fnc_DynamicAAFireGateLocal", owner _vehicle];
    true
};

private _approved = if (_active) then {
    _eligibleTargets select {!isNull _x && {alive _x} && {_x isKindOf "Air"}}
} else {
    []
};
_vehicle setVariable ["Waldo_DynamicAA_EligibleTargetsLocal", _approved];

private _version = 2;
if (_vehicle getVariable ["Waldo_DynamicAA_FireGateVersionLocal", -1] != _version) then {
    private _old = _vehicle getVariable ["Waldo_DynamicAA_FireGateEhLocal", -1];
    if (_old >= 0) then {_vehicle removeEventHandler ["Fired", _old]};
    private _eh = _vehicle addEventHandler ["Fired", {
        params ["_vehicle", "", "", "", "", "", "_projectile", ["_gunner", objNull]];
        if (isNull _projectile) exitWith {};
        private _approved = _vehicle getVariable ["Waldo_DynamicAA_EligibleTargetsLocal", []];
        private _target = missileTarget _projectile;
        if (isNull _target && {!isNull _gunner}) then {_target = assignedTarget _gunner};
        if (isNull _target || {!(_target in _approved)}) then {
            deleteVehicle _projectile;
            private _nextLog = _vehicle getVariable ["Waldo_DynamicAA_NextBlockedShotLogLocal", 0];
            if (diag_tickTime >= _nextLog) then {
                _vehicle setVariable ["Waldo_DynamicAA_NextBlockedShotLogLocal", diag_tickTime + 2];
                diag_log format [
                    "[WMP DYNAMIC AA] Blocked non-eligible shot system=%1 vehicle=%2 target=%3 approved=%4 owner=%5.",
                    _vehicle getVariable ["Waldo_DynamicAA_SystemId", "UNKNOWN"], typeOf _vehicle,
                    if (isNull _target) then {"NONE"} else {typeOf _target}, count _approved, clientOwner
                ];
            };
        };
    }];
    _vehicle setVariable ["Waldo_DynamicAA_FireGateEhLocal", _eh];
    _vehicle setVariable ["Waldo_DynamicAA_FireGateVersionLocal", _version];
};
true
