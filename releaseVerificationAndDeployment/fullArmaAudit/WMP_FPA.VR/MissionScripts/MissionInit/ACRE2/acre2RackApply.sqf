/*
 * Author: WaldoTheWarfighter
 * Server worker that initialises and configures one object's ACRE2 radio racks after ACRE has
 * synchronized their unique rack/radio data. ACRE creates a rack ID on a selected human client,
 * acknowledges it to the server, and propagates its radio-data events to every ACRE machine and JIP
 * clients. WMP therefore waits for the server's synchronized copy instead of racing every client or
 * retaining a client-owner dependency that can become stale.
 *
 * Locality/repeat/JIP:
 * Server-only and spawned. ACRE's documented rack creation, mount, unmount and removal APIs remain
 * server calls. Channel state is changed only after the rack is readable on the server, then read
 * back. Every wait is bounded. Waldo_fnc_ACRE2RackSetup owns repeat suppression, queued replacement
 * and PlayerConnected replay. ACRE owns subsequent state synchronization and JIP delivery; WMP does
 * not continually retune a successfully configured rack.
 *
 * Arguments:
 * 0: Vehicle/object <OBJECT>.
 * 1: Validated settings <HASHMAP>; see Waldo_fnc_ACRE2RackSetup.
 * 2: Request signature <STRING>.
 *
 * Return Value:
 * BOOL - true only when every explicit rack job succeeded. Empty racks reached through an "ALL"
 * selector are deliberately skipped because "ALL" means every already-mounted radio.
 *
 * Current caller: Waldo_fnc_ACRE2RackSetup (server).
 * Example: [_vehicle, _settings, str _settings] spawn Waldo_fnc_ACRE2RackApply;
 */
params [
    ["_vehicle", objNull, [objNull]],
    ["_config", createHashMap, [createHashMap]],
    ["_signature", "", [""]]
];

private _finish = {
    params ["_success", "_applied", "_requested", "_problems", ["_state", "COMPLETE"]];
    if (!isNull _vehicle) then {
        _vehicle setVariable ["Waldo_ACRE2_RackSetupRunning", false, true];
        _vehicle setVariable ["Waldo_ACRE2_RackRunningSignature", ""];
        _vehicle setVariable ["Waldo_ACRE2_RackSetupComplete", _state == "COMPLETE", true];
        _vehicle setVariable ["Waldo_ACRE2_RackSetupResult", [_applied, _requested, _problems], true];
        _vehicle setVariable ["Waldo_ACRE2_RackSetupState", _state, true];
        if (_success) then {_vehicle setVariable ["Waldo_ACRE2_RackAppliedSignature", _signature]};
        diag_log format ["[WMP ACRE RACK] vehicle=%1 state=%2 applied=%3/%4 problems=%5", _vehicle, _state, _applied, _requested, _problems];

        if (_vehicle getVariable ["Waldo_ACRE2_RackQueued", false]) then {
            _vehicle setVariable ["Waldo_ACRE2_RackQueued", false];
            [_vehicle, _vehicle getVariable ["Waldo_ACRE2_RackDesiredConfig", []], true] call Waldo_fnc_ACRE2RackSetup;
        };
    };
    _success
};

if (!isServer) exitWith {[false, 0, 0, ["NOT_SERVER"]] call _finish};
if (isNull _vehicle) exitWith {[false, 0, 0, ["NULL_VEHICLE"]] call _finish};

private _players = if (isNil "CBA_fnc_players") then {[]} else {[] call CBA_fnc_players};
_players = _players select {isPlayer _x && {!isNull _x}};
if (_players isEqualTo []) exitWith {
    [false, 0, count (_config getOrDefault ["assignments", []]), ["WAITING_FOR_ACRE_PLAYER"], "WAITING_FOR_PLAYER"] call _finish
};

private _preset = _config getOrDefault ["preset", ""];
if (_preset != "") then {[_vehicle, _preset] call acre_api_fnc_setVehicleRacksPreset};

