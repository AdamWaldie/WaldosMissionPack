/*
 * Author: WaldoTheWarfighter
 * Applies the current server plan to supported local carried radios. Explicit rows are optional
 * templates, so an absent radio occurrence is skipped rather than treated as a failure. Unlisted,
 * unsupported and captured radios are preserved. Frequency requests use ACRE's asynchronous public
 * setupRadios API and are recorded as accepted but unverified because no public frequency read API
 * exists. PTT, volume, speaker mode and current-radio selection are never changed.
 * Locality and authority: call on the player's interface client after ACRE unique radios exist and
 * the complete server plan has arrived. It changes only that client's carried radios.
 *
 * Arguments:
 * 0: force <BOOL> (default false)
 * 1: reason <STRING> (default MANUAL)
 * 2: allow one retry <BOOL> (internal, default true)
 *
 * Return Value: BOOL - true when all applicable assignments were applied or accepted.
 *
 * Example: [true, "RESPAWN"] call Waldo_fnc_ACRE2ApplyPlayerPlan;
 * Result: applicable carried-radio occurrences receive the authored baseline once for this loadout.
 * Current callers: Waldo_fnc_ACRE2SchedulePlayerRefresh and persistence fallback.
 */
params [["_force", false, [true]], ["_reason", "MANUAL", [""]], ["_retryAllowed", true, [true]]];
if (!hasInterface || {isNull player} || {!(isClass (configFile >> "CfgPatches" >> "acre_main"))}) exitWith {false};
private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
if !(_config getOrDefault ["enabled", true]) exitWith {true};
private _plan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
if (count _plan < 4 || {(_plan select 0) != 3}) exitWith {false};
private _sideKey = switch (side player) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
private _sideIndex = (_plan select 2) findIf {(_x select 0) == _sideKey};
if (_sideIndex < 0) exitWith {false};
private _sidePlan = (_plan select 2) select _sideIndex;
_sidePlan params ["_unusedSide", "_preset", "_nets", "_groups"];
private _groupKey = toUpper groupId group player;
private _groupIndex = _groups findIf {(_x select 0) == _groupKey};
if (_groupIndex < 0) exitWith {
    diag_log format ["[WMP ACRE] No %1 plan for group %2.", _sideKey, _groupKey];
    missionNamespace setVariable ["Waldo_ACRE2_LastApplication", [false, _reason, _sideKey, _groupKey, [], ["No matching group plan."], [], []]];
    false
};
private _generation = missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0];
if ((missionNamespace getVariable ["Waldo_ACRE2_RestoredRadioGeneration", -1]) == _generation) exitWith {true};
private _groupPlan = _groups select _groupIndex;
_groupPlan params ["_unusedGroup", "_netKeys", "_shortAssignment", "_explicitAssignments"];
private _profiles = [_config] call Waldo_fnc_ACRE2GetRadioProfiles;
private _radios = [] call Waldo_fnc_ACRE2GetOrderedRadios;
private _problems = [];
private _applied = [];
private _preserved = [];
private _pendingFrequency = [];
private _success = true;
private _profileFor = {params ["_base"]; private _i = _profiles findIf {toUpper (_x select 0) == toUpper _base}; if (_i < 0) then {[]} else {_profiles select _i}};
private _radiosOfType = {params ["_base"]; _radios select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == toUpper _base}};
private _netFor = {params ["_key"]; private _i = _nets findIf {(_x select 0) == toUpper _key}; if (_i < 0) then {[]} else {_nets select _i}};
private _tuningFor = {
    params ["_net", "_base"];
    private _i = (_net select 2) findIf {toUpper (_x select 0) == toUpper _base};
    if (_i < 0) then {[]} else {(_net select 2) select _i}
};
private _normaliseEar = {params ["_value"]; private _ear = toUpper _value; if (_ear == "BOTH") then {"CENTER"} else {_ear}};
private _defaultEar = {params ["_profile", "_occurrence"]; private _ears = _profile select 2; _ears select (((_occurrence - 1) min ((count _ears) - 1)) max 0)};

