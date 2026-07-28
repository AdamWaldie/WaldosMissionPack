/*
 * Author: Waldo
 * Registers a hazardous zone from one feature-specific preset plus optional overrides.
 *
 * Arguments: 0: key <STRING>; 1: area <OBJECT|STRING|ARRAY>; 2: preset key <STRING>; 3: overrides <HASHMAP>
 * Return Value: Boolean
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
