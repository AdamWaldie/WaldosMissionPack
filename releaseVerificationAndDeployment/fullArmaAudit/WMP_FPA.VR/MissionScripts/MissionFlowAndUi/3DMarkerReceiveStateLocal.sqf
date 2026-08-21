/*
 * Author: WaldoTheWarfighter
 * Installs one authoritative custom-3D-marker snapshot on its requesting interface client.
 * Locality/authority: only changes interface-local render state; the server remains authoritative.
 * Repeat/JIP behaviour: stale snapshots are ignored, equal/newer snapshots replace local state,
 * clear the coalescing sentinel and establish the revision used by later compact deltas.
 * Arguments: 0 revision <NUMBER>; 1 complete marker registry <ARRAY>.
 * Return Value: BOOL - true when accepted/already current; false without an interface or revision.
 * Current caller: Waldo_fnc_Marker3DRequestStateServer via owner-targeted remoteExecCall.
 * Example: [4, [["hq", [0,0,0]]]] call Waldo_fnc_Marker3DReceiveStateLocal;
 */
params [["_revision", -1, [0]], ["_registry", [], [[]]]];
if (!hasInterface || {_revision < 0}) exitWith {false};
missionNamespace setVariable ["Waldo_3DMarker_StateRequestPending", false];
if (_revision < (missionNamespace getVariable ["Waldo_3DMarker_Revision", -1])) exitWith {true};
missionNamespace setVariable ["Waldo_3DMarker_Registry", +_registry];
missionNamespace setVariable ["Waldo_3DMarker_Revision", _revision];
true
