/*
 * Author: Waldo
 * Removes a named hazardous-environment zone without disturbing other zones.
 *
 * Arguments:
 * 0: key <STRING> - registered zone name
 *
 * Return Value:
 * Boolean - true when a zone was removed
 *
 * Example:
 * ["reactor"] call Waldo_fnc_HazardUnregisterZone;
 */

params [["_key", "", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
private _zones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
private _index = _zones findIf {(_x select 0) == _key};
if (_index < 0) exitWith {false};
_zones deleteAt _index;
missionNamespace setVariable ["Waldo_Hazard_Zones", _zones, isServer];
true
