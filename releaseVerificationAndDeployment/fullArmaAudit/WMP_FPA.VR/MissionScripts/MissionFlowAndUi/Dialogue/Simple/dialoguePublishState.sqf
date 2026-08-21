/*
 * Author: WaldoTheWarfighter
 * Publishes one serialisable descriptor snapshot for all registered dialogue speakers.
 * Locality/authority: server builds state; interface clients reconcile local actions.
 * Repeat/JIP behaviour: full replacement snapshot; JIP clients request the current version.
 * Arguments: 0 optional owner ID <NUMBER>, default all clients. Return Value: ARRAY descriptors.
 * Current callers: registration, clearing and state requests. Example: [] call Waldo_fnc_DialoguePublishState;
 */
params [["_ownerId", -2, [0]]];
if (!isServer) exitWith {[]};
private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
private _snapshot = [];
private _keys = keys _registry;
_keys sort true;
{
    private _entry = _registry get _x;
    private _speaker = _entry getOrDefault ["speaker", objNull];
    if (!isNull _speaker) then {
        private _kind = _entry getOrDefault ["kind", "SIMPLE"];
        private _reference = if (_kind == "ADVANCED") then {_entry getOrDefault ["conversationId", ""]} else {_entry getOrDefault ["archetype", "SPECIFIC"]};
        _snapshot pushBack [_speaker, _kind, _reference];
    };
} forEach _keys;
private _version = (missionNamespace getVariable ["Waldo_Dialogue_StateVersion", 0]) + 1;
missionNamespace setVariable ["Waldo_Dialogue_StateVersion", _version];
[_version, _snapshot] remoteExecCall ["Waldo_fnc_DialogueReceiveStateLocal", _ownerId];
_snapshot
