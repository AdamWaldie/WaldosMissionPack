/*
 * Author: WaldoTheWarfighter
 * Dispatches automatic respawn-snapshot seeding for a player who was just live-side-switched onto a
 * side with no saved snapshot yet, per Waldo_Respawn_SideSwitchMode. Called only from
 * initPlayerLocal.sqf's live "group" side-change watcher - never from the ordinary respawn path, which
 * always restores an already-established per-side snapshot on its own and never needs seeding.
 *
 * Arguments:
 * 0: new side key <STRING> - "WEST", "EAST", "GUER" or "CIV"
 *
 * Return Value:
 * Boolean - true when a seed actually ran (either mode), false when skipped (toggle off, already has
 * a snapshot for this side, or called with a null player).
 *
 * Example:
 * ["EAST"] call Waldo_fnc_RespawnSeedSideSwitch;
 *
 * Current callers: initPlayerLocal.sqf's live "group" event handler.
 */
params [["_newSideKey", "", [""]]];
if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_Respawn_SeedOnSideSwitch", false]) exitWith {false};
if (isNull player) exitWith {false};
if (_newSideKey == "") exitWith {false};

private _key = format ["%1_%2", getPlayerUID player, _newSideKey];
private _snapshots = missionNamespace getVariable ["Waldo_Player_RespawnSnapshots", createHashMap];
// An already-established side is only ever touched by the normal respawn-restore path - this live
// handler exists purely to seed a FIRST snapshot for a side that has none, never to overwrite one.
if (count (_snapshots getOrDefault [_key, []]) > 0) exitWith {
    diag_log format ["[WMP LOADOUT][SIDE_SWITCH] Skipped seeding for %1: a snapshot already exists.", _key];
    false
};

private _mode = toUpper (missionNamespace getVariable ["Waldo_Respawn_SideSwitchMode", "CARRY_OVER"]);
if (_mode != "SIDE_BASE_LOADOUT") then {
    if (_mode != "CARRY_OVER") then {
        diag_log format ["[WMP LOADOUT][SIDE_SWITCH] Unrecognized Waldo_Respawn_SideSwitchMode '%1'; treating as CARRY_OVER.", _mode];
    };
    [] call Waldo_fnc_RespawnSeedCarryOver;
    // Diagnostic-only outcome, read by respawn/side-switch-seed. fellBack is always false here - this
    // branch IS the CARRY_OVER mode, not a fallback into it.
    missionNamespace setVariable ["Waldo_Player_LastSideSwitchSeed", ["CARRY_OVER", false, diag_tickTime, _newSideKey]];
    true
} else {
    private _seeded = [_newSideKey] call Waldo_fnc_RespawnSeedSideBaseLoadout;
    if (_seeded) then {
        missionNamespace setVariable ["Waldo_Player_LastSideSwitchSeed", ["SIDE_BASE_LOADOUT", false, diag_tickTime, _newSideKey]];
    } else {
        diag_log format ["[WMP LOADOUT][SIDE_SWITCH] SIDE_BASE_LOADOUT unavailable for %1 (empty/unusable mission.sqm pool); falling back to CARRY_OVER.", _newSideKey];
        [] call Waldo_fnc_RespawnSeedCarryOver;
        missionNamespace setVariable ["Waldo_Player_LastSideSwitchSeed", ["SIDE_BASE_LOADOUT", true, diag_tickTime, _newSideKey]];
    };
    true
};
