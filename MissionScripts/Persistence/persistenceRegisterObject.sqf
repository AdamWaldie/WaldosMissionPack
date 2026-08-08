/*
 * Author: WaldoTheWarfighter
 * Registers an editor-placed or scripted object for repeat-safe server persistence.
 * Server-only work: it silently no-ops (returns false) on every non-server machine, so it is safe to
 * call directly from an object's own Eden init field with no isServer wrapper - exactly like
 * Waldo_fnc_Jammer and Waldo_fnc_HazardRegisterPresetZone, the server's own execution of that same
 * init line is what actually registers it. When persistence is enabled but its dependency/startup
 * gate is still pending, registration is queued by key and replayed after activation. The function
 * does not enable persistence itself and returns false while the feature is off.
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
 * // From an object's own init field in Eden - no isServer wrapper needed:
 * [this, "base_supply_1", [true, false, false, false, false]] call Waldo_fnc_PersistenceRegisterObject;
 *
 * Current callers: mission-maker server setup, the Persistence Object Example composition, the
 * "Persistence - Register Object" ZEN module and the audit mission.
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
