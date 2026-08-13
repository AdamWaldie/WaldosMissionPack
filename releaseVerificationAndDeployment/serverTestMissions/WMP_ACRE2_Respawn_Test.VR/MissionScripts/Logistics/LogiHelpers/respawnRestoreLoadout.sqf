/*
 * Author: WaldoTheWarfighter
 * Restores a respawned unit's saved loadout and, when identity matches, its supported ACRE2 radio
 * state. This is the shared body behind initPlayerLocal.sqf's local Respawn handler. Repeat safety is
 * tracked in missionNamespace against the actual new object; it deliberately does not use a unit
 * variable because Arma can transfer object variables to the next respawn body.
 *
 * Arguments:
 * 0: unit <OBJECT> - the newly (re)spawned unit; must already be local to the calling machine
 * 1: old unit <OBJECT> - corpse/replaced player object (default objNull)
 *
 * Return Value:
 * Boolean - true when this call actually performed the restore, false when skipped or deferred
 *
 * Example:
 * [_unit, _oldUnit] call Waldo_fnc_RespawnRestoreLoadout;
 *
 * Current callers: initPlayerLocal.sqf's local Respawn event handler.
 */
params [["_unit", objNull, [objNull]], ["_oldUnit", objNull, [objNull]]];
if (isNull _unit) exitWith {diag_log "[WMP LOADOUT] RespawnRestoreLoadout skipped: called with a null unit."; false};
if ((missionNamespace getVariable ["Waldo_RespawnRestoreHandledUnit", objNull]) isEqualTo _unit) exitWith {
    diag_log format ["[WMP LOADOUT][RESPAWN][DUPLICATE] unit=%1 owner=%2 already handled for this life.", _unit, owner _unit];
    false
};
if !(local _unit) exitWith {
    // A silent, single-shot drop here is exactly what left a respawn with no restore and no
    // explanation in RPT even after the trigger fired - retry briefly instead of giving up on the
    // first check. `player` can be reassigned to this unit fractionally before the engine's own
    // locality bookkeeping catches up; this covers that gap without blocking the caller.
    diag_log format ["[WMP LOADOUT][RESPAWN][DEFER] unit=%1 owner=%2 local=%3 retryWindow=5s.", _unit, owner _unit, local _unit];
    [_unit, _oldUnit] spawn {
        params ["_unit", "_oldUnit"];
        private _deadline = diag_tickTime + 5;
        waitUntil {sleep 0.05; local _unit || {diag_tickTime >= _deadline}};
        if (local _unit) then {
            [_unit, _oldUnit] call Waldo_fnc_RespawnRestoreLoadout;
        } else {
            diag_log format ["[WMP LOADOUT] RespawnRestoreLoadout: %1 never became local within 5s; giving up. This should not happen for a client's own respawned unit - report this RPT.", _unit];
        };
    };
    false
};
missionNamespace setVariable ["Waldo_RespawnRestoreHandledUnit", _unit];

