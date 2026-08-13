/*
 * Author: WaldoTheWarfighter
 * Server worker that initialises and configures one object's ACRE2 radio racks after ACRE has
 * synchronized their unique rack/radio data. ACRE creates rack IDs and holds their radio-data on a
 * selected human client. WMP leases the exact ACRE-ready client that ACRE's dedicated-server APIs
 * target, while the server retains validation, request state, retry and completion authority.
 *
 * Locality/repeat/JIP:
 * Server-only and spawned. ACRE's documented rack creation, mount, unmount and removal APIs remain
 * server calls. Channel state is changed and read back on the leased ACRE client. Every wait is
 * bounded. Waldo_fnc_ACRE2RackSetup owns repeat suppression, queued replacement
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
        private _finalState = if (_state != "COMPLETE") then {_state} else {if (_success) then {"COMPLETE"} else {"FAILED"}};
        _vehicle setVariable ["Waldo_ACRE2_RackSetupRunning", false, true];
        _vehicle setVariable ["Waldo_ACRE2_RackRunningSignature", ""];
        _vehicle setVariable ["Waldo_ACRE2_RackSetupComplete", _success, true];
        _vehicle setVariable ["Waldo_ACRE2_RackSetupResult", [_applied, _requested, _problems], true];
        _vehicle setVariable ["Waldo_ACRE2_RackSetupState", _finalState, true];
        private _snapshot = _vehicle getVariable ["Waldo_ACRE2_RackDiagnosticSnapshot", []];
        if (count _snapshot >= 6) then {
            _snapshot set [0, _finalState];
            _snapshot set [2, owner _vehicle];
            _snapshot set [5, _problems];
            _vehicle setVariable ["Waldo_ACRE2_RackDiagnosticSnapshot", _snapshot, true];
        };
        if (_success) then {_vehicle setVariable ["Waldo_ACRE2_RackAppliedSignature", _signature]};
        diag_log format ["[WMP ACRE RACK] vehicle=%1 state=%2 applied=%3/%4 problems=%5", _vehicle, _finalState, _applied, _requested, _problems];

        if (_vehicle getVariable ["Waldo_ACRE2_RackQueued", false]) then {
            _vehicle setVariable ["Waldo_ACRE2_RackQueued", false];
            [_vehicle, _vehicle getVariable ["Waldo_ACRE2_RackDesiredConfig", []], [], true, _vehicle getVariable ["Waldo_ACRE2_RackDesiredProfile", "INLINE"]] call Waldo_fnc_ACRE2RackSetup;
        };
    };
    _success
};

if (!isServer) exitWith {[false, 0, 0, ["NOT_SERVER"]] call _finish};
if (isNull _vehicle) exitWith {[false, 0, 0, ["NULL_VEHICLE"]] call _finish};

// ACRE's server rack API delegates unique rack creation to a human client. Wait for WMP's explicit
// client handshake, which is published only after acre_api_fnc_isInitialized succeeds. This avoids
// the dedicated-server race where a player object exists tens of seconds before that client can
// process acre_sys_rack_initVehicleRacks. Reuse the mission's documented ACRE readiness window.
private _acreConfig = missionNamespace getVariable ["Waldo_ACRE2_Config", call compile preprocessFileLineNumbers "MissionConfig\acreConfig.sqf"];
private _readinessTimeout = _acreConfig getOrDefault ["readinessTimeoutSeconds", 120];
private _normaliseSide = {
    params ["_value"];
    switch (toUpper _value) do {
        case "BLUFOR"; case "WEST": {"WEST"}; case "OPFOR"; case "EAST": {"EAST"};
        case "INDEPENDENT"; case "INDEP"; case "GUER": {"GUER"}; case "CIVILIAN"; case "CIV": {"CIV"};
        default {toUpper _value};
    }
};
private _configuredSide = [_config getOrDefault ["netSide", "AUTO"]] call _normaliseSide;
if (_configuredSide == "AUTO") then {
    private _configSide = getNumber (configOf _vehicle >> "side");
    private _inferredSide = ["EAST", "WEST", "GUER", "CIV"] param [_configSide, ""];
    _configuredSide = [_inferredSide] call _normaliseSide;
};
private _readyPlayers = [];
private _readyDeadline = diag_tickTime + _readinessTimeout;
waitUntil {
    sleep 0.25;
    // ACRE's mount/unmount/remove server APIs always target the first non-headless allPlayers
    // entry. Lease that exact client so later hardware work cannot silently land elsewhere.
    private _humans = allPlayers - (entities "HeadlessClient_F");
    _readyPlayers = if (_humans isEqualTo []) then {[]} else {
        private _candidate = _humans select 0;
        if (!isNull _candidate && {_candidate getVariable ["Waldo_ACRE2_ClientReady", false]}) then {[_candidate]} else {[]}
    };
    !(_readyPlayers isEqualTo []) || {diag_tickTime >= _readyDeadline} || {isNull _vehicle}
};
if (isNull _vehicle) exitWith {[false, 0, 0, ["NULL_VEHICLE"]] call _finish};
if (_readyPlayers isEqualTo []) exitWith {
    [false, 0, count (_config getOrDefault ["assignments", []]), [format ["NO_ACRE_READY_CLIENT_WITHIN_%1_SECONDS", _readinessTimeout]], "WAITING_FOR_ACRE_CLIENT"] call _finish
};

private _preset = _config getOrDefault ["preset", ""];
if (_preset == "" && {_configuredSide != ""}) then {
    private _sideEntry = (_acreConfig getOrDefault ["sides", []]) select {
        [(_x param [0, ""])] call _normaliseSide == _configuredSide
    };
    if !(_sideEntry isEqualTo []) then {_preset = (_sideEntry select 0) param [1, ""]};
};
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
    // A non-empty condition forces ACRE to select a client which completed the handshake, even when
    // a vehicle preset is configured. Without it ACRE selects the first CBA player unconditionally.
    [_vehicle, {(_this select 0) getVariable ["Waldo_ACRE2_ClientReady", false]}] call acre_api_fnc_initVehicleRacks;
};
private _initDeadline = diag_tickTime + _readinessTimeout;
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
    private _shortName = _rackSettings getOrDefault ["shortName", "RDO"];
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
                private _accepted = [
                    _vehicle,
                    _definition,
                    false,
                    {(_this select 0) getVariable ["Waldo_ACRE2_ClientReady", false]}
                ] call acre_api_fnc_addRackToVehicle;
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

// ACRE 2.14 publishes the rack ID list on the vehicle, but the radio-data objects behind those IDs
// remain local to ACRE clients. Its server read APIs consequently report valid rack IDs as
// nonexistent. Delegate state inspection, channel writes and read-back to the same proven client
// that initialized the racks; the server retains the validated request and completion authority.
private _client = _readyPlayers select 0;
private _clientToken = format ["%1:%2:%3", netId _vehicle, diag_tickTime, floor random 1000000];
_vehicle setVariable ["Waldo_ACRE2_RackClientToken", _clientToken];
_vehicle setVariable ["Waldo_ACRE2_RackClientOwner", owner _client];
_vehicle setVariable ["Waldo_ACRE2_RackClientResult", nil];
[_vehicle, _config, _clientToken] remoteExecCall ["Waldo_fnc_ACRE2RackClientApply", owner _client];
private _clientDeadline = diag_tickTime + _readinessTimeout;
waitUntil {
    sleep 0.25;
    !isNil {_vehicle getVariable "Waldo_ACRE2_RackClientResult"}
        || {diag_tickTime >= _clientDeadline}
        || {isNull _vehicle}
        || {isNull _client}
        || {owner _client != (_vehicle getVariable ["Waldo_ACRE2_RackClientOwner", -1])}
};
if (isNull _vehicle) exitWith {[false, 0, 0, ["NULL_VEHICLE"]] call _finish};
private _clientResult = _vehicle getVariable ["Waldo_ACRE2_RackClientResult", []];
_vehicle setVariable ["Waldo_ACRE2_RackClientToken", nil];
_vehicle setVariable ["Waldo_ACRE2_RackClientOwner", nil];
_vehicle setVariable ["Waldo_ACRE2_RackClientResult", nil];
if (_clientResult isEqualTo []) exitWith {
    [false, 0, count (_config getOrDefault ["assignments", []]),
        [if (isNull _client) then {"CLIENT_DISCONNECTED"} else {"CLIENT_APPLY_TIMEOUT"}], "WAITING_FOR_ACRE_CLIENT"] call _finish
};
_clientResult params ["_clientSuccess", "_clientApplied", "_clientRequested", "_clientProblems", "_clientSnapshot"];
_vehicle setVariable ["Waldo_ACRE2_RackDiagnosticSnapshot", _clientSnapshot, true];
[_clientSuccess, _clientApplied, _clientRequested, _clientProblems] call _finish;
_clientSuccess