// Apply the first matching side-scoped override. MERGE updates assignment identities; REPLACE starts clean.
{
    _x params ["_overrideSide", "_selector", "_mode", "_overrideAssignments"];
    if (toUpper _overrideSide == _sideKey) then {
        _selector params ["_selectorType", "_selectorValue"];
        private _matches = switch (toUpper _selectorType) do {
            case "UID": {getPlayerUID player == _selectorValue};
            case "VARIABLE": {vehicleVarName player == _selectorValue};
            case "ROLE": {toUpper ((roleDescription player splitString "@") param [0, ""]) == toUpper _selectorValue};
            default {false};
        };
        if (_matches) exitWith {
            if (toUpper _mode == "REPLACE") then {_explicitAssignments = []};
            {
                private _identity = format ["%1#%2", toUpper (_x select 0), _x select 1];
                private _existing = _explicitAssignments findIf {format ["%1#%2", toUpper (_x select 0), _x select 1] == _identity};
                if (_existing < 0) then {_explicitAssignments pushBack _x} else {_explicitAssignments set [_existing, _x]};
            } forEach _overrideAssignments;
        };
    };
} forEach (_config getOrDefault ["radioOverrides", []]);
private _signature = format ["%1|%2|%3|%4|%5", _plan select 1, _sideKey, _groupKey, _generation, _explicitAssignments];
if (!_force && {(missionNamespace getVariable ["Waldo_ACRE2_AppliedSignature", ""]) == _signature}) exitWith {true};

private _resolved = [];
private _explicitIdentities = [];
{
    _x params ["_base", "_occurrence", "_target", "_ear"];
    private _matching = [toUpper _base] call _radiosOfType;
    if (count _matching >= _occurrence) then {
        _resolved pushBack [_matching select (_occurrence - 1), toUpper _base, _occurrence, _target, [_ear] call _normaliseEar];
        _explicitIdentities pushBack format ["%1#%2", toUpper _base, _occurrence];
    };
} forEach _explicitAssignments;
private _shortRadios = ["ACRE_PRC343"] call _radiosOfType;
if (count _shortRadios > 0 && {!(_shortAssignment isEqualTo [])} && {!("ACRE_PRC343#1" in _explicitIdentities)}) then {
    private _profile = ["ACRE_PRC343"] call _profileFor;
    _resolved pushBack [_shortRadios select 0, "ACRE_PRC343", 1, _shortAssignment, [_profile, 1] call _defaultEar];
};
// Every supported carried occurrence independently takes the first compatible configured net.
private _typeCounts = createHashMap;
{
    private _radioId = _x;
    private _base = toUpper ([_radioId] call acre_api_fnc_getBaseRadio);
    private _profile = [_base] call _profileFor;
    private _occurrence = (_typeCounts getOrDefault [_base, 0]) + 1;
    _typeCounts set [_base, _occurrence];
    private _identity = format ["%1#%2", _base, _occurrence];
    if (count _profile > 0 && {toUpper (_profile select 1) != "BLOCK_CHANNEL"} && {!(_identity in _explicitIdentities)}) then {
        private _compatibleNets = [];
        {
            private _net = [_x] call _netFor;
            if (count _net > 0 && {count ([_net, _base] call _tuningFor) > 0}) then {_compatibleNets pushBack _net};
        } forEach _netKeys;
        if (count _compatibleNets >= _occurrence) then {
            _resolved pushBack [_radioId, _base, _occurrence, (_compatibleNets select (_occurrence - 1)) select 0, [_profile, _occurrence] call _defaultEar];
        };
    };
} forEach _radios;

