/*
 * Author: WaldoTheWarfighter
 * Captures the local player's enabled persistence fields into a network-safe array.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Array - versioned player-state payload
 *
 * Example:
 * private _state = [] call Waldo_fnc_PersistenceClientCapture;
 */

if !(hasInterface) exitWith {[]};

private _saveLoadout = missionNamespace getVariable ["Waldo_Persistence_SaveLoadout", true];
private _saveMedical = missionNamespace getVariable ["Waldo_Persistence_SaveMedical", true];
private _saveNeeds = missionNamespace getVariable ["Waldo_Persistence_SaveFoodWater", false];
private _savePosition = missionNamespace getVariable ["Waldo_Persistence_SavePosition", false];
private _saveRadios = missionNamespace getVariable ["Waldo_Persistence_SaveRadios", false];

private _loadout = if (_saveLoadout) then {[getUnitLoadout player] call Waldo_fnc_ACRE2FilterLoadout} else {[]};
private _medical = [];
if (_saveMedical && {isClass (configFile >> "CfgPatches" >> "ace_medical")}) then {
    _medical = [player] call ace_medical_fnc_serializeState;
};

private _needs = if (_saveNeeds) then {
    [
        player getVariable ["acex_field_rations_hunger", 0],
        player getVariable ["acex_field_rations_thirst", 0]
    ]
} else {[]};

private _position = if (_savePosition) then {[getPosATL player, getDir player]} else {[]};
private _radios = if (_saveRadios) then {[] call Waldo_fnc_ACRE2CaptureRadioState} else {[]};

[1, _loadout, _medical, _needs, _position, _radios]
