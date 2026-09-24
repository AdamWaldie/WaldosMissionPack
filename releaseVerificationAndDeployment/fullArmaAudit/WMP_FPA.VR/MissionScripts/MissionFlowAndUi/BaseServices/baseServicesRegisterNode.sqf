/*
 * Author: WaldoTheWarfighter
 * Add one placed object to a named base-service network. Objects with the same
 * network ID can offer travel between them. Give each object only the services
 * players should find there. Enable Waldo_BaseServices_Enable first.
 *
 * Locality and authority: The server owns the network. Eden also runs the Init
 * field on clients, but those calls do nothing. The server waits for settings,
 * then sends the complete network and its markers to every client, including JIP.
 * Repeat and JIP: Calling again updates this object without duplicating actions.
 *
 * Arguments:
 * 0: object <OBJECT> - the placed stand, laptop or other interaction object.
 * 1: network ID <STRING> - same ID joins the same travel network.
 * 2: label <STRING> - name shown to players and in travel destinations.
 * 3: services <ARRAY of STRING> - choose SAVE, HEAL, SPECTATE and/or TELEPORT.
 * 4: icon <STRING> - optional .paa path; default WMP service icon.
 * 5: transition <STRING or ARRAY> - optional travel preset or custom settings;
 *    empty string (default) uses the network's preset.
 * 6: marker offset <ARRAY [x,y,z]> - optional model-space point; empty array
 *    (default) puts the 3D marker on the object's upper surface.
 * Return Value: <BOOL> - true when the server accepts or queues the setup.
 * Example: In the object's Eden Init field:
 * [this, "MainBase", "Medical", ["HEAL", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
 * Result: This object offers full heal and travel to other TELEPORT nodes in MainBase.
 * Current callers: Eden object Init, base-service compositions and ZEN node setup.
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
