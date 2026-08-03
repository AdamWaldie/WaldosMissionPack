/*
 * Author: WaldoTheWarfighter
 * Applies a server-supplied persistence state to the local player after validation.
 *
 * Arguments:
 * 0: state <ARRAY> - versioned player-state payload
 *
 * Return Value:
 * Boolean - true when the payload was accepted
 *
 * Example:
 * [_state] remoteExecCall ["Waldo_fnc_PersistenceClientApply", owner _player];
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

if (missionNamespace getVariable ["Waldo_Persistence_SaveLoadout", true] && {count _loadout > 0}) then {
    player setUnitLoadout ([_loadout] call Waldo_fnc_ACRE2FilterLoadout);
    missionNamespace setVariable ["Waldo_ACRE2_LoadoutGeneration", (missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0]) + 1];
    missionNamespace setVariable ["Waldo_ACRE2_PersistenceRadioGeneration", -1];
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
    [_radios, _generation] spawn Waldo_fnc_ACRE2ApplyRadioState;
} else {
    [true, "PERSISTENCE_BASELINE"] spawn Waldo_fnc_ACRE2ApplyPlayerPlan;
};

["PERSISTENCE", "Persistent player state loaded.", "SUCCESS", "PERSISTENCE"] call Waldo_fnc_FeatureNotifyLocal;
true