private _sideKey = switch (side _unit) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
// UID+side only - a scripted respawn always creates a fresh, unnamed unit object, so vehicleVarName
// never matches the Eden-named unit a snapshot was captured against.
private _currentIdentity = [getPlayerUID _unit, _sideKey];
private _snapshot = missionNamespace getVariable ["Waldo_Player_RespawnSnapshot", []];
private _savedIdentity = if (count _snapshot >= 4) then {_snapshot select 0} else {missionNamespace getVariable ["Waldo_Player_LoadoutIdentity", []]};
private _identityMatches = _savedIdentity isEqualTo _currentIdentity;
private _savedLoadout = if (count _snapshot >= 4) then {_snapshot select 1} else {missionNamespace getVariable ["Waldo_Player_Inventory", []]};
private _restoredCount = 0;
// Never let an Eden/CBA @ callsign radio-setup attribute copied to the new body race the saved
// radio restore below. WMP owns the one initial assignment and explicit saved-state restoration.
_unit setVariable ["acre_sys_radio_setup", "", true];
if (_identityMatches && {count _savedLoadout > 0}) then {
    _unit setUnitLoadout _savedLoadout;
    _restoredCount = count _savedLoadout;
};
private _generation = (missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0]) + 1;
missionNamespace setVariable ["Waldo_ACRE2_LoadoutGeneration", _generation];
missionNamespace setVariable ["Waldo_ACRE2_RestoredRadioGeneration", -1];
private _savedRadios = if (_identityMatches) then {
    if (count _snapshot >= 4) then {_snapshot select 2} else {missionNamespace getVariable ["Waldo_Player_RadioState", []]}
} else {[]};
private _snapshotAge = if (count _snapshot >= 4) then {diag_tickTime - (_snapshot select 3)} else {-1};
private _savedRadioCount = if (count _savedRadios >= 2) then {count (_savedRadios select 1)} else {0};
private _source = missionNamespace getVariable ["Waldo_Player_RespawnSnapshotSource", "UNKNOWN"];
diag_log format ["[WMP LOADOUT][RESPAWN][SNAPSHOT] source=%1 age=%2 identityMatch=%3 loadoutEntries=%4 savedRadios=%5 generation=%6.", _source, _snapshotAge, _identityMatches, count _savedLoadout, _savedRadioCount, _generation];
// Log both outcomes, not just the mismatch case - a silent success path is exactly what made a real
// restore indistinguishable from "still getting the baseline" while debugging this system;
// diagnostics also read the tracked outcome below for a client-local check.
if (_identityMatches) then {
    diag_log format ["[WMP LOADOUT][RESPAWN][INVENTORY_OK] restoredEntries=%1 savedRadios=%2 identity=%3.", _restoredCount, _savedRadioCount, _currentIdentity];
} else {
    diag_log format ["[WMP LOADOUT] Saved snapshot identity %1 did not match respawn identity %2; baseline retained.", _savedIdentity, _currentIdentity];
};
missionNamespace setVariable ["Waldo_Player_LastRespawnRestore", [_identityMatches, _restoredCount, diag_tickTime]];
if (count _savedRadios >= 3 && {count (_savedRadios select 1) > 0}) then {
    diag_log format ["[WMP LOADOUT][RESPAWN][RADIO_RESTORE_START] generation=%1 expectedOccurrences=%2.", _generation, _savedRadioCount];
    missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", true];
    [_savedRadios, _generation] spawn {
        params ["_radioState", "_loadoutGeneration"];
        private _restored = [_radioState, _loadoutGeneration] call Waldo_fnc_ACRE2ApplyRadioState;
        missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
        if (_restored) then {
            diag_log format ["[WMP LOADOUT][RESPAWN][RADIO_RESTORE_OK] generation=%1.", _loadoutGeneration];
            ["RESPAWN_RESTORED", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        } else {
            diag_log format ["[WMP LOADOUT][RESPAWN][RADIO_RESTORE_FAILED] generation=%1; applying current mission plan.", _loadoutGeneration];
            ["RESPAWN_RESTORE_FALLBACK", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        };
    };
} else {
    diag_log format ["[WMP LOADOUT][RESPAWN][RADIO_BASELINE] generation=%1 reason=no complete saved radio snapshot.", _generation];
    ["RESPAWN_BASELINE", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
};
// Respawn Text
[] spawn Waldo_fnc_RespawnText;
// Rebind player-object protection only after the saved inventory exists, so ACE safety targets the
// restored weapon/muzzle. This also covers ENDEX, whose old event-handler IDs otherwise point at
// the corpse and suppress installation on the replacement body.
[_unit, _oldUnit] call Waldo_fnc_ProtectionRespawnLocal;
[] call Waldo_fnc_SetupUiCleanupAction;
[] call Waldo_fnc_AccessibilitySelfInteractionInit;
[] call Waldo_fnc_TransportInteractionInitLocal;
true
