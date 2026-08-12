/*
 * Author: WaldoTheWarfighter
 * Restores a respawned unit's saved loadout and, when identity matches, its supported ACRE2 radio
 * state. This is the shared body behind both of initPlayerLocal.sqf's independent respawn triggers -
 * the "CAManBase"/"Respawn" extended event handler and the CBA_fnc_addPlayerEventHandler "unit"
 * change handler - so a genuine respawn is caught by whichever of the two actually fires first, rather
 * than depending on a single signal. Idempotent per unit object: a second call for the same freshly
 * spawned unit (both triggers firing for the same life) is a safe no-op after the first.
 *
 * Arguments:
 * 0: unit <OBJECT> - the newly (re)spawned unit; must already be local to the calling machine
 *
 * Return Value:
 * Boolean - true when this call actually performed the restore, false when skipped (not local, or
 * already handled for this unit)
 *
 * Example:
 * [_unit] call Waldo_fnc_RespawnRestoreLoadout;
 *
 * Current callers: initPlayerLocal.sqf's "Respawn" extended event handler and its
 * CBA_fnc_addPlayerEventHandler "unit" handler.
 */
params [["_unit", objNull, [objNull]]];
if (isNull _unit || {!(local _unit)}) exitWith {false};
if (_unit getVariable ["Waldo_RespawnRestoreHandled", false]) exitWith {false};
_unit setVariable ["Waldo_RespawnRestoreHandled", true];

private _sideKey = switch (side _unit) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
// UID+side only - a scripted respawn always creates a fresh, unnamed unit object, so vehicleVarName
// never matches the Eden-named unit a snapshot was captured against.
private _currentIdentity = [getPlayerUID _unit, _sideKey];
private _savedIdentity = missionNamespace getVariable ["Waldo_Player_LoadoutIdentity", []];
private _identityMatches = _savedIdentity isEqualTo _currentIdentity;
private _savedLoadout = missionNamespace getVariable ["Waldo_Player_Inventory", []];
private _restoredCount = 0;
if (_identityMatches && {count _savedLoadout > 0}) then {
    _unit setUnitLoadout _savedLoadout;
    _restoredCount = count _savedLoadout;
};
private _generation = (missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0]) + 1;
missionNamespace setVariable ["Waldo_ACRE2_LoadoutGeneration", _generation];
missionNamespace setVariable ["Waldo_ACRE2_RestoredRadioGeneration", -1];
private _savedRadios = if (_identityMatches) then {missionNamespace getVariable ["Waldo_Player_RadioState", []]} else {[]};
// Log both outcomes, not just the mismatch case - a silent success path is exactly what made a real
// restore indistinguishable from "still getting the baseline" while debugging this system;
// diagnostics also read the tracked outcome below for a client-local check.
if (_identityMatches) then {
    diag_log format ["[WMP LOADOUT] Restored saved loadout (%1 entries) for identity %2.", _restoredCount, _currentIdentity];
} else {
    diag_log format ["[WMP LOADOUT] Saved snapshot identity %1 did not match respawn identity %2; baseline retained.", _savedIdentity, _currentIdentity];
};
missionNamespace setVariable ["Waldo_Player_LastRespawnRestore", [_identityMatches, _restoredCount, diag_tickTime]];
if (count _savedRadios >= 3 && {count (_savedRadios select 1) > 0}) then {
    missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", true];
    [_savedRadios, _generation] spawn {
        params ["_radioState", "_loadoutGeneration"];
        private _restored = [_radioState, _loadoutGeneration] call Waldo_fnc_ACRE2ApplyRadioState;
        missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
        if (_restored) then {
            ["RESPAWN_RESTORED", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        } else {
            diag_log "[WMP ACRE] Saved respawn radio state could not be restored; applying the current mission plan.";
            ["RESPAWN_RESTORE_FALLBACK", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        };
    };
} else {
    ["RESPAWN_BASELINE", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
};
// Respawn Text
[] spawn Waldo_fnc_RespawnText;
// Re-apply safestart if it is still active (respawn resets damage/handlers/position)
if (missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
    [true] call Waldo_fnc_SafeStartApply;
};
[] call Waldo_fnc_SetupUiCleanupAction;
[] call Waldo_fnc_AccessibilitySelfInteractionInit;
[] call Waldo_fnc_TransportInteractionInitLocal;
true
