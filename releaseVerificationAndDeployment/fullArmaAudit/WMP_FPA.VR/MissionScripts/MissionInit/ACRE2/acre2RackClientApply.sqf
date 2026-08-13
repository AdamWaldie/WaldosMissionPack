/*
 * Author: WaldoTheWarfighter
 * Applies and verifies one server-validated ACRE vehicle-rack plan on the selected ACRE-ready
 * interface client. ACRE 2.14 keeps rack radio-data objects client-local even though the vehicle's
 * rack ID list is public, so channel inspection and writes must occur here. Server-only hardware
 * API calls are relayed through Waldo_fnc_ACRE2RackHardwareServer and then verified locally. This
 * client worker is necessary because ACRE 2.14's public getMountedRackRadio/getRadioChannel APIs
 * can resolve the unique rack/radio data on ACRE interface clients but report those same valid IDs
 * as nonexistent on a dedicated server.
 * Locality/authority: interface client selected by Waldo_fnc_ACRE2RackApply. Only the server may
 * invoke it. It does not change carried radios, PTT defaults, persistence, or later player choices.
 * Repeat/JIP behaviour: one token identifies the active request; stale calls are rejected. ACRE owns
 * rack/radio synchronization and JIP after this one initial setup.
 *
 * Arguments:
 * 0: rack vehicle/object <OBJECT>
 * 1: validated settings <HASHMAP>
 * 2: request token <STRING>
 * Return Value: BOOL - true when the client worker was accepted.
 * Current caller: Waldo_fnc_ACRE2RackApply (server).
 * Example: [_vehicle, _settings, _token] remoteExecCall ["Waldo_fnc_ACRE2RackClientApply", owner _player];
 */
params [
    ["_vehicle", objNull, [objNull]],
    ["_config", createHashMap, [createHashMap]],
    ["_token", "", [""]]
];
if (!hasInterface || {remoteExecutedOwner != 2} || {isNull _vehicle}) exitWith {false};

