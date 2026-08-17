/*
 * Author: WaldoTheWarfighter
 * Resolves which ACRE2 preset name applies to a given side for every known radio base class, using the
 * same side/PRC-343-policy lookup acre2PreInit.sqf uses to bake presets in at mission start. Extracted
 * into its own reusable function rather than staying inlined so side-switch respawn seeding and joint
 * radio nets can resolve the same side->preset mapping without duplicating this lookup a second and
 * third time.
 *
 * Arguments:
 * 0: ACRE configuration <HASHMAP> (default current mission configuration)
 * 1: side key <STRING> - "WEST", "EAST", "GUER" or "CIV"
 *
 * Return Value:
 * ARRAY of [radio base class <STRING>, preset name <STRING>] pairs, one per Waldo_fnc_ACRE2GetRadioProfiles entry.
 *
 * Example:
 * [missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap], "WEST"] call Waldo_fnc_ACRE2ResolveSidePresetMap;
 *
 * Current callers: acre2PreInit.sqf, respawnSeedSideBaseLoadout.sqf, acre2ApplyJointNets.sqf.
 */
params [["_config", missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap], [createHashMap]], ["_sideKey", "CIV", [""]]];
private _sideAliases = switch (toUpper _sideKey) do {
    case "WEST": {["WEST", "BLUFOR"]};
    case "EAST": {["EAST", "OPFOR"]};
    case "GUER": {["GUER", "INDEP", "INDEPENDENT"]};
    default {["CIV", "CIVILIAN"]};
};
private _sideIndex = (_config getOrDefault ["sides", []]) findIf {toUpper (_x select 0) in _sideAliases};
// A side left out of "sides" entirely (not just present with empty nets/groups) still needs its own
// correct official ACRE preset here - falling back to a single blanket "default" would silently bake
// every EAST/GUER player's radios onto CIV's preset instead of their own side's. Matches
// Waldo_fnc_ACRE2ValidateConfig's own per-side official preset mapping.
private _defaultPreset = switch (toUpper _sideKey) do {
    case "WEST": {"default3"}; case "EAST": {"default2"}; case "GUER": {"default4"}; default {"default"};
};
private _sidePreset = if (_sideIndex >= 0) then {((_config get "sides") select _sideIndex) select 1} else {_defaultPreset};
private _shortPreset = if (toUpper (_config getOrDefault ["prc343PresetPolicy", "FULL_RANGE"]) == "FULL_RANGE") then {"default"} else {_sidePreset};
private _map = [];
{
    private _base = _x select 0;
    _map pushBack [_base, if (toUpper _base == "ACRE_PRC343") then {_shortPreset} else {_sidePreset}];
} forEach ([_config] call Waldo_fnc_ACRE2GetRadioProfiles);
_map
