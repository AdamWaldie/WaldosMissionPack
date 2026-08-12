/*
 * Author: WaldoTheWarfighter
 * Registers the desired ACRE2 rack-radio setup for one vehicle or object. Mission makers may call
 * this directly from an Eden object Init field; it forwards to the server automatically, so an
 * `isServer` wrapper is neither required nor recommended.
 *
 * The server stores the newest request, validates it, and starts Waldo_fnc_ACRE2RackApply. If no
 * ACRE-ready human player exists yet (normal while a dedicated server is waiting in its lobby), the
 * request remains pending and is retried automatically after a player joins. A different request
 * made while setup is already running replaces the queued request and runs next. Repeated copies
 * of the same Eden Init request are ignored while that request is already running. An identical
 * completed request is repeat-safe. ACRE2 owns the resulting rack/radio state and supplies it to JIP
 * clients; WMP does not continually retune the rack after successful initial setup.
 *
 * Configuration sources may be mixed. Pass a profile name from MissionConfig\acreConfig.sqf and
 * optional inline [key,value] overrides, or pass inline settings alone. Inline keys replace the
 * same top-level key from the profile; arrays are not invisibly merged.
 *
 * Arguments:
 * 0: Vehicle or object <OBJECT> - the object whose ACRE2 racks are configured.
 * 1: Profile name, settings HashMap, or [key,value] rows <STRING|HASHMAP|ARRAY> (default [])
 *    A string selects one named `rackProfiles` entry from MissionConfig\acreConfig.sqf.
 *    `preset` <STRING> (default "") - advanced: an existing ACRE2 radio preset applied before the
 *      racks initialise. This is the supported way to pre-program a PRC-77/SEM70 rack frequency.
 *    `netSide` <STRING> (default "AUTO") - WEST/EAST/GUER/CIV chooses which central named nets are
 *      available. AUTO uses the vehicle classname's configured side, then a unique matching net.
 *    `addRacks` <ARRAY> (default []) - named rack definitions. Each definition is
 *      [rack class, settings], where settings contain count, displayName, shortName, removable,
 *      access, disabled, mountedRadio, components and intercoms. `count` is the desired total of
 *      that rack class on the object, making retries safe rather than adding duplicates.
 *    `assignments` <ARRAY> (default []) - rows shaped as:
 *      [rack selector, target, optional mounted radio classname]
 *      Selector is "ALL", a zero-based rack number, a rack base classname, or
 *      [rack base classname, occurrence starting at 1].
 *      Target is a named net from this acreConfig, a direct channel, or -1 to leave unchanged.
 *      Optional radio classname replaces the current removable radio. "UNMOUNT_RADIO" empties the
 *      rack and "REMOVE_RACK" removes the whole removable rack. Fixed racks are never forced.
 * 2: Inline overrides <HASHMAP or ARRAY> (default []) - used only with a named profile. For the
 *    older inline-only call shape this may be the Force Boolean.
 * 3: Force <BOOL> (default false) - run again even when the same request already completed.
 *
 * Return Value:
 * BOOL - true when the request was accepted or forwarded; false when its basic shape was invalid.
 *
 * Current callers:
 * Eden init fields and the ACRE rack example compositions.
 *
 * Examples:
 * // Beginner default: reuse WEST's named COY net for compatible mounted rack radios.
 * [this, [["netSide", "WEST"], ["assignments", [["ALL", "COY"]]]]] call Waldo_fnc_ACRE2RackSetup;
 *
 * // Recommended central profile, with one optional inline override.
 * [this, "COMMAND_VEHICLE", [["assignments", [[["ACRE_VRC110", 1], "AIRGND", "ACRE_PRC152"]]]]] call Waldo_fnc_ACRE2RackSetup;
 */
params [
    ["_vehicle", objNull, [objNull]],
    ["_profileOrSettings", [], ["", [], createHashMap]],
    ["_overridesOrForce", [], [[], createHashMap, true]],
    ["_force", false, [true]]
];

if (isNull _vehicle) exitWith {
    diag_log "[WMP ACRE RACK] Rejected setup: vehicle/object is null.";
    false
};

