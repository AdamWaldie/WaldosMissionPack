/*
 * Author: WaldoTheWarfighter
 * Applies a server-supplied persistence load result to the local player after validation.
 * Locality and authority: the server remote-executes this on the owning player client. It rejects
 * requests from any non-server remote owner and mutates only the local player. FOUND restores the
 * saved state, NONE releases the authored baseline, and FAILED releases gameplay while permanently
 * withholding automatic persistence writes for this client session. Repeated/stale replies are
 * rejected by the PENDING state, so one server response owns each join/JIP handshake.
 *
 * Arguments:
 * 0: result <STRING> - FOUND, NONE or FAILED
 * 1: state <ARRAY> - versioned player-state payload; required only for FOUND
 *
 * Return Value:
 * Boolean - true when the payload was accepted
 *
 * Example:
 * ["FOUND", _state] remoteExecCall ["Waldo_fnc_PersistenceClientApply", owner _player];
 *
 * Result:
 * The owning client restores configured player state and prepares its ordinary respawn snapshot.
 *
 * Current callers:
 * Waldo_fnc_PersistenceServerHandleLoadPlayer on the server.
 */

params [["_result", "FAILED", [""]], ["_state", [], [[]]]];
if !(hasInterface) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
private _currentLoadState = missionNamespace getVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"];
if !(_currentLoadState in ["PENDING", "WAITING_RUNTIME"]) exitWith {
    diag_log format ["[WMP PERSISTENCE] Ignored stale player-load result %1 while state was %2.", _result, _currentLoadState];
    false
};
_result = toUpperANSI _result;
if (_result == "FAILED") exitWith {
    missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"];
    missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", false];
    diag_log "[WMP PERSISTENCE] Player load failed validation; ACRE baseline released and automatic persistence writes remain disabled.";
    ["PERSISTENCE_LOAD_FAILED", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
    true
};
if (_result == "NONE") exitWith {
    missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "NONE"];
    private _acreConfig = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
    private _acreManaged = isClass (configFile >> "CfgPatches" >> "acre_main") && {_acreConfig getOrDefault ["enabled", true]};
    if (_acreManaged) then {
        ["PERSISTENCE_BASELINE", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
    } else {
        [false] call Waldo_fnc_SaveLoadout;
        missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", true];
    };
    true
};
if (_result != "FOUND" || {count _state < 6}) exitWith {
    missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"];
    missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", false];
    diag_log format ["[WMP PERSISTENCE] Rejected malformed player-load result %1.", _result];
    ["PERSISTENCE_MALFORMED", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
    false
};

_state params ["_version", "_loadout", "_medical", "_needs", "_position", "_radios"];
if (_version != 1) exitWith {
    missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"];
    missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", false];
    diag_log format ["[WMP PERSISTENCE] Rejected unsupported player-state version %1.", _version];
    ["PERSISTENCE_VERSION_FAILED", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
    false
};

missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", true];
if (missionNamespace getVariable ["Waldo_Persistence_SaveLoadout", true] && {count _loadout > 0}) then {
    private _filteredLoadout = [_loadout] call Waldo_fnc_ACRE2FilterLoadout;
    player setUnitLoadout _filteredLoadout;
    missionNamespace setVariable ["Waldo_Player_Inventory", _filteredLoadout];
    private _sideKey = switch (side player) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
    // UID+side only - matches saveRespawnLoadout.sqf; vehicleVarName never survives a scripted respawn.
    missionNamespace setVariable ["Waldo_Player_LoadoutIdentity", [getPlayerUID player, _sideKey]];
    missionNamespace setVariable ["Waldo_ACRE2_LoadoutGeneration", (missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0]) + 1];
    missionNamespace setVariable ["Waldo_ACRE2_RestoredRadioGeneration", -1];
};
if (missionNamespace getVariable ["Waldo_Persistence_SaveMedical", true] && {count _medical > 0} && {isClass (configFile >> "CfgPatches" >> "ace_medical")}) then {
    [player, _medical] call ace_medical_fnc_deserializeState;
};
if (missionNamespace getVariable ["Waldo_Persistence_SaveFoodWater", false] && {count _needs >= 2}) then {
    player setVariable ["acex_field_rations_hunger", _needs select 0, true];
    player setVariable ["acex_field_rations_thirst", _needs select 1, true];
};
if (missionNamespace getVariable ["Waldo_Persistence_SavePosition", false] && {count _position >= 2}) then {
    player setPosATL (_position select 0);
    player setDir (_position select 1);
};

private _generation = missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0];
private _acreConfig = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
private _acreManaged = isClass (configFile >> "CfgPatches" >> "acre_main") && {_acreConfig getOrDefault ["enabled", true]};
if (_acreManaged && {missionNamespace getVariable ["Waldo_Persistence_SaveRadios", false]} && {count _radios > 0}) then {
    missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", true];
    [_radios, _generation] spawn {
        params ["_savedRadios", "_loadoutGeneration"];
        if !([_savedRadios, _loadoutGeneration] call Waldo_fnc_ACRE2ApplyRadioState) then {
            diag_log "[WMP PERSISTENCE] Saved ACRE radio state could not be restored; applying the current mission plan.";
            missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "FOUND"];
            missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
            ["PERSISTENCE_RESTORE_FALLBACK", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        } else {
            // Capture one complete ordinary-respawn snapshot only after both the persisted loadout
            // and its newly issued ACRE radio IDs have been restored. This prevents respawn from
            // observing a persisted inventory paired with an older or empty radio-state array.
            // Bounded settle-wait first: this follows a scripted setUnitLoadout earlier in this file
            // (see the persisted-loadout apply above), the same class of "object exists but inventory
            // hasn't finished settling" race the mission-start baseline capture guards against.
            [player] call Waldo_fnc_LoadoutWaitStable;
            missionNamespace setVariable ["Waldo_Player_NextRespawnSnapshotSource", "PERSISTENCE_RESTORED"];
            [false] call Waldo_fnc_SaveLoadout;
            missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "FOUND"];
            missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", true];
            missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
            ["PERSISTENCE_RESTORED", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        };
    };
} else {
    missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "FOUND"];
    missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
    if (_acreManaged) then {
        ["PERSISTENCE_BASELINE", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
    } else {
        [false] call Waldo_fnc_SaveLoadout;
        missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", true];
    };
};

["PERSISTENCE", "Persistent player state loaded.", "SUCCESS", "PERSISTENCE"] call Waldo_fnc_FeatureNotifyLocal;
true
