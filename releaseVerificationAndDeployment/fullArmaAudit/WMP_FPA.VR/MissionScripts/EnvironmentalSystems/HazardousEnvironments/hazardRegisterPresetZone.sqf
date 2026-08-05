/*
 * Author: WaldoTheWarfighter, Val
 * Registers a hazardous zone from one feature-specific preset plus optional overrides.
 *
 * The preset is copied before overrides are applied, so repeated registrations do not mutate the
 * shared preset catalogue. Registration is delegated to Waldo_fnc_HazardRegisterZone. This is
 * currently called directly by mission scripts and inventoried by the full-pack function station.
 * Locality and authority: Call on the server. It copies local configuration data, then delegates
 * authoritative validation, storage and publication to Waldo_fnc_HazardRegisterZone.
 *
 * Arguments:
 * 0: key <STRING> - stable unique zone name
 * 1: area <OBJECT|STRING|ARRAY> - supported zone definition
 * 2: preset key <STRING> (default: LOW_RADIATION)
 * 3: overrides <HASHMAP> (default: empty)
 *
 * Return Value:
 * Boolean - true when the preset exists and the zone was registered
 *
 * Example:
 * ["reactor", reactorTrigger, "SEVERE_RADIATION", createHashMapFromArray [["notifyTransitions", true]]] call Waldo_fnc_HazardRegisterPresetZone;
 * Result: Registers `reactor` with a copied severe-radiation profile plus the supplied override.
 * Current callers: server mission scripts and the full-pack audit function station.
 */

params ["_key", "_area", ["_presetKey", "LOW_RADIATION", [""]], ["_overrides", createHashMap, [createHashMap]]];
private _presets = missionNamespace getVariable ["Waldo_Hazard_Presets", createHashMap];
_presetKey = toUpperANSI _presetKey;
if !(_presetKey in (keys _presets)) exitWith {false};
private _profile = createHashMap;
private _preset = _presets get _presetKey;
{_profile set [_x, _preset get _x]} forEach keys _preset;
{_profile set [_x, _overrides get _x]} forEach keys _overrides;
[_key, _area, _profile] call Waldo_fnc_HazardRegisterZone
