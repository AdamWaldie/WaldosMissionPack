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
 * CALLING CONTRACT - this is stricter than most WMP "no isServer wrapper needed" functions and is
 * easy to get wrong: unlike Waldo_fnc_Jammer/Waldo_fnc_HazardRegisterPresetZone, which self-forward
 * to the server with remoteExecCall when called on a client, this one does NOT forward itself - a
 * client remoteExecCall lands here with remoteExecutedOwner > 0 and is rejected outright (see the
 * guard right after the isServer check). It must be reached one of these ways:
 *   - An object's own Eden init field. This is what "no isServer wrapper needed" actually means here:
 *     the init field runs identically on every machine, and only the server's own execution of that
 *     line does anything - it is NOT an instruction that a client may remoteExec this safely.
 *   - Direct `call`/`spawn` from code already running on the server (initServer.sqf, a server-only
 *     script, or another server-side function) - e.g. Waldo_fnc_PersistenceInit's own replay of
 *     queued registrations, or the "Persistence - Register Object" ZEN module's server-side handler
 *     (Waldo_fnc_FeatureRuntimeApply), which itself is what a curator's client actually remoteExecs;
 *     that function spawns this one locally on the server, never remoteExec-ing this function itself.
 * A new mission-specific entry point that wants curator/client-triggered registration must add its
 * own authenticated server-side bridge (matching the ZEN module's pattern above) rather than
 * remoteExecCall-ing this function directly.
 *
 * Arguments:
 * 0: object <OBJECT> - object to persist
 * 1: key <STRING> - stable database key, unique within the mission. Registering the same key again
 *    (e.g. re-running an init field, or the ZEN module used twice near the same object) replaces the
 *    previous entry for that key rather than creating a duplicate - safe to call more than once.
 * 2: options <ARRAY> - [save cargo, save damage, save fuel, save ammo/pylons, save position,
 *      custom variable names]. Missing first-five values default true; missing custom variables use
 *      Waldo_Persistence_DefaultCustomVariables. Keys permit letters, digits, underscore and dash -
 *      anything else is rejected (logged, not silently truncated) rather than saved under a mangled
 *      key. The 6th element (custom variable names) is an ARRAY of extra serialisable
 *      missionNamespace-safe variable names to save/restore alongside the five built-in fields - see
 *      Optional-Feature-Extensions.md for the shape those values must take.
 *
 * Return Value:
 * Boolean - true when registered or successfully queued; false when the feature is off, the object/
 * key are invalid, or this was reached the wrong way (see CALLING CONTRACT above).
 *
 * Example:
 * // From an object's own init field in Eden - no isServer wrapper needed:
 * [this, "base_supply_1", [true, false, false, false, false]] call Waldo_fnc_PersistenceRegisterObject;
 *
 * Current callers: mission-maker server setup, the Persistence Object Example composition, the
 * "Persistence - Register Object" ZEN module (via Waldo_fnc_FeatureRuntimeApply, server-side) and the
 * audit mission.
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
