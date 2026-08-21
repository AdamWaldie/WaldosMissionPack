/*
 * Author: WaldoTheWarfighter
 * Applies one revisioned custom-3D-marker change without retransmitting the complete registry.
 * Locality/authority: invoked on interface clients by the authoritative server; never mutates
 * server state. Repeat/JIP behaviour: duplicate revisions are ignored, the next revision is
 * applied once, and a gap or pre-snapshot delivery requests a complete authoritative snapshot.
 * Arguments: 0 revision <NUMBER>; 1 operation <STRING: UPSERT|REMOVE>; 2 payload <ARRAY> containing
 * one complete marker row for UPSERT or marker-ID strings for REMOVE.
 * Return Value: BOOL - true when applied or already current; false when a snapshot was requested.
 * Current callers: Waldo_fnc_Create3DMarker and Waldo_fnc_Remove3DMarker via server remoteExecCall.
 * Example: [12, "REMOVE", ["generator_alpha"]] call Waldo_fnc_Marker3DApplyDeltaLocal;
 */
params [
    ["_revision", -1, [0]],
    ["_operation", "", [""]],
    ["_payload", [], [[]]]
];
if (!hasInterface || {_revision < 0}) exitWith {false};
private _localRevision = missionNamespace getVariable ["Waldo_3DMarker_Revision", -1];
if (_revision <= _localRevision) exitWith {true};
if (_localRevision < 0 || {_revision != _localRevision + 1}) exitWith {
    [] call Waldo_fnc_Marker3DRequestStateServer;
    false
};

private _registry = +(missionNamespace getVariable ["Waldo_3DMarker_Registry", []]);
switch (toUpperANSI _operation) do {
    case "UPSERT": {
        private _id = _payload param [0, "", [""]];
        if (_id == "") exitWith {};
        private _index = _registry findIf {(_x param [0, ""]) isEqualTo _id};
        if (_index < 0) then {_registry pushBack _payload} else {_registry set [_index, _payload]};
    };
    case "REMOVE": {
        _registry = _registry select {!((_x param [0, ""]) in _payload)};
    };
    default {
        [] call Waldo_fnc_Marker3DRequestStateServer;
    };
};
if !(toUpperANSI _operation in ["UPSERT", "REMOVE"]) exitWith {false};
missionNamespace setVariable ["Waldo_3DMarker_Registry", _registry];
missionNamespace setVariable ["Waldo_3DMarker_Revision", _revision];
true
