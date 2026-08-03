/*
 * Author: WaldoTheWarfighter
 * Applies the current server plan to the local player's explicitly managed carried radios. It
 * supports same-type occurrence assignments, per-instance ear placement, direct or logical-net
 * channels and ACRE's public setupRadios frequency path. Unlisted and captured radios are preserved.
 * Calls are idempotent by revision, side, group and loadout generation and retry once after a failed
 * API write or read-back.
 *
 * Arguments:
 * 0: force <BOOL> (default false)
 * 1: reason <STRING> (default MANUAL)
 * 2: allow one retry <BOOL> (internal, default true)
 *
 * Return Value: BOOL - true when a matching plan was applied or was already current.
 *
 * Example: [true, "RESPAWN"] call Waldo_fnc_ACRE2ApplyPlayerPlan;
 * Current callers: Waldo_fnc_ACRE2Init, group/unit lifecycle, respawn and persistence fallback.
 */
params [["_force", false, [true]], ["_reason", "MANUAL", [""]], ["_retryAllowed", true, [true]]];
if (!hasInterface || {isNull player} || {!(isClass (configFile >> "CfgPatches" >> "acre_main"))}) exitWith {false};
private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
if !(_config getOrDefault ["enabled", true]) exitWith {true};
private _plan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
if (count _plan < 4 || {(_plan select 0) != 2}) exitWith {false};
private _sideKey = switch (side player) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
private _sideIndex = (_plan select 2) findIf {(_x select 0) == _sideKey};
if (_sideIndex < 0) exitWith {false};
private _sidePlan = (_plan select 2) select _sideIndex;
_sidePlan params ["_unusedSide", "_preset", "_nets", "_groups"];
private _groupKey = toUpper groupId group player;
private _groupIndex = _groups findIf {(_x select 0) == _groupKey};
if (_groupIndex < 0) exitWith {
    diag_log format ["[WMP ACRE] No %1 plan for group %2.", _sideKey, _groupKey];
    uiNamespace setVariable ["Waldo_ACRE2_LastApplication", [false, _reason, _sideKey, _groupKey, [], ["No matching group plan."], []]];
    false
};
private _generation = missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0];
if ((missionNamespace getVariable ["Waldo_ACRE2_PersistenceRadioGeneration", -1]) == _generation) exitWith {true};
private _groupPlan = _groups select _groupIndex;
_groupPlan params ["_unusedGroup", "_netKeys", "_shortAssignment", "_explicitAssignments"];
private _profiles = _config getOrDefault ["radioProfiles", []];
private _priority = _config getOrDefault ["radioPriority", []];
private _radios = [] call Waldo_fnc_ACRE2GetOrderedRadios;
private _problems = [];
private _applied = [];
private _preserved = [];
private _success = true;

private _normaliseSpatial = {
    params ["_value"];
    private _upper = toUpper _value;
    if (_upper == "BOTH") then {"CENTER"} else {_upper};
};
private _profileFor = {
    params ["_base"];
    private _index = _profiles findIf {toUpper (_x select 0) == toUpper _base};
    if (_index < 0) then {[]} else {_profiles select _index};
};
private _radiosOfType = {
    params ["_base"];
    _radios select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == toUpper _base}
};
private _defaultSpatial = {
    params ["_profile", "_occurrence"];
    private _values = _profile select 2;
    private _index = ((_occurrence - 1) min ((count _values) - 1)) max 0;
    [_values select _index] call _normaliseSpatial
};
private _netFor = {
    params ["_key"];
    private _index = _nets findIf {(_x select 0) == toUpper _key};
    if (_index < 0) then {[]} else {_nets select _index};
};

// A UID, editor-variable or role override replaces the group's explicit assignment list.
{
    _x params ["_selector", "_assignments"];
    _selector params ["_selectorType", "_selectorValue"];
    private _matches = switch (toUpper _selectorType) do {
        case "UID": {getPlayerUID player == _selectorValue};
        case "VARIABLE": {vehicleVarName player == _selectorValue};
        case "ROLE": {
            private _roleParts = roleDescription player splitString "@";
            toUpper (_roleParts param [0, ""]) == toUpper _selectorValue
        };
        default {false};
    };
    if (_matches) exitWith {_explicitAssignments = _assignments};
} forEach (_config getOrDefault ["radioOverrides", []]);
private _signature = format ["%1|%2|%3|%4|%5", _plan select 1, _sideKey, _groupKey, _generation, _explicitAssignments];
if (!_force && {(uiNamespace getVariable ["Waldo_ACRE2_AppliedSignature", ""]) == _signature}) exitWith {true};

private _resolved = [];
if (count _explicitAssignments > 0) then {
    {
        _x params ["_sourceBase", "_occurrence", "_target", "_sourceSpatial"];
        private _base = toUpper _sourceBase;
        private _matching = [_base] call _radiosOfType;
        if (count _matching < _occurrence) then {
            _problems pushBack format ["Missing %1 occurrence %2.", _base, _occurrence];
            _success = false;
        } else {
            private _radioId = _matching select (_occurrence - 1);
            _resolved pushBack [_radioId, _base, _occurrence, _target, [_sourceSpatial] call _normaliseSpatial];
        };
    } forEach _explicitAssignments;
} else {
    // Simple fallback: one squad radio plus successive supported radios for the ordered group nets.
    private _shortProfile = ["ACRE_PRC343"] call _profileFor;
    private _shortRadios = ["ACRE_PRC343"] call _radiosOfType;
    if (count _shortRadios > 0 && {count _shortProfile > 0}) then {
        _resolved pushBack [_shortRadios select 0, "ACRE_PRC343", 1, _shortAssignment, [_shortProfile, 1] call _defaultSpatial];
    };
    private _netCursor = 0;
    {
        private _base = toUpper _x;
        private _profile = [_base] call _profileFor;
        if (count _profile > 0) then {
            private _matching = [_base] call _radiosOfType;
            {
                if (_netCursor < count _netKeys) then {
                    private _targetNet = _netKeys select _netCursor;
                    private _canUseNet = true;
                    if (toUpper (_profile select 1) == "FREQUENCY") then {
                        private _net = [_targetNet] call _netFor;
                        _canUseNet = count _net > 0 && {((_net select 3) findIf {toUpper (_x select 0) == _base}) >= 0};
                    };
                    if (_canUseNet) then {
                        _resolved pushBack [_x, _base, _forEachIndex + 1, _targetNet, [_profile, _forEachIndex + 1] call _defaultSpatial];
                        _netCursor = _netCursor + 1;
                    };
                };
            } forEach _matching;
        };
    } forEach _priority;
};

