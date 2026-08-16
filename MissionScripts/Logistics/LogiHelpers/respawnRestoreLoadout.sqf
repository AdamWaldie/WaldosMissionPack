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
 * 2: trigger source <STRING> - "RESPAWN_EH" or "UNIT_WATCHDOG", diagnostic-only label identifying
 *    which of initPlayerLocal.sqf's two independent triggers called this (default "UNKNOWN")
 *
 * Return Value:
 * Boolean - true when this call actually performed the restore, false when skipped or deferred
 *
 * Example:
 * [_unit, _oldUnit, "RESPAWN_EH"] call Waldo_fnc_RespawnRestoreLoadout;
 *
 * Current callers: initPlayerLocal.sqf's two independent respawn triggers (see its own comments).
 */
params [["_unit", objNull, [objNull]], ["_oldUnit", objNull, [objNull]], ["_triggerSource", "UNKNOWN", [""]]];
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
    [_unit, _oldUnit, _triggerSource] spawn {
        params ["_unit", "_oldUnit", "_triggerSource"];
        private _deadline = diag_tickTime + 5;
        waitUntil {sleep 0.05; local _unit || {diag_tickTime >= _deadline}};
        if (local _unit) then {
            [_unit, _oldUnit, _triggerSource] call Waldo_fnc_RespawnRestoreLoadout;
        } else {
            diag_log format ["[WMP LOADOUT] RespawnRestoreLoadout: %1 never became local within 5s; giving up. This should not happen for a client's own respawned unit - report this RPT.", _unit];
        };
    };
    false
};
missionNamespace setVariable ["Waldo_RespawnRestoreHandledUnit", _unit];
// Diagnostic-only session counter - a genuinely new life reaches this point exactly once (the dedup
// and locality guards above already filtered out duplicates and not-yet-local calls), so this is a
// reliable per-client "how many respawns has this trace covered" figure for respawn/loadout-restore.
missionNamespace setVariable ["Waldo_Player_RespawnCount", (missionNamespace getVariable ["Waldo_Player_RespawnCount", 0]) + 1];

