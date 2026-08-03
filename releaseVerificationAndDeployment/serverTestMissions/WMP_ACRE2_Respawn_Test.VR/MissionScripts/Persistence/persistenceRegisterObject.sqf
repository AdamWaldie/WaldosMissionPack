/*
 * Author: WaldoTheWarfighter
 * Registers an editor-placed or scripted object for repeat-safe server persistence.
 * This is a server-only mission setup call. When persistence is enabled but its dependency/startup
 * gate is still pending, registration is queued by key and replayed after activation. The function
 * does not enable persistence and returns false when called on a client or when the feature is off.
 *
 * Arguments:
 * 0: object <OBJECT> - object to persist
 * 1: key <STRING> - stable database key, unique within the mission
 * 2: options <ARRAY> - [save cargo, save damage, save fuel, save ammo/pylons, save position,
 *      custom variable names]. Missing first-five values default true; missing custom variables use
 *      Waldo_Persistence_DefaultCustomVariables. Keys permit letters, digits, underscore and dash.
 *
 * Return Value:
 * Boolean - true when registered
 *
 * Example:
 * if (isServer) then {
 *     [supplyCrate, "base_supply_1", [true, false, false, false, false]]
 *         call Waldo_fnc_PersistenceRegisterObject;
 * };
 *
 * Current callers: mission-maker server setup, persistence ZEN registration and audit mission.
 */

params [
    ["_object", objNull, [objNull]],
    ["_key", "", [""]],
    ["_options", [true, true, true, true, true], [[]]]
];

if !(isServer) exitWith {false};
if (remoteExecutedOwner > 0) exitWith {false};
if (isNull _object || {_key == ""}) exitWith {false};

if !(missionNamespace getVariable ["Waldo_Persistence_Active", false]) exitWith {
    if (missionNamespace getVariable ["Waldo_Persistence_Enable", false]) then {
        private _pending = missionNamespace getVariable ["Waldo_Persistence_PendingObjects", []];
        private _existingPending = _pending findIf {(_x select 1) == _key};
        if (_existingPending >= 0) then {
            _pending set [_existingPending, [_object, _key, _options]];
        } else {
            _pending pushBack [_object, _key, _options];
        };
        missionNamespace setVariable ["Waldo_Persistence_PendingObjects", _pending];
        true
    } else {
        false
    }
};

private _safeKey = [_key, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_safeKey != _key || {_safeKey == ""}) exitWith {
    diag_log format ["[WMP PERSISTENCE] Object key '%1' contains unsupported characters.", _key];
    false
};

_options resize 6;
for "_i" from 0 to 4 do {
    if (isNil {_options select _i}) then {_options set [_i, true]};
};
if (isNil {_options select 5}) then {_options set [5, missionNamespace getVariable ["Waldo_Persistence_DefaultCustomVariables", []]]};

private _registry = missionNamespace getVariable ["Waldo_Persistence_ObjectRegistry", []];
private _existing = _registry findIf {(_x select 1) == _safeKey};
private _entry = [_object, _safeKey, _options];
if (_existing >= 0) then {
    _registry set [_existing, _entry];
} else {
    _registry pushBack _entry;
};
missionNamespace setVariable ["Waldo_Persistence_ObjectRegistry", _registry];
_object setVariable ["Waldo_Persistence_Key", _safeKey, true];

[_object, _safeKey, _options] call Waldo_fnc_PersistenceLoadObject;
true