private _rackBaseClass = {
    params ["_rackId"];
    private _source = getText (configFile >> "CfgVehicles" >> _rackId >> "acre_baseClass");
    if (_source == "") then {_rackId} else {_source}
};
private _settingsMap = {
    params ["_value"];
    if (_value isEqualType createHashMap) exitWith {_value};
    if (_value isEqualType [] && {count _value == 2} && {(_value select 0) isEqualType ""}) then {_value = [_value]};
    createHashMapFromArray _value
};
private _compatibleRadio = {
    params ["_rackClass", "_radioClass"];
    if (_radioClass == "") exitWith {true};
    private _known = createHashMapFromArray [
        ["ACRE_VRC64", "ACRE_PRC77"],
        ["ACRE_VRC103", "ACRE_PRC117F"],
        ["ACRE_VRC110", "ACRE_PRC152"],
        ["ACRE_VRC111", "ACRE_PRC148"],
        ["ACRE_SEM90", "ACRE_SEM70"]
    ];
    private _expected = _known getOrDefault [toUpper _rackClass, ""];
    _expected != "" && {_expected == toUpper _radioClass}
};

if !([_vehicle] call acre_api_fnc_areVehicleRacksInitialized) then {
    [_vehicle] call acre_api_fnc_initVehicleRacks;
};
private _initDeadline = diag_tickTime + 30;
waitUntil {
    sleep 0.25;
    ([_vehicle] call acre_api_fnc_areVehicleRacksInitialized) || {diag_tickTime >= _initDeadline}
};
if !([_vehicle] call acre_api_fnc_areVehicleRacksInitialized) exitWith {
    [false, 0, count (_config getOrDefault ["assignments", []]), ["RACKS_NOT_INITIALISED"]] call _finish
};

// Additions use a desired total count per rack class. This makes a retry after a timeout safe: WMP
// recounts real ACRE racks and adds only the missing number instead of duplicating earlier successes.
private _additionProblems = [];
{
    _x params ["_rackClass", "_sourceSettings"];
    private _rackSettings = [_sourceSettings] call _settingsMap;
    private _desiredCount = _rackSettings getOrDefault ["count", 1];
    private _displayName = _rackSettings getOrDefault ["displayName", getText (configFile >> "CfgAcreComponents" >> _rackClass >> "name")];
    private _shortName = _rackSettings getOrDefault ["shortName", "RADIO"];
    private _removable = _rackSettings getOrDefault ["removable", true];
    private _access = _rackSettings getOrDefault ["access", ["inside"]];
    private _disabled = _rackSettings getOrDefault ["disabled", []];
    private _mountedRadio = _rackSettings getOrDefault ["mountedRadio", ""];
    private _components = _rackSettings getOrDefault ["components", []];
    private _intercoms = _rackSettings getOrDefault ["intercoms", []];
    private _classValid = isClass (configFile >> "CfgAcreComponents" >> _rackClass);
    if (!_classValid) then {
        _additionProblems pushBack format ["ADD_%1:UNKNOWN_RACK_CLASS", _rackClass];
    } else {
        if !([_rackClass, _mountedRadio] call _compatibleRadio) then {
            _additionProblems pushBack format ["ADD_%1:INCOMPATIBLE_RADIO_%2", _rackClass, _mountedRadio];
        } else {
            private _existing = [_vehicle] call acre_api_fnc_getVehicleRacks;
            private _currentCount = {toUpper _rackClass == toUpper ([_x] call _rackBaseClass)} count _existing;
            private _copy = _currentCount + 1;
            while {_copy <= _desiredCount && {_additionProblems isEqualTo []}} do {
                private _definition = [_rackClass, _displayName, _shortName, _removable, _access, _disabled, _mountedRadio, _components, _intercoms];
                private _accepted = [_vehicle, _definition, false, {}] call acre_api_fnc_addRackToVehicle;
                if (!_accepted) then {
                    _additionProblems pushBack format ["ADD_%1_%2:REQUEST_REJECTED", _rackClass, _copy];
                } else {
                    private _addDeadline = diag_tickTime + 45;
                    waitUntil {
                        sleep 0.25;
                        private _now = [_vehicle] call acre_api_fnc_getVehicleRacks;
                        ({toUpper _rackClass == toUpper ([_x] call _rackBaseClass)} count _now) >= _copy || {diag_tickTime >= _addDeadline}
                    };
                    private _after = [_vehicle] call acre_api_fnc_getVehicleRacks;
                    if (({toUpper _rackClass == toUpper ([_x] call _rackBaseClass)} count _after) < _copy) then {
                        _additionProblems pushBack format ["ADD_%1_%2:TIMEOUT", _rackClass, _copy];
                    };
                };
                _copy = _copy + 1;
            };
        };
    };
} forEach (_config getOrDefault ["addRacks", []]);
if !(_additionProblems isEqualTo []) exitWith {
    [false, 0, count (_config getOrDefault ["assignments", []]), _additionProblems] call _finish
};

