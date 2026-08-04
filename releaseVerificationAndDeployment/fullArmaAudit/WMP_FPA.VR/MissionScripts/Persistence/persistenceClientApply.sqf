/*
 * Author: WaldoTheWarfighter
 * Applies a server-supplied persistence state to the local player after validation.
 * Locality and authority: the server remote-executes this on the owning player client. It rejects
 * requests from any non-server remote owner and mutates only the local player.
 *
 * Arguments:
 * 0: state <ARRAY> - versioned player-state payload
 *
 * Return Value:
 * Boolean - true when the payload was accepted
 *
 * Example:
 * [_state] remoteExecCall ["Waldo_fnc_PersistenceClientApply", owner _player];
 *
 * Result:
 * The owning client restores configured player state and prepares its ordinary respawn snapshot.
 *
 * Current callers:
 * Waldo_fnc_PersistenceServerHandleLoadPlayer on the server.
 */

params [["_state", [], [[]]]];
if !(hasInterface) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (count _state < 6) exitWith {false};

_state params ["_version", "_loadout", "_medical", "_needs", "_position", "_radios"];
if (_version != 1) exitWith {
    diag_log format ["[WMP PERSISTENCE] Rejected unsupported player-state version %1.", _version];
    false
};

missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", true];
if (missionNamespace getVariable ["Waldo_Persistence_SaveLoadout", true] && {count _loadout > 0}) then {
    private _filteredLoadout = [_loadout] call Waldo_fnc_ACRE2FilterLoadout;
    player setUnitLoadout _filteredLoadout;
    missionNamespace setVariable ["Waldo_Player_Inventory", _filteredLoadout];
    private _sideKey = switch (side player) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
    missionNamespace setVariable ["Waldo_Player_LoadoutIdentity", [getPlayerUID player, vehicleVarName player, _sideKey]];
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
if (missionNamespace getVariable ["Waldo_Persistence_SaveRadios", false] && {count _radios > 0}) then {
    missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", true];
    [_radios, _generation] spawn {
        params ["_savedRadios", "_loadoutGeneration"];
        if !([_savedRadios, _loadoutGeneration] call Waldo_fnc_ACRE2ApplyRadioState) then {
            diag_log "[WMP PERSISTENCE] Saved ACRE radio state could not be restored; applying the current mission plan.";
            missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
            ["PERSISTENCE_RESTORE_FALLBACK", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        } else {
            missionNamespace setVariable ["Waldo_Player_RadioState", _savedRadios];
            missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
            ["PERSISTENCE_RESTORED", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        };
    };
} else {
    missionNamespace setVariable ["Waldo_ACRE2_RadioRestoreInProgress", false];
    ["PERSISTENCE_BASELINE", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
};

["PERSISTENCE", "Persistent player state loaded.", "SUCCESS", "PERSISTENCE"] call Waldo_fnc_FeatureNotifyLocal;
true