private _sideKey = switch (side _unit) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
// UID+side only - a scripted respawn always creates a fresh, unnamed unit object, so vehicleVarName
// never matches the Eden-named unit a snapshot was captured against.
private _currentIdentity = [getPlayerUID _unit, _sideKey];
private _snapshot = missionNamespace getVariable ["Waldo_Player_RespawnSnapshot", []];
private _savedIdentity = if (count _snapshot >= 4) then {_snapshot select 0} else {missionNamespace getVariable ["Waldo_Player_LoadoutIdentity", []]};
private _identityMatches = _savedIdentity isEqualTo _currentIdentity;
private _savedLoadout = if (count _snapshot >= 4) then {_snapshot select 1} else {missionNamespace getVariable ["Waldo_Player_Inventory", []]};
// Only present on snapshots saved by the current saveRespawnLoadout.sqf; empty on anything older,
// which simply skips the apply-verification step below rather than comparing against nothing.
private _savedCanary = if (count _snapshot >= 5) then {_snapshot select 4} else {[]};
private _restoredCount = 0;
// Never let an Eden/CBA @ callsign radio-setup attribute copied to the new body race the saved
// radio restore below. WMP owns the one initial assignment and explicit saved-state restoration.
// ACRE parses this variable as serialized array text, so "[]" is its valid empty representation.
_unit setVariable ["acre_sys_radio_setup", "[]", true];
if (_identityMatches && {count _savedLoadout > 0}) then {
    _unit setUnitLoadout _savedLoadout;
    _restoredCount = count _savedLoadout;
    // setUnitLoadout can silently no-op if called before the respawned unit's inventory is fully
    // ready - the same transient window the locality retry above exists for. Loadout restore is
    // mission-critical, so verify the apply actually took instead of trusting one call, and retry
    // briefly if it didn't. Verification compares a small set of stable, ACRE-independent equipment
    // commands (the canary saved alongside the loadout) rather than getUnitLoadout itself: its
    // top-level shape never changes with content, so a count comparison could never detect a no-op,
    // while a full deep-equality comparison would false-positive the moment ACRE assigns fresh unique
    // radio item IDs onto the just-restored gear.
    if (count _savedCanary >= 7) then {
        [_unit, _savedLoadout, _savedCanary] spawn {
            params ["_unit", "_savedLoadout", "_savedCanary"];
            private _canaryMatches = {
                (primaryWeapon _unit) == (_savedCanary select 0)
                && {(secondaryWeapon _unit) == (_savedCanary select 1)}
                && {(handgunWeapon _unit) == (_savedCanary select 2)}
                && {(uniform _unit) == (_savedCanary select 3)}
                && {(vest _unit) == (_savedCanary select 4)}
                && {(backpack _unit) == (_savedCanary select 5)}
                && {(headgear _unit) == (_savedCanary select 6)}
            };
            private _tries = 0;
            while {
                _tries < 5
                && {alive _unit}
                && {!(call _canaryMatches)}
            } do {
                sleep 0.2;
                if (alive _unit) then {_unit setUnitLoadout _savedLoadout;};
                _tries = _tries + 1;
            };
            private _finalMatch = call _canaryMatches;
            // Diagnostic-only outcome, read by respawn/loadout-apply-verify. A unit that died again
            // mid-retry (!alive) is not a verify failure - there is nothing left to verify - so it is
            // recorded as a distinct outcome rather than folded into "failed".
            private _verifyOutcome = if !(alive _unit) then {"UNIT_DIED"} else {if (_finalMatch) then {"OK"} else {"FAILED"}};
            missionNamespace setVariable ["Waldo_Player_LoadoutVerifyOutcome", [_verifyOutcome, _tries, diag_tickTime]];
            if (alive _unit && {!_finalMatch}) then {
                diag_log format ["[WMP LOADOUT][RESPAWN][VERIFY_FAILED] unit=%1 expectedCanary=%2 after %3 retries.", _unit, _savedCanary, _tries];
            } else {
                if (_tries > 0) then {
                    diag_log format ["[WMP LOADOUT][RESPAWN][VERIFY_RETRY_OK] unit=%1 succeeded after %2 retries.", _unit, _tries];
                };
            };
        };
    };
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
// Element 0-2 are the original, load-bearing shape read elsewhere (e.g. runDiagnosticsClient.sqf's
// "_lastRestore params [...]"); everything from index 3 on is additive diagnostic detail only.
missionNamespace setVariable ["Waldo_Player_LastRespawnRestore", [_identityMatches, _restoredCount, diag_tickTime, _triggerSource, _source, _snapshotAge, _savedRadioCount, _generation]];
if (count _savedRadios >= 3 && {count (_savedRadios select 1) > 0}) then {
    diag_log format ["[WMP LOADOUT][RESPAWN][RADIO_RESTORE_START] generation=%1 expectedOccurrences=%2.", _generation, _savedRadioCount];
    missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", true];
    [_savedRadios, _generation] spawn {
        params ["_radioState", "_loadoutGeneration"];
        private _restored = [_radioState, _loadoutGeneration] call Waldo_fnc_ACRE2ApplyRadioState;
        missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
        if (_restored) then {
            diag_log format ["[WMP LOADOUT][RESPAWN][RADIO_RESTORE_OK] generation=%1.", _loadoutGeneration];
            missionNamespace setVariable ["Waldo_Player_LastRadioRestoreOutcome", ["RESTORED", _loadoutGeneration, diag_tickTime]];
            ["RESPAWN_RESTORED", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        } else {
            diag_log format ["[WMP LOADOUT][RESPAWN][RADIO_RESTORE_FAILED] generation=%1; applying current mission plan.", _loadoutGeneration];
            missionNamespace setVariable ["Waldo_Player_LastRadioRestoreOutcome", ["FAILED", _loadoutGeneration, diag_tickTime]];
            ["RESPAWN_RESTORE_FALLBACK", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        };
    };
} else {
    diag_log format ["[WMP LOADOUT][RESPAWN][RADIO_BASELINE] generation=%1 reason=no complete saved radio snapshot.", _generation];
    missionNamespace setVariable ["Waldo_Player_LastRadioRestoreOutcome", ["BASELINE", _generation, diag_tickTime]];
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
