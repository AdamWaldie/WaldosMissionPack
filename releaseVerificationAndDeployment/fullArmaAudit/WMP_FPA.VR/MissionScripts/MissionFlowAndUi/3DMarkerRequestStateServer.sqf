/*
 * Author: WaldoTheWarfighter
 * Requests or returns the authoritative custom-3D-marker snapshot for one interface client.
 * Locality/authority: clients forward an empty request; only the server reads the authoritative
 * registry and replies to remoteExecutedOwner. Repeat/JIP behaviour: requests are locally
 * coalesced, while every accepted request returns one ordered [revision, registry] snapshot.
 * Arguments: None.
 * Return Value: BOOL - true when a request/reply was queued; false for an invalid remote owner.
 * Current callers: Waldo_fnc_Init3DMarkers and Waldo_fnc_Marker3DApplyDeltaLocal.
 * Example: [] call Waldo_fnc_Marker3DRequestStateServer;
 */
if (!isServer) exitWith {
    if (missionNamespace getVariable ["Waldo_3DMarker_StateRequestPending", false]) exitWith {true};
    missionNamespace setVariable ["Waldo_3DMarker_StateRequestPending", true];
    [] remoteExecCall ["Waldo_fnc_Marker3DRequestStateServer", 2];
    true
};
private _requestOwner = remoteExecutedOwner;
if (_requestOwner <= 2) exitWith {false};
[
    missionNamespace getVariable ["Waldo_3DMarker_Revision", 0],
    +(missionNamespace getVariable ["Waldo_3DMarker_Registry", []])
] remoteExecCall ["Waldo_fnc_Marker3DReceiveStateLocal", _requestOwner];
true
