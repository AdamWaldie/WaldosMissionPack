/*
 * Author: WaldoTheWarfighter, Val
 * Removes a named hazardous-environment zone without disturbing other zones.
 *
 * Unauthorized client remote execution is rejected. The authoritative runtime path broadcasts
 * removal and clears the matching JIP registration. This is currently called by the ZEN remove
 * module, Waldo_fnc_FeatureRuntimeApply and mission scripts.
 * Locality and authority: Server-authoritative. Unapproved client remote execution is rejected;
 * accepted removal republishes the complete registry through the replaceable JIP snapshot.
 *
 * Arguments:
 * 0: key <STRING> - registered zone name
 * 1: authorised runtime request <BOOLEAN> - internal server-wrapper proof (default false)
 *
 * Return Value:
 * Boolean - true when a zone was removed
 *
 * Example:
 * ["reactor"] call Waldo_fnc_HazardUnregisterZone;
 * Result: Removes only `reactor`, disables hazards if no zones remain and updates every client/JIP.
 * Current callers: ZEN removal, Waldo_fnc_FeatureRuntimeApply and server mission scripts.
 */

params [["_key", "", [""]], ["_authorisedRuntime", false, [false]]];
if !(isServer) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2} && {!_authorisedRuntime}) exitWith {false};
private _zones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
private _index = _zones findIf {(_x select 0) == _key};
if (_index < 0) exitWith {false};
_zones deleteAt _index;
missionNamespace setVariable ["Waldo_Hazard_Zones", _zones];
if (_zones isEqualTo []) then {missionNamespace setVariable ["Waldo_Hazard_Enable", false, true]};
// Safe no-op when this zone never registered a marker (Waldo_fnc_Remove3DMarker returns false for an
// unknown id) - every removal path (ZEN, mission scripts, the emitter's own auto-cleanup EventHandler)
// funnels through here, so this is the single teardown point that needs to know about the marker.
[format ["WMP_HAZARD_%1", _key]] call Waldo_fnc_Remove3DMarker;
[] call Waldo_fnc_HazardPublishState;
diag_log format ["[WMP HAZARD] Removed zone '%1'; authoritative zone count=%2.", _key, count _zones];
true