private _setupSettings = [];
private _managedIds = [];
{
    _x params ["_radioId", "_base", "_occurrence", "_target", "_ear"];
    private _profile = [_base] call _profileFor;
    private _mode = toUpper (_profile select 1);
    private _setting = _target;
    private _netLabel = "DIRECT";
    private _ready = true;
    if (_target isEqualType "") then {
        private _net = [_target] call _netFor;
        private _tuning = if (count _net > 0) then {[_net, _base] call _tuningFor} else {[]};
        if (count _tuning == 0) then {
            _ready = false; _success = false;
            _problems pushBack format ["%1#%2 net %3 has no compatible tuning.", _base, _occurrence, _target];
        } else {_setting = _tuning select 1; _netLabel = _net select 1};
    };
    if (_ready && {_mode == "BLOCK_CHANNEL"}) then {
        // WMP authors PRC-343 values as [block, channel]. ACRE setupRadios expects
        // [channel, block]; a flattened 1-256 channel is not a valid PRC-343 assignment.
        _setupSettings pushBack [_base, _occurrence, [_setting select 1, _setting select 0]];
    };
    if (_ready && {_mode == "CHANNEL"}) then {
        if !([_radioId, _setting] call acre_api_fnc_setRadioChannel) then {_success = false};
        if (([_radioId] call acre_api_fnc_getRadioChannel) != _setting) then {_success = false; _problems pushBack format ["%1#%2 channel read-back failed.", _base, _occurrence]};
    };
    if (_ready && {_mode == "FREQUENCY"}) then {
        if (_setting isEqualType 0) then {
            private _divisor = (_profile select 4) select 3;
            private _whole = floor _setting;
            _setting = [_whole, round ((_setting - _whole) * _divisor)];
        };
        _setupSettings pushBack [_base, _occurrence, _setting];
        _pendingFrequency pushBack [_radioId, _base, _occurrence, _setting, _netLabel];
    };
    if (_ready) then {
        if !([_radioId, _ear] call acre_api_fnc_setRadioSpatial) then {_success = false; _problems pushBack format ["%1#%2 ear write failed.", _base, _occurrence]};
        _managedIds pushBack _radioId;
        _applied pushBack [_radioId, _base, _occurrence, _setting, _ear, _netLabel, _mode];
    };
} forEach _resolved;
if (count _setupSettings > 0) then {
    // setupRadios consumes repeated same-type settings in carried-radio order. Sorting by class then
    // occurrence prevents an explicit occurrence-two row from being applied to occurrence one.
    _setupSettings sort true;
    private _broad = [] call acre_api_fnc_getCurrentRadioList;
    private _safe = true;
    {
        private _base = toUpper (_x select 0);
        if !((_broad select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _base}) isEqualTo (_radios select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _base})) then {_safe = false};
    } forEach _setupSettings;
    if (!_safe || {isNil "acre_api_fnc_setupRadios"}) then {_success = false; _problems pushBack "Frequency setup is ambiguous while same-type external/rack radios are accessible."} else {
        private _setupRequest = _setupSettings apply {[_x select 0, _x select 2]};
        if !(_setupRequest call acre_api_fnc_setupRadios) then {_success = false; _problems pushBack "ACRE rejected the radio setup request."};
    };
};
{if !(_x in _managedIds) then {_preserved pushBack [_x, [_x] call acre_api_fnc_getBaseRadio]}} forEach _radios;
if (!_success && {_retryAllowed} && {count _setupSettings == 0}) exitWith {if (canSuspend) then {uiSleep 0.2}; [true, _reason, false] call Waldo_fnc_ACRE2ApplyPlayerPlan};
if (_success) then {missionNamespace setVariable ["Waldo_ACRE2_AppliedSignature", _signature]} else {
    diag_log format ["[WMP ACRE] Assignment failed during %1: %2", _reason, _problems];
    if (_config getOrDefault ["notifyAssignmentProblems", true] && {!(_reason in ["INITIAL", "RESPAWN"])}) then {["ACRE2", "One or more applicable radio assignments failed. Check the CEOI or RPT.", "WARNING", "ACRE2_ASSIGNMENT"] call Waldo_fnc_FeatureNotifyLocal};
};
if (_success) then {diag_log format ["[WMP ACRE] %1 radio plan applied for %2/%3: %4 managed, %5 preserved.", _reason, _sideKey, _groupKey, count _applied, count _preserved]};
missionNamespace setVariable ["Waldo_ACRE2_LastApplication", [_success, _reason, _sideKey, _groupKey, _applied, _problems, _preserved, _pendingFrequency]];
_success
