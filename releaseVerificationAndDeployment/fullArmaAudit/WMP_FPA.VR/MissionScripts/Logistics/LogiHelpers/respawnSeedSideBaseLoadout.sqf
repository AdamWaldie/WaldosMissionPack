/*
 * Author: WaldoTheWarfighter
 * Seeds a respawn snapshot for a live-side-switched player by assembling a weapon-aware starter kit
 * from the new side's own scanned mission.sqm pool, with that side's proper ACRE2 preset reasserted
 * first (a preset is baked into a radio item at creation time, so it must be set before the assembled
 * loadout - which may include radio classnames pulled from the pool's items category - is applied).
 * The result is tagged NATIVE.
 *
 * Arguments:
 * 0: new side key <STRING> - "WEST", "EAST", "GUER" or "CIV"
 *
 * Return Value:
 * Boolean - true when a NATIVE seed was actually applied; false signals "fall back to CARRY_OVER"
 * (empty/unusable side pool, or Waldo_fnc_BuildAssembledSideLoadout could not assemble anything).
 *
 * Example: ["EAST"] call Waldo_fnc_RespawnSeedSideBaseLoadout;
 * Current callers: Waldo_fnc_RespawnSeedSideSwitch (SIDE_BASE_LOADOUT mode).
 */
params [["_newSideKey", "", [""]]];
if !(hasInterface) exitWith {false};
if (isNull player) exitWith {false};

private _sideObject = switch (_newSideKey) do {case "WEST": {west}; case "EAST": {east}; case "GUER": {independent}; default {civilian}};
private _pool = [_sideObject] call Waldo_fnc_GetSideLoadoutArray;
if (count _pool < 8) exitWith {
    diag_log format ["[WMP LOADOUT][SIDE_BASE_LOADOUT] No scanned mission.sqm pool exists for side %1.", _newSideKey];
    false
};

private _assembled = [_pool] call Waldo_fnc_BuildAssembledSideLoadout;
if (count _assembled == 0) exitWith {false};

// Preset is baked into a radio item at creation time, not at tune time - reassert this side's own
// official preset for every radio class before setUnitLoadout below can create any radio item.
if (isClass (configFile >> "CfgPatches" >> "acre_main") && {!isNil "acre_api_fnc_isInitialized"} && {[] call acre_api_fnc_isInitialized}) then {
    {
        _x params ["_base", "_preset"];
        [_base, _preset] call acre_api_fnc_setPreset;
    } forEach ([missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap], _newSideKey] call Waldo_fnc_ACRE2ResolveSidePresetMap);
};

// Live, already-fully-initialized unit - not a freshly-created respawn body, so none of the
// respawn-timing/locality races Waldo_fnc_RespawnRestoreLoadout guards against apply here.
player setUnitLoadout _assembled;
missionNamespace setVariable ["Waldo_Player_NextRespawnSnapshotTag", "NATIVE"];
diag_log format ["[WMP LOADOUT][SIDE_BASE_LOADOUT] Assembled NATIVE starter kit applied for side %1.", _newSideKey];
// Routes through the existing, already race-safe (token-coalesced) shared entry point rather than
// calling Waldo_fnc_ACRE2ApplyPlayerPlan directly; its own tail logic performs the tagged save once
// the plan is confirmed applied, avoiding a second, racing explicit save.
["SIDE_SWITCH_NATIVE", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
true