if (_overridesOrForce isEqualType true) then {
    _force = _overridesOrForce;
    _overridesOrForce = [];
};
private _toPairs = {
    params ["_value"];
    if (_value isEqualType createHashMap) then {
        private _converted = [];
        {_converted pushBack [_x, _value get _x]} forEach keys _value;
        _converted
    } else {
        if (_value isEqualType [] && {count _value == 2} && {(_value select 0) isEqualType ""}) then {[_value]} else {_value}
    }
};
private _pairs = [];
private _profileProblem = "";
if (_profileOrSettings isEqualType "") then {
    private _acreConfig = missionNamespace getVariable ["Waldo_ACRE2_Config", call compile preprocessFileLineNumbers "MissionConfig\acreConfig.sqf"];
    private _profileName = toUpper _profileOrSettings;
    private _profileIndex = (_acreConfig getOrDefault ["rackProfiles", []]) findIf {toUpper (_x param [0, ""]) == _profileName};
    if (_profileIndex < 0) then {
        _profileProblem = format ["central rack profile '%1' does not exist", _profileOrSettings];
    } else {
        _pairs = [((_acreConfig get "rackProfiles") select _profileIndex) param [1, []]] call _toPairs;
        {
            private _key = _x select 0;
            private _existing = _pairs findIf {toUpper (_x select 0) == toUpper _key};
            if (_existing < 0) then {_pairs pushBack _x} else {_pairs set [_existing, _x]};
        } forEach ([_overridesOrForce] call _toPairs);
    };
} else {
    _pairs = [_profileOrSettings] call _toPairs;
};
if (_profileProblem != "") exitWith {
    diag_log format ["[WMP ACRE RACK] Rejected setup for %1: %2.", _vehicle, _profileProblem];
    false
};
if (_pairs isEqualType createHashMap) then {
    private _converted = [];
    {_converted pushBack [_x, _pairs get _x]} forEach keys _pairs;
    _pairs = _converted;
};
if !(_pairs isEqualType [] && {{_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""}} count _pairs == count _pairs}) exitWith {
    diag_log format ["[WMP ACRE RACK] Rejected setup for %1: settings must be [key, value] rows.", _vehicle];
    false
};

if (!isServer) exitWith {
    [_vehicle, _pairs, _force] remoteExecCall ["Waldo_fnc_ACRE2RackSetup", 2];
    true
};
if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {
    diag_log format ["[WMP ACRE RACK] ACRE2 is absent; setup skipped for %1.", _vehicle];
    false
};

private _settings = createHashMapFromArray _pairs;
private _assignments = _settings getOrDefault ["assignments", []];
private _addRacks = _settings getOrDefault ["addRacks", []];
if !(_assignments isEqualType []) exitWith {
    diag_log format ["[WMP ACRE RACK] Rejected setup for %1: assignments must be an array.", _vehicle];
    false
};
if !(_addRacks isEqualType []) exitWith {
    diag_log format ["[WMP ACRE RACK] Rejected setup for %1: addRacks must be an array.", _vehicle];
    false
};
private _badRow = _assignments findIf {
    !(_x isEqualType []) || {count _x < 1} || {count _x > 3}
    || {!((_x select 0) isEqualType 0 || {(_x select 0) isEqualType ""} || {
        (_x select 0) isEqualType [] && {count (_x select 0) == 2} && {
            ((_x select 0) select 0) isEqualType "" && {((_x select 0) select 1) isEqualType 0}
        }
    })}
};
if (_badRow >= 0) exitWith {
    diag_log format ["[WMP ACRE RACK] Rejected setup for %1: assignment row %2 is malformed.", _vehicle, _badRow + 1];
    false
};
private _badAddition = _addRacks findIf {
    !(_x isEqualType []) || {count _x != 2} || {!((_x select 0) isEqualType "")} ||
    {!((_x select 1) isEqualType [] || {(_x select 1) isEqualType createHashMap})}
};
if (_badAddition >= 0) exitWith {
    diag_log format ["[WMP ACRE RACK] Rejected setup for %1: addRacks row %2 is malformed.", _vehicle, _badAddition + 1];
    false
};