private _racks = [_vehicle] call acre_api_fnc_getVehicleRacks;
if (_racks isEqualTo []) exitWith {[false, 0, 0, ["NO_RACKS_ON_OBJECT"]] call _finish};

// The initialized vehicle flag is networked before ACRE's radio-data event is guaranteed to have
// reached the server. Wait until every returned rack ID is actually readable instead of assuming
// those two independent messages arrive in one order.
private _readState = {
    params ["_rackId"];
    private _id = "";
    private _base = "";
    private _removable = false;
    private _idOk = !(isNil {_id = [_rackId, false] call acre_api_fnc_getMountedRackRadio});
    private _baseOk = !(isNil {_base = [_rackId, true] call acre_api_fnc_getMountedRackRadio});
    private _removableOk = !(isNil {_removable = [_rackId] call acre_api_fnc_isRackRadioRemovable});
    if (_idOk && {_baseOk} && {_removableOk}) then {[_id, _base, _removable]} else {nil}
};
private _rackDataDeadline = diag_tickTime + 30;
private _unreadable = [];
waitUntil {
    sleep 0.25;
    _unreadable = _racks select {isNil {[_x] call _readState}};
    _unreadable isEqualTo [] || {diag_tickTime >= _rackDataDeadline}
};
if !(_unreadable isEqualTo []) exitWith {
    [false, 0, count (_config getOrDefault ["assignments", []]), _unreadable apply {format ["%1:RADIO_DATA_NOT_SYNCHRONIZED", _x]}] call _finish
};

private _profiles = [] call Waldo_fnc_ACRE2GetRadioProfiles;
private _profileFor = {
    params ["_base"];
    private _index = _profiles findIf {toUpper (_x select 0) == toUpper _base};
    if (_index < 0) then {[]} else {_profiles select _index}
};
private _normaliseSide = {
    params ["_value"];
    switch (toUpper _value) do {
        case "BLUFOR"; case "WEST": {"WEST"}; case "OPFOR"; case "EAST": {"EAST"};
        case "INDEPENDENT"; case "INDEP"; case "GUER": {"GUER"}; case "CIVILIAN"; case "CIV": {"CIV"};
        default {toUpper _value};
    }
};
private _acreConfig = missionNamespace getVariable ["Waldo_ACRE2_Config", call compile preprocessFileLineNumbers "MissionConfig\acreConfig.sqf"];
private _configuredSide = [_config getOrDefault ["netSide", "AUTO"]] call _normaliseSide;
if (_configuredSide == "AUTO") then {
    private _configSide = getNumber (configOf _vehicle >> "side");
    private _inferredSide = ["EAST", "WEST", "GUER", "CIV"] param [_configSide, ""];
    _configuredSide = [_inferredSide] call _normaliseSide;
};
private _resolveNamedNet = {
    params ["_netKey", "_radioProfile"];
    private _wantedKey = toUpper _netKey;
    private _wantedFamily = toUpper (_radioProfile select 5);
    private _matches = [];
    {
        _x params ["_sideKey", "_unusedPreset", "_nets"];
        private _normalSide = [_sideKey] call _normaliseSide;
        if (_configuredSide == "" || {_configuredSide == _normalSide}) then {
            {
                if (toUpper (_x param [0, ""]) == _wantedKey && {toUpper (_x param [2, ""]) == _wantedFamily}) then {
                    _matches pushBack [_normalSide, _x select 3];
                };
            } forEach _nets;
        };
    } forEach (_acreConfig getOrDefault ["sides", []]);
    if (count _matches == 1) then {_matches select 0} else {[]}
};

