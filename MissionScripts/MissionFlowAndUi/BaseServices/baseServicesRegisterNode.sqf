/*
 * Author: WaldoTheWarfighter
 * Purpose: Adds or updates one Eden/object-init service node in a named base network.
 * Locality / Authority: Only the server mutates the registry; object Init runs on every machine.
 * Repeat / JIP: Duplicate object Init calls are ignored off-server; server upserts by object.
 *   Registration waits in scheduled code for the shared settings before publishing a full snapshot.
 * Arguments: object <OBJECT>; group ID <STRING>; label <STRING>; services <ARRAY>;
 *   icon <STRING> (default WMP service icon); transition <STRING|ARRAY> (default group preset);
 *   marker offset <ARRAY> (default object surface).
 * Return Value: <BOOL> request accepted on the server.
 * Current callers: Eden object Init, service compositions and ZEN service configuration.
 * Example: [this, "MainBase", "Medical", ["HEAL", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
 */
params [
    ["_object", objNull, [objNull]], ["_groupId", "", [""]], ["_label", "", [""]],
    ["_services", [], [[]]],
    ["_icon", "\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa", [""]],
    ["_transition", "", ["", []]], ["_offset", [], [[]]]
];
if (!isServer || {isRemoteExecuted} || {isNull _object} || {_groupId isEqualTo ""} || {_label isEqualTo ""}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]) exitWith {
    _this spawn {
        waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false] || {isNull (_this select 0)}};
        if (!isNull (_this select 0)) then {_this call Waldo_fnc_BaseServicesRegisterNode};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_BaseServices_Enable", false]) exitWith {false};
// Moving a node to another named network must not leave it in both groups.
{
    _x params ["_otherId", "_otherRows", "_otherTransition"];
    if (_otherId isNotEqualTo _groupId && {(_otherRows findIf {(_x select 0) isEqualTo _object}) >= 0}) then {
        [_otherId, _otherRows select {(_x select 0) isNotEqualTo _object}, _otherTransition]
            call Waldo_fnc_BaseServicesRegister;
    };
} forEach +(missionNamespace getVariable ["Waldo_BaseServices_Registry", []]);
private _registry = missionNamespace getVariable ["Waldo_BaseServices_Registry", []];
private _index = _registry findIf {(_x select 0) isEqualTo _groupId};
private _rows = if (_index >= 0) then {+((_registry select _index) select 1)} else {[]};
private _groupTransition = if (_index >= 0) then {(_registry select _index) select 2} else {"STANDARD"};
private _row = [_object, _label, _services, _icon, _transition, _offset];
private _old = _rows findIf {(_x select 0) isEqualTo _object};
if (_old >= 0) then {_rows set [_old, _row]} else {_rows pushBack _row};
[_groupId, _rows, _groupTransition] call Waldo_fnc_BaseServicesRegister