private _frequencySettings = [];
private _managedIds = [];
{
    _x params ["_radioId", "_base", "_occurrence", "_target", "_spatial"];
    private _profile = [_base] call _profileFor;
    if (count _profile == 0) then {
        _problems pushBack format ["No profile for %1.", _base];
        _success = false;
    } else {
        private _mode = toUpper (_profile select 1);
        private _setting = _target;
        private _netLabel = "DIRECT";
        private _assignmentReady = true;
        if (_target isEqualType "") then {
            private _net = [_target] call _netFor;
            if (count _net == 0) then {
                _problems pushBack format ["%1#%2 references missing net %3.", _base, _occurrence, _target];
                _success = false;
                _assignmentReady = false;
            } else {
                _netLabel = _net select 1;
                if (_mode == "FREQUENCY") then {
                    private _overrideIndex = (_net select 3) findIf {toUpper (_x select 0) == _base};
                    if (_overrideIndex < 0) then {
                        _problems pushBack format ["%1#%2 net %3 has no frequency override.", _base, _occurrence, _target];
                        _success = false;
                        _assignmentReady = false;
                    } else {
                        _setting = ((_net select 3) select _overrideIndex) select 1;
                    };
                } else {
                    _setting = _net select 2;
                };
            };
        };
        if (_assignmentReady) then {
            if (_mode == "BLOCK_CHANNEL") then {
                private _flat = ((_setting select 0) - 1) * 16 + (_setting select 1);
                if !([_radioId, _flat] call acre_api_fnc_setRadioChannel) then {_success = false};
                if (([_radioId] call acre_api_fnc_getRadioChannel) != _flat) then {_success = false};
            };
            if (_mode == "CHANNEL") then {
                if !([_radioId, _setting] call acre_api_fnc_setRadioChannel) then {_success = false};
                if (([_radioId] call acre_api_fnc_getRadioChannel) != _setting) then {_success = false};
            };
            if (_mode == "FREQUENCY") then {
                if (_setting isEqualType 0) then {
                    private _range = _profile select 4;
                    private _divisor = _range select 3;
                    private _whole = floor _setting;
                    _setting = [_whole, round ((_setting - _whole) * _divisor)];
                };
                _frequencySettings pushBack [_base, _setting];
            };
            if !([_radioId, _spatial] call acre_api_fnc_setRadioSpatial) then {_success = false};
            if (([_radioId] call acre_api_fnc_getRadioSpatial) != _spatial) then {_success = false};
            _managedIds pushBack _radioId;
            _applied pushBack [_radioId, _base, _occurrence, _setting, _spatial, _netLabel];
        };
    };
} forEach _resolved;

if (count _frequencySettings > 0) then {
    if (isNil "acre_api_fnc_setupRadios") then {
        _problems pushBack "This ACRE version has no public setupRadios function; frequency radios were unchanged.";
        _success = false;
    } else {
        private _broadRadios = [] call acre_api_fnc_getCurrentRadioList;
        private _frequencyClasses = _frequencySettings apply {toUpper (_x select 0)};
        private _safeFrequencyOrder = true;
        {
            private _base = _x;
            private _broadMatching = _broadRadios select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _base};
            private _carriedMatching = _radios select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _base};
            if !(_broadMatching isEqualTo _carriedMatching) then {_safeFrequencyOrder = false};
        } forEach (_frequencyClasses arrayIntersect _frequencyClasses);
        if (!_safeFrequencyOrder) then {
            _problems pushBack "Frequency setup is ambiguous while a same-type rack or external radio is accessible; carried radios were unchanged.";
            _success = false;
        } else {
            if !(_frequencySettings call acre_api_fnc_setupRadios) then {_success = false};
        };
    };
};
{
    if !(_x in _managedIds) then {_preserved pushBack [_x, [_x] call acre_api_fnc_getBaseRadio]};
} forEach _radios;

if (!_success && {_retryAllowed}) exitWith {
    if (canSuspend) then {uiSleep 0.2};
    [true, _reason, false] call Waldo_fnc_ACRE2ApplyPlayerPlan
};
if (!_success) then {
    diag_log format ["[WMP ACRE] Assignment failed during %1: %2", _reason, _problems];
    if (_config getOrDefault ["notifyAssignmentProblems", true] && {!(_reason in ["INITIAL", "RESPAWN"])}) then {
        ["ACRE2", "One or more configured radio assignments could not be applied. Check the ACRE2 status station or RPT.", "WARNING", "ACRE2_ASSIGNMENT"] call Waldo_fnc_FeatureNotifyLocal;
    };
} else {
    uiNamespace setVariable ["Waldo_ACRE2_AppliedSignature", _signature];
};
uiNamespace setVariable ["Waldo_ACRE2_LastApplication", [_success, _reason, _sideKey, _groupKey, _applied, _problems, _preserved]];
_success