private _signature = str _pairs;
if (!_force && {!(_vehicle getVariable ["Waldo_ACRE2_RackSetupRunning", false])} && {(_vehicle getVariable ["Waldo_ACRE2_RackAppliedSignature", ""]) == _signature}) exitWith {true};

_vehicle setVariable ["Waldo_ACRE2_RackDesiredConfig", _pairs];
_vehicle setVariable ["Waldo_ACRE2_RackSetupSignature", _signature, true];
private _registry = missionNamespace getVariable ["Waldo_ACRE2_RackVehicles", []];
_registry pushBackUnique _vehicle;
missionNamespace setVariable ["Waldo_ACRE2_RackVehicles", _registry];

// A dedicated server can execute Eden init fields before CBA has a usable player. Retain the
// request and resume it after PlayerConnected instead of timing out and requiring a manual re-call.
if (isNil {missionNamespace getVariable "Waldo_ACRE2_RackPlayerConnectedEH"}) then {
    private _eh = addMissionEventHandler ["PlayerConnected", {
        [] spawn {
            private _deadline = diag_tickTime + 60;
            waitUntil {
                sleep 0.5;
                (!isNil "CBA_fnc_players" && {count ([] call CBA_fnc_players) > 0})
                || {diag_tickTime >= _deadline}
            };
            {
                if (!isNull _x && {!(_x getVariable ["Waldo_ACRE2_RackSetupRunning", false])} && {!(_x getVariable ["Waldo_ACRE2_RackSetupComplete", false])}) then {
                    [_x, _x getVariable ["Waldo_ACRE2_RackDesiredConfig", []], true] call Waldo_fnc_ACRE2RackSetup;
                };
            } forEach (missionNamespace getVariable ["Waldo_ACRE2_RackVehicles", []]);
        };
    }];
    missionNamespace setVariable ["Waldo_ACRE2_RackPlayerConnectedEH", _eh];
};
if !(missionNamespace getVariable ["Waldo_ACRE2_RackReadinessWatcherRunning", false]) then {
    missionNamespace setVariable ["Waldo_ACRE2_RackReadinessWatcherRunning", true];
    [] spawn {
        private _deadline = diag_tickTime + 300;
        waitUntil {
            sleep 0.5;
            (!isNil "CBA_fnc_players" && {count ([] call CBA_fnc_players) > 0})
            || {diag_tickTime >= _deadline}
        };
        if (!isNil "CBA_fnc_players" && {count ([] call CBA_fnc_players) > 0}) then {
            {
                if (!isNull _x && {!(_x getVariable ["Waldo_ACRE2_RackSetupRunning", false])} && {!(_x getVariable ["Waldo_ACRE2_RackSetupComplete", false])}) then {
                    [_x, _x getVariable ["Waldo_ACRE2_RackDesiredConfig", []], true] call Waldo_fnc_ACRE2RackSetup;
                };
            } forEach (missionNamespace getVariable ["Waldo_ACRE2_RackVehicles", []]);
        };
        missionNamespace setVariable ["Waldo_ACRE2_RackReadinessWatcherRunning", false];
    };
};

if (_vehicle getVariable ["Waldo_ACRE2_RackSetupRunning", false]) exitWith {
    if (!_force && {(_vehicle getVariable ["Waldo_ACRE2_RackRunningSignature", ""]) == _signature}) exitWith {true};
    _vehicle setVariable ["Waldo_ACRE2_RackQueued", true];
    diag_log format ["[WMP ACRE RACK] New setup queued for %1 while its current run finishes.", _vehicle];
    true
};

_vehicle setVariable ["Waldo_ACRE2_RackQueued", false];
_vehicle setVariable ["Waldo_ACRE2_RackSetupRunning", true, true];
_vehicle setVariable ["Waldo_ACRE2_RackRunningSignature", _signature];
_vehicle setVariable ["Waldo_ACRE2_RackSetupComplete", false, true];
_vehicle setVariable ["Waldo_ACRE2_RackSetupResult", [0, 0, ["STARTING"]], true];
[_vehicle, _settings, _signature] spawn Waldo_fnc_ACRE2RackApply;
true