[_vehicle, _config, _token] spawn {
    params ["_vehicle", "_config", "_token"];
    private _profileName = _vehicle getVariable ["Waldo_ACRE2_RackProfile", "INLINE"];
    private _send = {
        params ["_success", "_applied", "_requested", "_problems", "_inventory", "_jobs"];
        private _snapshot = [if (_success) then {"COMPLETE"} else {"FAILED"}, _profileName, clientOwner, _inventory, _jobs, _problems];
        [_vehicle, _token, [_success, _applied, _requested, _problems, _snapshot]] remoteExecCall ["Waldo_fnc_ACRE2RackClientResultServer", 2];
    };
    private _rackBaseClass = {
        params ["_rackId"];
        private _source = getText (configFile >> "CfgVehicles" >> _rackId >> "acre_baseClass");
        if (_source == "") then {_rackId} else {_source}
    };
    private _readState = {
        params ["_rackId"];
        // Do not wrap an assignment in `isNil { ... }`: SQF assignment statements return no
        // value, so that pattern reports nil even when the called ACRE function returned valid
        // rack data. Capture each API result first, then test whether that local variable exists.
        private _id = [_rackId, false] call acre_api_fnc_getMountedRackRadio;
        if (isNil "_id") exitWith {nil};
        private _base = [_rackId, true] call acre_api_fnc_getMountedRackRadio;
        if (isNil "_base") exitWith {nil};
        private _removable = [_rackId] call acre_api_fnc_isRackRadioRemovable;
        if (isNil "_removable") exitWith {nil};
        [_id, _base, _removable]
    };
    private _waitForState = {
        params ["_rackId", "_condition", ["_timeout", 30]];
        private _deadline = diag_tickTime + _timeout;
        private _state = nil;
        waitUntil {
            uiSleep 0.25;
            private _candidate = [_rackId] call _readState;
            if !(isNil "_candidate") then {if ([_candidate] call _condition) then {_state = _candidate}};
            !(isNil "_state") || {diag_tickTime >= _deadline}
        };
        if (isNil "_state") then {nil} else {_state}
    };
    private _racks = [_vehicle] call acre_api_fnc_getVehicleRacks;
    private _rackDeadline = diag_tickTime + 60;
    private _unreadable = [];
    waitUntil {
        uiSleep 0.25;
        _racks = [_vehicle] call acre_api_fnc_getVehicleRacks;
        _unreadable = _racks select {isNil {[_x] call _readState}};
        (!(_racks isEqualTo []) && {_unreadable isEqualTo []}) || {diag_tickTime >= _rackDeadline}
    };
    if (_racks isEqualTo [] || {!(_unreadable isEqualTo [])}) exitWith {
        [false, 0, count (_config getOrDefault ["assignments", []]),
            if (_racks isEqualTo []) then {["NO_CLIENT_RACKS"]} else {_unreadable apply {format ["%1:CLIENT_DATA_NOT_READY", _x]}}, [], []] call _send
    };
    private _inventory = [];
    {
        private _state = [_x] call _readState;
        _inventory pushBack [_x, [_x] call _rackBaseClass, _state param [0, ""], _state param [1, ""], _state param [2, false]];
    } forEach _racks;

    private _profiles = [] call Waldo_fnc_ACRE2GetRadioProfiles;
    private _profileFor = {
        params ["_base"];
        private _index = _profiles findIf {toUpperANSI (_x select 0) == toUpperANSI _base};
        if (_index < 0) then {[]} else {_profiles select _index}
    };
    private _normaliseSide = {
        params ["_value"];
        switch (toUpperANSI _value) do {
            case "BLUFOR"; case "WEST": {"WEST"}; case "OPFOR"; case "EAST": {"EAST"};
            case "INDEPENDENT"; case "INDEP"; case "GUER": {"GUER"}; case "CIVILIAN"; case "CIV": {"CIV"};
            default {toUpperANSI _value};
        }
    };
    private _acreConfig = missionNamespace getVariable ["Waldo_ACRE2_Config", call compile preprocessFileLineNumbers "MissionConfig\acreConfig.sqf"];
    private _configuredSide = [_config getOrDefault ["netSide", "AUTO"]] call _normaliseSide;
    if (_configuredSide == "AUTO") then {
        private _configSide = getNumber (configOf _vehicle >> "side");
        _configuredSide = [["EAST", "WEST", "GUER", "CIV"] param [_configSide, ""]] call _normaliseSide;
    };
    private _resolveNamedNet = {
        params ["_netKey", "_radioProfile"];
        private _wantedKey = toUpperANSI _netKey;
        private _wantedFamily = toUpperANSI (_radioProfile select 5);
        private _matches = [];
        {
            _x params ["_sideKey", "_unusedPreset", "_nets"];
            private _normalSide = [_sideKey] call _normaliseSide;
            if (_configuredSide == "" || {_configuredSide == _normalSide}) then {
                {if (toUpperANSI (_x param [0, ""]) == _wantedKey && {toUpperANSI (_x param [2, ""]) == _wantedFamily}) then {_matches pushBack [_normalSide, _x select 3]}} forEach _nets;
            };
        } forEach (_acreConfig getOrDefault ["sides", []]);
        if (count _matches == 1) then {_matches select 0} else {[]}
    };
    private _compatibleRadio = {
        params ["_rackClass", "_radioClass"];
        private _known = createHashMapFromArray [["ACRE_VRC64", "ACRE_PRC77"], ["ACRE_VRC103", "ACRE_PRC117F"], ["ACRE_VRC110", "ACRE_PRC152"], ["ACRE_VRC111", "ACRE_PRC148"], ["ACRE_SEM90", "ACRE_SEM70"]];
        (_known getOrDefault [toUpperANSI _rackClass, ""]) == toUpperANSI _radioClass
    };
    private _applyOne = {
        params ["_rackId", "_target", "_mountClass", "_skipEmpty"];
        private _current = [_rackId] call _readState;
        if (isNil "_current") exitWith {[false, "STATE_NOT_READY"]};
        _current params ["_currentId", "_currentBase", "_removable"];
        if (toUpperANSI _mountClass == "REMOVE_RACK") exitWith {
            if (!_removable) then {[false, "RACK_NOT_REMOVABLE"]} else {
                [_vehicle, _token, _rackId, "REMOVE_RACK", ""] remoteExecCall ["Waldo_fnc_ACRE2RackHardwareServer", 2];
                private _deadline = diag_tickTime + 30;
                waitUntil {uiSleep 0.25; !(_rackId in ([_vehicle] call acre_api_fnc_getVehicleRacks)) || {diag_tickTime >= _deadline}};
                private _gone = !(_rackId in ([_vehicle] call acre_api_fnc_getVehicleRacks));
                [_gone, if (_gone) then {"REMOVED"} else {"REMOVE_TIMEOUT"}]
            }
        };
        if (toUpperANSI _mountClass == "UNMOUNT_RADIO") exitWith {
            if (!_removable) then {[false, "RADIO_NOT_REMOVABLE"]} else {if (_currentId == "") then {[true, "ALREADY_EMPTY", false]} else {
                [_vehicle, _token, _rackId, "UNMOUNT_RADIO", _currentId] remoteExecCall ["Waldo_fnc_ACRE2RackHardwareServer", 2];
                private _empty = [_rackId, {(_this select 0) == ""}, 30] call _waitForState;
                [!(isNil "_empty"), if (isNil "_empty") then {"UNMOUNT_TIMEOUT"} else {"RADIO_UNMOUNTED"}]
            }}
        };
        if (_mountClass != "" && {toUpperANSI _mountClass != toUpperANSI _currentBase}) then {
            private _rackClass = [_rackId] call _rackBaseClass;
            if !([_rackClass, _mountClass] call _compatibleRadio) exitWith {_current = [false, "INCOMPATIBLE_RADIO"]};
            if (!_removable) exitWith {_current = [false, "RADIO_NOT_REMOVABLE"]};
            if (_currentId != "") then {
                [_vehicle, _token, _rackId, "UNMOUNT_RADIO", _currentId] remoteExecCall ["Waldo_fnc_ACRE2RackHardwareServer", 2];
                private _empty = [_rackId, {(_this select 0) == ""}, 30] call _waitForState;
                if (isNil "_empty") exitWith {_current = [false, "UNMOUNT_TIMEOUT"]};
            };
            if !(_current isEqualType [] && {count _current == 2} && {(_current select 0) isEqualType false}) then {
                [_vehicle, _token, _rackId, "MOUNT_RADIO", _mountClass] remoteExecCall ["Waldo_fnc_ACRE2RackHardwareServer", 2];
                private _mounted = [_rackId, {(_this select 0) != "" && {toUpperANSI (_this select 1) == toUpperANSI _mountClass}}, 45] call _waitForState;
                _current = if (isNil "_mounted") then {[false, "MOUNT_TIMEOUT"]} else {_mounted};
            };
        };
        if (_current isEqualType [] && {count _current == 2} && {(_current select 0) isEqualType false}) exitWith {_current};
        _current params ["_currentId", "_currentBase"];
        if (_target isEqualType 0 && {_target < 0}) exitWith {[true, "UNCHANGED", false]};
        if (_currentId == "") exitWith {if (_skipEmpty && {_mountClass == ""}) then {[true, "EMPTY_SKIPPED", false]} else {[false, "NO_MOUNTED_RADIO", false]}};
        private _profile = [_currentBase] call _profileFor;
        if (_profile isEqualTo []) exitWith {[false, format ["UNSUPPORTED_RADIO_%1", _currentBase]]};
        private _setting = _target;
        if (_target isEqualType "") then {
            private _resolved = [_target, _profile] call _resolveNamedNet;
            _setting = if (_resolved isEqualTo []) then {[false, "NET_NOT_UNIQUE_OR_INCOMPATIBLE"]} else {_resolved select 1};
        };
        if (_setting isEqualType [] && {count _setting == 2} && {(_setting select 0) isEqualType false}) exitWith {_setting};
        private _mode = toUpperANSI (_profile select 1);
        if (_mode == "FREQUENCY") exitWith {[false, "FREQUENCY_REQUIRES_PRESET"]};
        private _channel = if (_mode == "BLOCK_CHANNEL" && {_setting isEqualType []}) then {(((_setting select 0) - 1) * 16) + (_setting select 1)} else {_setting};
        if !(_channel isEqualType 0 && {_channel >= 1} && {_channel <= (_profile select 3)}) exitWith {[false, "CHANNEL_OUT_OF_RANGE"]};
        private _written = [_currentId, _channel] call acre_api_fnc_setRadioChannel;
        private _readBack = -1; private _deadline = diag_tickTime + 5;
        waitUntil {uiSleep 0.1; _readBack = [_currentId] call acre_api_fnc_getRadioChannel; _readBack == _channel || {diag_tickTime >= _deadline}};
        [_written && {_readBack == _channel}, if (_readBack == _channel) then {format ["CHANNEL_%1", _channel]} else {format ["READBACK_%1_EXPECTED_%2", _readBack, _channel]}]
    };

    private _jobs = [];
    {
        _x params ["_selector", ["_setting", -1], ["_mountClass", ""]];
        if (_selector isEqualType "" && {toUpperANSI _selector == "ALL"}) then {{_jobs pushBack [_x, _setting, _mountClass, true]} forEach _racks} else {
            if (_selector isEqualType "") then {
                private _matching = _racks select {toUpperANSI ([_x] call _rackBaseClass) == toUpperANSI _selector};
                {_jobs pushBack [_x, _setting, _mountClass, false]} forEach _matching;
                if (_matching isEqualTo []) then {_jobs pushBack [format ["NO_RACK_CLASS_%1", _selector], _setting, _mountClass, false]};
            } else {if (_selector isEqualType [] && {count _selector == 2}) then {
                _selector params ["_class", "_occurrence"];
                private _matching = _racks select {toUpperANSI ([_x] call _rackBaseClass) == toUpperANSI _class};
                private _job = if (_occurrence >= 1 && {_occurrence <= count _matching}) then {[_matching select (_occurrence - 1), _setting, _mountClass, false]} else {[format ["INVALID_%1_OCCURRENCE_%2", _class, _occurrence], _setting, _mountClass, false]};
                _jobs pushBack _job;
            } else {
                private _job = if (_selector isEqualType 0 && {_selector >= 1} && {_selector <= count _racks}) then {[_racks select (_selector - 1), _setting, _mountClass, false]} else {[format ["INVALID_INDEX_%1", _selector], _setting, _mountClass, false]};
                _jobs pushBack _job;
            }};
        };
    } forEach (_config getOrDefault ["assignments", []]);
    private _applied = 0; private _problems = []; private _jobDiagnostics = [];
    {
        _x params ["_rackId", "_setting", "_mountClass", "_skipEmpty"];
        if (_rackId find "INVALID_" == 0 || {_rackId find "NO_RACK_CLASS_" == 0}) then {
            _problems pushBack _rackId; _jobDiagnostics pushBack [_rackId, _setting, _mountClass, false, _rackId, [], -1];
        } else {
            private _result = [_rackId, _setting, _mountClass, _skipEmpty] call _applyOne;
            if (_result select 0) then {if (_result param [2, true]) then {_applied = _applied + 1}} else {_problems pushBack format ["%1:%2", _rackId, _result select 1]};
            private _after = [_rackId] call _readState; if (isNil "_after") then {_after = []};
            private _radio = _after param [0, ""];
            _jobDiagnostics pushBack [_rackId, _setting, _mountClass, _result select 0, _result select 1, _after, if (_radio == "") then {-1} else {[_radio] call acre_api_fnc_getRadioChannel}];
        };
    } forEach _jobs;
    [_problems isEqualTo [], _applied, count _jobs, _problems, _inventory, _jobDiagnostics] call _send;
};
true
