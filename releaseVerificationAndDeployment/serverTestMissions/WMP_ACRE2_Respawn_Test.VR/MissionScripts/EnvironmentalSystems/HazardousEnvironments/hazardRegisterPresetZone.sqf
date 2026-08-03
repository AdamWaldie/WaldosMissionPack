/*
 * Author: WaldoTheWarfighter
 * Registers a hazardous zone from one feature-specific preset plus optional overrides.
 *
 * The preset is copied before overrides are applied, so repeated registrations do not mutate the
 * shared preset catalogue. Registration is delegated to Waldo_fnc_HazardRegisterZone. This is
 * currently called directly by mission scripts and inventoried by the full-pack function station.
 *
 * Arguments:
 * 0: key <STRING> - stable unique zone name
 * 1: area <OBJECT|STRING|ARRAY> - supported zone definition
 * 2: preset key <STRING> (default: MILD)
 * 3: overrides <HASHMAP> (default: empty)
 *
 * Return Value:
 * Boolean - true when the preset exists and the zone was registered
 *
 * Example:
 * ["reactor", reactorTrigger, "SEVERE", createHashMapFromArray [["notifyTransitions", true]]] call Waldo_fnc_HazardRegisterPresetZone;
 */

params ["_key", "_area", ["_presetKey", "MILD", [""]], ["_overrides", createHashMap, [createHashMap]]];
private _presets = missionNamespace getVariable ["Waldo_Hazard_Presets", createHashMap];
_presetKey = toUpperANSI _presetKey;
if !(_presetKey in (keys _presets)) exitWith {false};
private _profile = createHashMap;
private _preset = _presets get _presetKey;
{_profile set [_x, _preset get _x]} forEach keys _preset;
{_profile set [_x, _overrides get _x]} forEach keys _overrides;
[_key, _area, _profile] call Waldo_fnc_HazardRegisterZone
