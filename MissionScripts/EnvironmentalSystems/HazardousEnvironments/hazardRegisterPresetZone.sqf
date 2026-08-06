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
 * Current callers: server mission scripts, the shipped Radiation Hazard composition's object init
 * field, and the full-pack audit function station.
 */

params ["_key", "_area", ["_presetKey", "LOW_RADIATION", [""]], ["_overrides", createHashMap, [createHashMap]]];
// Waldo_Hazard_Presets is SHARED-scope config, loaded by init.sqf's "SHARED" LoadFeatureConfigs
// call. Object init fields (this is exactly how the shipped Radiation Hazard composition triggers
// registration) are not guaranteed to run after init.sqf - a preset lookup here can silently and
// permanently miss on that race, registering nothing with no error. Defer once instead of failing:
// re-parses the same original arguments after init.sqf's Waldo_SharedFeatureConfigReady flag is
// set, then falls through to the normal synchronous path unchanged for every other caller (server
// mission scripts, ZEN) that already runs after full startup.
if !(missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]) exitWith {
    [_this] spawn {
        params ["_args"];
        waitUntil {missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]};
        _args call Waldo_fnc_HazardRegisterPresetZone;
    };
    true
};
private _presets = missionNamespace getVariable ["Waldo_Hazard_Presets", createHashMap];
_presetKey = toUpperANSI _presetKey;
if !(_presetKey in (keys _presets)) exitWith {
    diag_log format ["[WMP HAZARD] Preset zone '%1' rejected: unknown preset '%2'.", _key, _presetKey];
    false
};
private _profile = createHashMap;
private _preset = _presets get _presetKey;
{_profile set [_x, _preset get _x]} forEach keys _preset;
{_profile set [_x, _overrides get _x]} forEach keys _overrides;
[_key, _area, _profile] call Waldo_fnc_HazardRegisterZone
