/*
 * Author: WaldoTheWarfighter
 * Applies the current server plan to supported local carried radios. A unified ALL row applies to
 * every carried occurrence of its class; alternatively, numbered rows configure differing duplicate
 * radios. Validation prevents mixing those two styles for one class. This includes
 * PRC-343 block/channel and ear settings. Absent occurrences are skipped. Unlisted,
 * unsupported and captured radios are preserved. Named nets contain one family-scoped value rather
 * than per-radio tunings. Frequency requests use ACRE's asynchronous public
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
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACRE-2-Long-Range-Radio-Presetting
 */
params [["_force", false, [true]], ["_reason", "MANUAL", [""]], ["_retryAllowed", true, [true]]];
if (!hasInterface || {isNull player} || {!(isClass (configFile >> "CfgPatches" >> "acre_main"))}) exitWith {false};
private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
if !(_config getOrDefault ["enabled", true]) exitWith {true};
private _plan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
if (count _plan < 4 || {(_plan select 0) != 5}) exitWith {false};
private _sideKey = switch (side player) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
private _sideIndex = (_plan select 2) findIf {(_x select 0) == _sideKey};
if (_sideIndex < 0) exitWith {false};
private _sidePlan = (_plan select 2) select _sideIndex;
_sidePlan params ["_unusedSide", "_preset", "_nets", "_groups"];
// Eden/CBA callsigns commonly alternate spaces, hyphens, underscores and dots. Treat those
// separators as presentation so `VIKING-2-3` and `Viking 2-3` resolve to the same authored group.
private _groupKey = toUpperANSI ((((groupId group player) splitString " -_.") joinString ""));
private _groupIndex = _groups findIf {(_x select 0) == _groupKey};
if (_groupIndex < 0) exitWith {
    diag_log format ["[WMP ACRE] No %1 plan for group %2.", _sideKey, _groupKey];
    missionNamespace setVariable ["Waldo_ACRE2_LastApplication", [false, _reason, _sideKey, _groupKey, [], ["No matching group plan."], [], []]];
    false
};
private _generation = missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0];
if ((missionNamespace getVariable ["Waldo_ACRE2_RestoredRadioGeneration", -1]) == _generation) exitWith {true};
private _groupPlan = _groups select _groupIndex;
_groupPlan params ["_unusedGroup", "_assignments"];
private _profiles = [_config] call Waldo_fnc_ACRE2GetRadioProfiles;
private _radios = [] call Waldo_fnc_ACRE2GetOrderedRadios;
private _problems = [];
private _applied = [];
private _preserved = [];
private _pendingFrequency = [];
private _success = true;
private _profileFor = {params ["_base"]; private _i = _profiles findIf {toUpper (_x select 0) == toUpper _base}; if (_i < 0) then {[]} else {_profiles select _i}};
private _netFor = {params ["_key"]; private _i = _nets findIf {(_x select 0) == toUpper _key}; if (_i < 0) then {[]} else {_nets select _i}};
private _netCompatible = {params ["_net", "_profile"]; count _net == 4 && {count _profile >= 6} && {toUpper (_net select 2) == toUpper (_profile select 5)}};
private _normaliseEar = {params ["_value"]; private _ear = toUpper _value; if (_ear == "BOTH") then {"CENTER"} else {_ear}};
private _profileClasses = _profiles apply {toUpperANSI (_x select 0)};
private _inventoryRadios = (items player + assignedItems player) select {
    private _item = toUpperANSI _x;
    (_profileClasses findIf {_item == _x || {_item find (_x + "_ID_") == 0}}) >= 0
};
if (!(_inventoryRadios isEqualTo []) && {_radios isEqualTo []}) exitWith {
    private _message = format ["Supported radio items exist in the inventory (%1), but ACRE returned no unique carried radios.", _inventoryRadios];
    missionNamespace setVariable ["Waldo_ACRE2_LastApplication", [false, _reason, _sideKey, _groupKey, [], [_message], [], []]];
    diag_log format ["[WMP ACRE] %1", _message];
    false
};

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
            if (toUpper _mode == "REPLACE") then {_assignments = []};
            {
                private _scope = if ((_x select 1) isEqualType "") then {toUpper (_x select 1)} else {_x select 1};
                private _identity = format ["%1#%2", toUpper (_x select 0), _scope];
                private _existing = _assignments findIf {format ["%1#%2", toUpper (_x select 0), if ((_x select 1) isEqualType "") then {toUpper (_x select 1)} else {_x select 1}] == _identity};
                private _row = [toUpper (_x select 0), _scope, _x select 2, [_x select 3] call _normaliseEar];
                if (_existing < 0) then {_assignments pushBack _row} else {_assignments set [_existing, _row]};
            } forEach _overrideAssignments;
        };
    };
} forEach (_config getOrDefault ["radioOverrides", []]);
private _signature = format ["%1|%2|%3|%4|%5", _plan select 1, _sideKey, _groupKey, _generation, _assignments];
if (!_force && {(missionNamespace getVariable ["Waldo_ACRE2_AppliedSignature", ""]) == _signature}) exitWith {true};

