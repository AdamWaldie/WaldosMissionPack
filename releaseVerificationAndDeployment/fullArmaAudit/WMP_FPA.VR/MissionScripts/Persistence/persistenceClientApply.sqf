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
    player setUnitLoadout _loadout;
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

if (missionNamespace getVariable ["Waldo_Persistence_SaveRadios", false] && {count _radios > 0} && {isClass (configFile >> "CfgPatches" >> "acre_main")}) then {
    [_radios] spawn {
        params ["_savedRadios"];
        sleep 2;
        private _typeCounts = createHashMap;
        {
            private _radioId = _x;
            private _baseType = [_radioId] call acre_api_fnc_getBaseRadio;
            private _index = _typeCounts getOrDefault [_baseType, 0];
            _typeCounts set [_baseType, _index + 1];
            private _savedIndex = _savedRadios findIf {(_x select 0) == _baseType && {(_x select 1) == _index}};
            if (_savedIndex >= 0) then {
                private _saved = _savedRadios select _savedIndex;
                [_radioId, _saved select 2] call acre_api_fnc_setRadioChannel;
                [_radioId, _saved select 3] call acre_api_fnc_setRadioSpatial;
            };
        } forEach ([player] call acre_api_fnc_getCurrentRadioList);
    };
};

["PERSISTENCE", "Persistent player state loaded.", "SUCCESS", "PERSISTENCE"] call Waldo_fnc_FeatureNotifyLocal;
true