private _waitForState = {
    params ["_rackId", "_condition", ["_timeout", 30]];
    private _deadline = diag_tickTime + _timeout;
    private _state = nil;
    waitUntil {
        sleep 0.25;
        private _candidate = [_rackId] call _readState;
        if !(isNil "_candidate") then {
            if ([_candidate] call _condition) then {_state = _candidate};
        };
        !(isNil "_state") || {diag_tickTime >= _deadline}
    };
    if (isNil "_state") then {nil} else {_state}
};

private _applyOne = {
    params ["_rackId", "_target", "_mountClass", "_skipEmpty"];
    private _current = [_rackId] call _readState;
    if (isNil "_current") exitWith {[false, "STATE_NOT_SYNCHRONIZED"]};
    _current params ["_currentId", "_currentBase", "_removable"];

    if (toUpper _mountClass == "REMOVE_RACK") exitWith {
        if (!_removable) then {[false, "RACK_NOT_REMOVABLE"]} else {
            private _removed = [_vehicle, _rackId] call acre_api_fnc_removeRackFromVehicle;
            if (!_removed) then {[false, "REMOVE_REJECTED"]} else {
                private _removeDeadline = diag_tickTime + 30;
                waitUntil {
                    sleep 0.25;
                    !(_rackId in ([_vehicle] call acre_api_fnc_getVehicleRacks)) || {diag_tickTime >= _removeDeadline}
                };
                private _gone = !(_rackId in ([_vehicle] call acre_api_fnc_getVehicleRacks));
                [_gone, if (_gone) then {"REMOVED"} else {"REMOVE_TIMEOUT"}]
            }
        }
    };

    if (toUpper _mountClass == "UNMOUNT_RADIO") exitWith {
        if (!_removable) then {[false, "RADIO_NOT_REMOVABLE"]} else {
            if (_currentId == "") then {[true, "ALREADY_EMPTY", false]} else {
                private _unmounted = [_rackId, _currentId] call acre_api_fnc_unmountRackRadio;
                if (!_unmounted) then {[false, "UNMOUNT_REJECTED"]} else {
                    private _empty = [_rackId, {(_this select 0) == ""}, 30] call _waitForState;
                    if (isNil "_empty") then {[false, "UNMOUNT_TIMEOUT"]} else {[true, "RADIO_UNMOUNTED"]}
                }
            }
        }
    };

    if (_mountClass != "" && {toUpper _mountClass != toUpper _currentBase}) then {
        private _baseRack = [_rackId] call _rackBaseClass;
        if !([_baseRack, _mountClass] call _compatibleRadio) exitWith {_current = [false, format ["INCOMPATIBLE_%1", _baseRack]]};
        if (!_removable) exitWith {_current = [false, "RADIO_NOT_REMOVABLE"]};
        if (_currentId != "") then {
            if !([_rackId, _currentId] call acre_api_fnc_unmountRackRadio) exitWith {_current = [false, "UNMOUNT_REJECTED"]};
            private _empty = [_rackId, {(_this select 0) == ""}, 30] call _waitForState;
            if (isNil "_empty") exitWith {_current = [false, "UNMOUNT_TIMEOUT"]};
        };
        if !([_rackId, _mountClass] call acre_api_fnc_mountRackRadio) exitWith {_current = [false, "MOUNT_REJECTED"]};
        private _mounted = [_rackId, {(_this select 0) != "" && {toUpper (_this select 1) == toUpper _mountClass}}, 45] call _waitForState;
        if (isNil "_mounted") exitWith {_current = [false, "MOUNT_TIMEOUT"]};
        _current = _mounted;
    };
    // The exitWith values inside the replacement block deliberately replace _current with an error.
    if (_current isEqualType [] && {count _current == 2} && {(_current select 0) isEqualType false}) exitWith {_current};
    _current params ["_currentId", "_currentBase"];

    if (_target isEqualType 0 && {_target < 0}) exitWith {[true, "UNCHANGED", false]};
    if (_currentId == "") exitWith {
        if (_skipEmpty && {_mountClass == ""}) then {[true, "EMPTY_SKIPPED", false]} else {[false, "NO_MOUNTED_RADIO", false]}
    };
    private _profile = [_currentBase] call _profileFor;
    if (_profile isEqualTo []) exitWith {[false, format ["UNSUPPORTED_RADIO_%1", _currentBase]]};
    private _mode = toUpper (_profile select 1);
    private _setting = _target;
    if (_target isEqualType "") then {
        private _resolvedNet = [_target, _profile] call _resolveNamedNet;
        if (_resolvedNet isEqualTo []) then {
            _setting = [false, format ["NET_%1_NOT_UNIQUE_OR_INCOMPATIBLE", _target]];
        } else {
            _configuredSide = _resolvedNet select 0;
            _setting = _resolvedNet select 1;
        };
    };
    if (_setting isEqualType [] && {count _setting == 2} && {(_setting select 0) isEqualType false}) exitWith {_setting};
    if (_mode == "FREQUENCY") exitWith {[false, "FREQUENCY_REQUIRES_PRESET"]};

    private _channel = if (_mode == "BLOCK_CHANNEL" && {_setting isEqualType []}) then {
        (((_setting param [0, 1]) - 1) * 16) + (_setting param [1, 1])
    } else {_setting};
    if !(_channel isEqualType 0 && {_channel >= 1} && {_channel <= (_profile select 3)}) exitWith {[false, "CHANNEL_OUT_OF_RANGE"]};
    private _written = [_currentId, _channel] call acre_api_fnc_setRadioChannel;
    private _readBack = [_currentId] call acre_api_fnc_getRadioChannel;
    [_written && {_readBack == _channel}, if (_readBack == _channel) then {format ["CHANNEL_%1", _channel]} else {format ["READBACK_%1_EXPECTED_%2", _readBack, _channel]}]
};