private _resolved = [];
// Validated plans use ALL or numbered rows for a class, never both. Checking the exact occurrence
// first keeps lookup deterministic. Radios without either style remain untouched.
private _typeCounts = createHashMap;
{
    private _radioId = _x;
    private _base = toUpper ([_radioId] call acre_api_fnc_getBaseRadio);
    private _profile = [_base] call _profileFor;
    private _occurrence = (_typeCounts getOrDefault [_base, 0]) + 1;
    _typeCounts set [_base, _occurrence];
    if (count _profile > 0) then {
        private _ruleIndex = _assignments findIf {toUpper (_x select 0) == _base && {(_x select 1) isEqualType 0} && {(_x select 1) == _occurrence}};
        if (_ruleIndex < 0) then {
            _ruleIndex = _assignments findIf {
                toUpper (_x select 0) == _base
                    && {(_x select 1) isEqualType ""}
                    && {toUpper (_x select 1) == "ALL"}
            };
        };
        if (_ruleIndex >= 0) then {
            private _rule = _assignments select _ruleIndex;
            _resolved pushBack [_radioId, _base, _occurrence, _rule select 2, [_rule select 3] call _normaliseEar];
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
        if !([_net, _profile] call _netCompatible) then {
            _ready = false; _success = false;
            _problems pushBack format ["%1#%2 cannot use net %3: radio family %4 does not match net family %5.", _base, _occurrence, _target, _profile param [5, "UNKNOWN"], _net param [2, "UNKNOWN"]];
        } else {_setting = _net select 3; _netLabel = _net select 1};
    };
    if (_ready && {_mode == "BLOCK_CHANNEL"}) then {
        // ACRE reports and directly sets the PRC-343 as one absolute channel from 1 to 256. Its
        // setupRadios helper accepts [channel, block], but applies that request asynchronously even
        // after ACRE is initialised. Using it here allowed the automatic respawn snapshot to be
        // captured before the change occurred, permanently saving the new radio's Block 1/Channel 1
        // default. Target the already-resolved unique ID directly and require immediate read-back.
        private _absoluteChannel = (((_setting select 0) - 1) * 16) + (_setting select 1);
        if !([_radioId, _absoluteChannel] call acre_api_fnc_setRadioChannel) then {
            _success = false;
            _problems pushBack format ["%1#%2 Block %3/Channel %4 write failed.", _base, _occurrence, _setting select 0, _setting select 1];
        };
        if (([_radioId] call acre_api_fnc_getRadioChannel) != _absoluteChannel) then {
            _success = false;
            _problems pushBack format ["%1#%2 Block %3/Channel %4 read-back failed.", _base, _occurrence, _setting select 0, _setting select 1];
        };
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
    // Only frequency radios use setupRadios here. Channel and PRC-343 block/channel radios are
    // applied directly to their resolved unique IDs so they can be read back synchronously.
    // Sorting by class then occurrence keeps repeated frequency-radio requests deterministic.
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
