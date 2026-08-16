/*
 * Author: WaldoTheWarfighter
 * Saves the local player's current equipment and supported ACRE radio state as one logical respawn
 * snapshot. Transient ACRE unique IDs are filtered from the inventory while channel/frequency, ear,
 * volume, supported audio source and selected-radio state are stored separately by base class plus
 * same-type occurrence. Explicit player actions show themed confirmation; automatic radio/startup
 * callers can suppress presentation so no notification enters the mission loading/title sequence.
 * Locality and authority: call only on the player's interface client. The snapshot is player-local;
 * optional persistence capture sends its separately filtered state through the server lifecycle.
 *
 * Arguments:
 * 0: show notification <BOOL> (default true)
 *
 * Return Value: BOOL - true after one complete snapshot is saved. If ACRE is installed but not ready,
 * an existing complete snapshot is preserved rather than being partly overwritten.
 *
 * Example: [false] call Waldo_fnc_SaveLoadout;
 * Result: inventory and supported radio settings are saved without displaying a notification.
 * Current callers: starter/loadout-save interactions and ACRE2 radio assignment finalisation.
 */
params [["_showNotification", true, [true]]];
private _loadout = [getUnitLoadout player] call Waldo_fnc_ACRE2FilterLoadout;
// A small, ACRE-independent canary of the loadout's stable equipment commands, stored alongside the
// full loadout below. respawnRestoreLoadout.sqf uses this - not a raw getUnitLoadout comparison - to
// verify a restore actually took effect: getUnitLoadout's own top-level shape never changes with
// content (so a count comparison can never detect a silently no-op'd setUnitLoadout), while a full
// deep-equality comparison would false-positive as soon as ACRE re-assigns fresh unique radio item
// IDs onto the just-restored gear (the exact thing Waldo_fnc_ACRE2FilterLoadout strips before save).
private _canary = [primaryWeapon player, secondaryWeapon player, handgunWeapon player, uniform player, vest player, backpack player, headgear player];
private _radioState = [];
private _acrePresent = isClass (configFile >> "CfgPatches" >> "acre_main");
private _acreReady = _acrePresent && {!isNil "acre_api_fnc_isInitialized"} && {[] call acre_api_fnc_isInitialized};
if (_acreReady) then {
    _radioState = [] call Waldo_fnc_ACRE2CaptureRadioState;
};
private _sideKey = switch (side player) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
// UID+side only - a scripted respawn always creates a fresh, unnamed unit object, so vehicleVarName
// never matches between the unit a snapshot was captured against and the unit checking it on respawn.
private _identity = [getPlayerUID player, _sideKey];
private _source = missionNamespace getVariable ["Waldo_Player_NextRespawnSnapshotSource", if (_showNotification) then {"PLAYER_ACTION"} else {"AUTOMATIC"}];
missionNamespace setVariable ["Waldo_Player_NextRespawnSnapshotSource", nil];
private _existingSnapshot = missionNamespace getVariable ["Waldo_Player_RespawnSnapshot", []];
if (_acrePresent && {!_acreReady} && {count _existingSnapshot >= 4}) exitWith {
    diag_log "[WMP LOADOUT] Save deferred: ACRE is present but not ready; the previous complete respawn snapshot was preserved.";
    if (_showNotification) then {
        ["RESPAWN LOADOUT NOT SAVED", "ACRE is still preparing your radios. Your previous respawn loadout remains safe; try again shortly.", "WARNING", 5, "TOP_RIGHT", "RESPAWN_LOADOUT", "PLAYER LOADOUT", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    };
    false
};
private _snapshot = [_identity, _loadout, _radioState, diag_tickTime, _canary];
missionNamespace setVariable ["Waldo_Player_RespawnSnapshot", _snapshot];
missionNamespace setVariable ["Waldo_Player_RespawnSnapshotSource", _source];
// Compatibility mirrors for persistence and diagnostics. Restore code treats the snapshot above as
// authoritative so these values can never be observed as a half-written inventory/radio pair.
missionNamespace setVariable ["Waldo_Player_Inventory", _loadout];
missionNamespace setVariable ["Waldo_Player_RadioState", _radioState];
missionNamespace setVariable ["Waldo_Player_LoadoutIdentity", _identity];
diag_log format ["[WMP LOADOUT][SAVE][OK] source=%1 loadoutEntries=%2 radios=%3 identity=%4 acrePresent=%5 acreReady=%6.", _source, count _loadout, if (count _radioState >= 2) then {count (_radioState select 1)} else {0}, _identity, _acrePresent, _acreReady];
if (_showNotification) then {
    [
        "RESPAWN LOADOUT SAVED",
        "Your current equipment and supported radio settings will be restored when you respawn.",
        "SUCCESS",
        5,
        "TOP_RIGHT",
        "RESPAWN_LOADOUT",
        "PLAYER LOADOUT",
        "REPLACE"
    ] call Waldo_fnc_ShowUiNotification;
};
true