private _assignments = _config getOrDefault ["assignments", []];
private _jobs = [];
{
    _x params ["_selector", ["_setting", -1], ["_mountClass", ""]];
    if (_selector isEqualType "" && {toUpper _selector == "ALL"}) then {
        {_jobs pushBack [_x, _setting, _mountClass, true]} forEach _racks;
    } else {
        if (_selector isEqualType "") then {
            private _matching = _racks select {toUpper ([_x] call _rackBaseClass) == toUpper _selector};
            {_jobs pushBack [_x, _setting, _mountClass, false]} forEach _matching;
            if (_matching isEqualTo []) then {_jobs pushBack [format ["NO_RACK_CLASS_%1", _selector], _setting, _mountClass, false]};
        } else {
        if (_selector isEqualType [] && {count _selector == 2}) then {
            _selector params ["_selectedClass", "_occurrence"];
            private _matching = _racks select {toUpper ([_x] call _rackBaseClass) == toUpper _selectedClass};
            if (_occurrence >= 1 && {_occurrence <= count _matching}) then {
                _jobs pushBack [_matching select (_occurrence - 1), _setting, _mountClass, false];
            } else {
                _jobs pushBack [format ["INVALID_%1_OCCURRENCE_%2", _selectedClass, _occurrence], _setting, _mountClass, false];
            };
        } else {
        if (_selector isEqualType 0 && {_selector >= 0} && {_selector < count _racks}) then {
            _jobs pushBack [_racks select _selector, _setting, _mountClass, false];
        } else {
            _jobs pushBack [format ["INVALID_INDEX_%1", _selector], _setting, _mountClass, false];
        };
        };
        };
    };
} forEach _assignments;

private _applied = 0;
private _problems = [];
{
    _x params ["_rackId", "_setting", "_mountClass", "_skipEmpty"];
    if (_rackId find "INVALID_" == 0 || {_rackId find "NO_RACK_CLASS_" == 0}) then {
        _problems pushBack _rackId;
    } else {
        private _result = [_rackId, _setting, _mountClass, _skipEmpty] call _applyOne;
        if (_result select 0) then {
            if (_result param [2, true]) then {_applied = _applied + 1};
        } else {
            _problems pushBack format ["%1:%2", _rackId, _result select 1];
        };
        diag_log format ["[WMP ACRE RACK] vehicle=%1 rack=%2 setting=%3 mount=%4 success=%5 detail=%6", _vehicle, _rackId, _setting, _mountClass, _result select 0, _result select 1];
    };
} forEach _jobs;

[_problems isEqualTo [], _applied, count _jobs, _problems] call _finish
