/*
 * Author: WaldoTheWarfighter
 * Validates the root ACRE2 configuration without mutating radios, presets or network state. It
 * checks capability profiles, assignment identity, ear values, side presets, logical nets,
 * group allocations and player/role overrides. Strict mode promotes 343 collisions to errors.
 *
 * Arguments:
 * 0: configuration <HASHMAP>
 *
 * Return Value: ARRAY - [valid <BOOL>, errors <ARRAY>, warnings <ARRAY>].
 *
 * Example: private _result = [_config] call Waldo_fnc_ACRE2ValidateConfig;
 * Current callers: Waldo_fnc_ACRE2PreInit and Waldo_fnc_ACRE2Init.
 */
params [["_config", createHashMap, [createHashMap]]];
private _errors = [];
private _warnings = [];
private _strict = _config getOrDefault ["strict", true];
private _prc343PresetPolicy = toUpper (_config getOrDefault ["prc343PresetPolicy", "FULL_RANGE"]);
if ((_config getOrDefault ["version", -1]) != 2) then {_errors pushBack "Unsupported configuration version; expected 2."};
if !(_prc343PresetPolicy in ["FULL_RANGE", "SIDE_ISOLATED"]) then {_errors pushBack "prc343PresetPolicy must be FULL_RANGE or SIDE_ISOLATED."};
{
    _x params ["_key", "_default"];
    if !((_config getOrDefault [_key, _default]) isEqualType true) then {_errors pushBack format ["%1 must be true or false.", _key]};
} forEach [["enabled", true], ["strict", true], ["retuneOnGroupChange", false], ["namedDisplays", true], ["notifyAssignmentProblems", true]];

private _normaliseSide = {
    params ["_value"];
    switch (toUpper _value) do {
        case "BLUFOR";
        case "WEST": {"WEST"};
        case "OPFOR";
        case "EAST": {"EAST"};
        case "INDEPENDENT";
        case "INDEP";
        case "GUER": {"GUER"};
        case "CIVILIAN";
        case "CIV": {"CIV"};
        default {toUpper _value};
    };
};
private _normaliseSpatial = {
    params ["_value"];
    private _upper = toUpper _value;
    if (_upper == "BOTH") then {"CENTER"} else {_upper};
};
private _validFrequency = {
    params ["_value", ["_range", []]];
    private _mhz = -1;
    private _khz = 0;
    if (_value isEqualType 0) then {_mhz = _value; _khz = round ((_value - floor _value) * 1000)};
    if (_value isEqualType [] && {count _value == 2} && {(_value select 0) isEqualType 0} && {(_value select 1) isEqualType 0}) then {
        private _divisor = if (count _range == 4) then {_range select 3} else {1000};
        _mhz = (_value select 0) + ((_value select 1) / _divisor);
        _khz = round (((_value select 1) / _divisor) * 1000);
        if ((_value select 1) < 0 || {(_value select 1) >= _divisor}) then {_mhz = -1};
    };
    if (_mhz <= 0 || {_khz < 0} || {_khz >= 1000}) exitWith {false};
    if (count _range != 4) exitWith {true};
    private _step = _range select 2;
    _mhz >= (_range select 0) && {_mhz <= (_range select 1)} && {_step > 0} && {abs ((_khz / _step) - round (_khz / _step)) < 0.001}
};

private _profiles = _config getOrDefault ["radioProfiles", []];
private _profileClasses = [];
{
    if (count _x < 5) then {
        _errors pushBack format ["Malformed radio profile: %1", _x];
    } else {
        _x params ["_class", "_mode", "_spatials", "_maxChannel", "_frequencyRange"];
        _class = toUpper _class;
        _mode = toUpper _mode;
        if (_class == "") then {_errors pushBack "A radio profile has an empty class name."};
        if (isClass (configFile >> "CfgPatches" >> "acre_main") && {!(isClass (configFile >> "CfgWeapons" >> (_x select 0)))}) then {_errors pushBack format ["Radio profile class %1 is not present in CfgWeapons.", _x select 0]};
        if (_class in _profileClasses) then {_errors pushBack format ["Duplicate radio profile %1.", _class]};
        _profileClasses pushBack _class;
        if !(_mode in ["BLOCK_CHANNEL", "CHANNEL", "FREQUENCY"]) then {_errors pushBack format ["%1 has invalid profile mode %2.", _class, _mode]};
        if !(_spatials isEqualType []) then {
            _errors pushBack format ["%1 ear defaults must be an array.", _class];
        } else {
            if (count _spatials == 0) then {_errors pushBack format ["%1 must define at least one default ear.", _class]};
            {
                if !(([_x] call _normaliseSpatial) in ["LEFT", "RIGHT", "CENTER"]) then {
                    _errors pushBack format ["%1 has invalid ear value %2; use LEFT, RIGHT, BOTH or CENTER.", _class, _x];
                };
            } forEach _spatials;
        };
        if !(_maxChannel isEqualType 0) then {_errors pushBack format ["%1 maximum channel must be numeric.", _class]};
        if (_mode in ["BLOCK_CHANNEL", "CHANNEL"] && {_maxChannel < 1}) then {_errors pushBack format ["%1 requires a positive maximum channel.", _class]};
        if (_mode == "FREQUENCY") then {
            if (count _frequencyRange != 4 || {!((_frequencyRange select 0) isEqualType 0)} || {!((_frequencyRange select 1) isEqualType 0)} || {!((_frequencyRange select 2) isEqualType 0)} || {!((_frequencyRange select 3) isEqualType 0)} || {(_frequencyRange select 0) >= (_frequencyRange select 1)} || {(_frequencyRange select 2) <= 0} || {(_frequencyRange select 3) <= 0}) then {
                _errors pushBack format ["%1 requires frequency range [minimum MHz, maximum MHz, step kHz, ACRE pair divisor].", _class];
            };
        } else {
            if !(_frequencyRange isEqualTo []) then {_errors pushBack format ["%1 is not a frequency profile and must use an empty frequency range.", _class]};
        };
    };
} forEach _profiles;

private _prioritySeen = [];
{
    private _class = toUpper _x;
    if (_class in _prioritySeen) then {_errors pushBack format ["Duplicate radioPriority class %1.", _class]};
    _prioritySeen pushBack _class;
    if !(_class in _profileClasses) then {_errors pushBack format ["radioPriority class %1 has no radio profile.", _class]};
} forEach (_config getOrDefault ["radioPriority", []]);

private _expectedPresets = createHashMapFromArray [["WEST", "default3"], ["EAST", "default2"], ["GUER", "default4"], ["CIV", "default"]];
private _sideKeys = [];
private _allNetKeys = [];
private _sideData = [];
{
    if (count _x < 4) then {
        _errors pushBack format ["Malformed side entry: %1", _x];
    } else {
        _x params ["_sourceSide", "_preset", "_nets", "_groups"];
        private _sideKey = [_sourceSide] call _normaliseSide;
        if !(_sideKey in ["WEST", "EAST", "GUER", "CIV"]) then {_errors pushBack format ["Invalid side key %1.", _sourceSide]};
        if (_sideKey in _sideKeys) then {_errors pushBack format ["Duplicate side key %1.", _sideKey]};
        _sideKeys pushBack _sideKey;
        if (_preset != (_expectedPresets getOrDefault [_sideKey, ""])) then {
            _errors pushBack format ["%1 must use existing ACRE preset %2, not %3.", _sideKey, _expectedPresets getOrDefault [_sideKey, ""], _preset];
        };
        private _netKeys = [];
        {
            if (count _x < 3) then {
                _errors pushBack format ["Malformed %1 net: %2", _sideKey, _x];
            } else {
                private _netKey = toUpper (_x select 0);
                if (_netKey == "") then {_errors pushBack format ["%1 contains an empty net key.", _sideKey]};
                private _safeLabel = "";
                {if (_x in (toArray "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_/")) then {_safeLabel = _safeLabel + toString [_x]}} forEach toArray toUpper (_x select 1);
                if (_safeLabel == "") then {_errors pushBack format ["%1/%2 display label contains no supported characters.", _sideKey, _netKey]};
                if (count _safeLabel > 12) then {_warnings pushBack format ["%1/%2 physical display label will be truncated to 12 characters.", _sideKey, _netKey]};
                if (_netKey in _netKeys) then {_errors pushBack format ["Duplicate %1 net key %2.", _sideKey, _netKey]};
                _netKeys pushBack _netKey;
                _allNetKeys pushBackUnique _netKey;
                private _overrideClasses = [];
                {
                    if (count _x != 2) then {
                        _errors pushBack format ["Malformed %1/%2 frequency override: %3", _sideKey, _netKey, _x];
                    } else {
                        private _overrideClass = toUpper (_x select 0);
                        if (_overrideClass in _overrideClasses) then {_errors pushBack format ["Duplicate %1/%2 override for %3.", _sideKey, _netKey, _overrideClass]};
                        _overrideClasses pushBack _overrideClass;
                        private _profileIndex = _profiles findIf {toUpper (_x select 0) == _overrideClass};
                        if (_profileIndex < 0 || {toUpper ((_profiles select _profileIndex) select 1) != "FREQUENCY"}) then {
                            _errors pushBack format ["%1/%2 override class %3 is not a FREQUENCY profile.", _sideKey, _netKey, _overrideClass];
                        };
                        private _range = if (_profileIndex >= 0) then {(_profiles select _profileIndex) select 4} else {[]};
                        if !([(_x select 1), _range] call _validFrequency) then {_errors pushBack format ["%1/%2 has invalid frequency override %3.", _sideKey, _netKey, _x select 1]};
                    };
                } forEach (_x select 2);
            };
        } forEach _nets;
        private _channelProfiles = _profiles select {toUpper (_x select 1) == "CHANNEL"};
        {
            if (count _nets > (_x select 3)) then {_errors pushBack format ["%1 defines %2 nets but %3 supports only %4 channels.", _sideKey, count _nets, _x select 0, _x select 3]};
        } forEach _channelProfiles;
        private _max343Block = if (_prc343PresetPolicy == "FULL_RANGE" || {_preset == "default"}) then {16} else {5};
        _sideData pushBack [_sideKey, _netKeys, _groups, _max343Block];
    };
} forEach (_config getOrDefault ["sides", []]);

private _validateAssignments = {
    params ["_assignments", "_context", "_allowedNets", ["_max343Block", 16]];
    private _identities = [];
    private _frequencyOccurrences = createHashMap;
    {
        if (count _x < 4) then {
            _errors pushBack format ["Malformed %1 radio assignment: %2", _context, _x];
        } else {
            _x params ["_sourceClass", "_occurrence", "_target", "_spatial"];
            private _class = toUpper _sourceClass;
            private _profileIndex = _profiles findIf {toUpper (_x select 0) == _class};
            if (_profileIndex < 0) then {_errors pushBack format ["%1 assignment class %2 has no profile.", _context, _class]};
            if !(_occurrence isEqualType 0) then {
                _errors pushBack format ["%1/%2 occurrence must be numeric.", _context, _class];
            } else {
                if (_occurrence < 1 || {_occurrence != floor _occurrence}) then {_errors pushBack format ["%1/%2 occurrence must be an integer of 1 or greater.", _context, _class]};
            };
            private _identity = format ["%1#%2", _class, _occurrence];
            if (_identity in _identities) then {_errors pushBack format ["%1 contains duplicate assignment %2.", _context, _identity]};
            _identities pushBack _identity;
            if !(([_spatial] call _normaliseSpatial) in ["LEFT", "RIGHT", "CENTER"]) then {_errors pushBack format ["%1/%2 has invalid ear %3.", _context, _identity, _spatial]};
            if (_target isEqualType "") then {
                if !((toUpper _target) in _allowedNets) then {_errors pushBack format ["%1/%2 references unknown net %3.", _context, _identity, _target]};
            } else {
                if !(_target isEqualType 0 || {_target isEqualType []}) then {_errors pushBack format ["%1/%2 has invalid target %3.", _context, _identity, _target]};
                if (_profileIndex >= 0) then {
                    private _profile = _profiles select _profileIndex;
                    private _mode = toUpper (_profile select 1);
                    if (_mode == "BLOCK_CHANNEL" && {!(_target isEqualType [] && {count _target == 2} && {(_target select 0) >= 1} && {(_target select 0) <= _max343Block} && {(_target select 0) == floor (_target select 0)} && {(_target select 1) in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]})}) then {
                        _errors pushBack format ["%1/%2 PRC-343 target must be [block, channel] with block 1-%3 and channel 1-16 for this preset.", _context, _identity, _max343Block];
                    };
                    if (_mode == "CHANNEL" && {!(_target isEqualType 0 && {_target >= 1} && {_target <= (_profile select 3)} && {_target == floor _target})}) then {
                        _errors pushBack format ["%1/%2 direct channel must be an integer from 1 to %3.", _context, _identity, _profile select 3];
                    };
                    if (_mode == "FREQUENCY" && {!([_target, _profile select 4] call _validFrequency)}) then {
                        _errors pushBack format ["%1/%2 has invalid direct frequency %3.", _context, _identity, _target];
                    };
                };
            };
            if (_profileIndex >= 0 && {toUpper ((_profiles select _profileIndex) select 1) == "FREQUENCY"}) then {
                private _occurrences = _frequencyOccurrences getOrDefault [_class, []];
                _occurrences pushBack _occurrence;
                _frequencyOccurrences set [_class, _occurrences];
            };
        };
    } forEach _assignments;
    {
        private _classKey = _x;
        private _occurrences = _frequencyOccurrences get _classKey;
        _occurrences sort true;
        {
            if (_x != (_forEachIndex + 1)) then {_errors pushBack format ["%1 frequency assignments for %2 must be contiguous from occurrence 1.", _context, _classKey]};
        } forEach _occurrences;
    } forEach keys _frequencyOccurrences;
};

{
    _x params ["_sideKey", "_netKeys", "_groups", "_max343Block"];
    private _assignments = [];
    private _groupKeys = [];
    {
        if (count _x < 4) then {
            _errors pushBack format ["Malformed %1 group: %2", _sideKey, _x];
        } else {
            _x params ["_groupId", "_netRefs", "_explicit343", "_radioAssignments"];
            private _groupKey = toUpper _groupId;
            if (_groupKey == "") then {_errors pushBack format ["%1 contains an empty group ID.", _sideKey]};
            if (_groupKey in _groupKeys) then {_errors pushBack format ["Duplicate %1 group %2.", _sideKey, _groupKey]};
            _groupKeys pushBack _groupKey;
            {if !((toUpper _x) in _netKeys) then {_errors pushBack format ["%1/%2 references unknown net %3.", _sideKey, _groupKey, _x]}} forEach _netRefs;
            private _explicitShortAssignments = _radioAssignments select {count _x >= 3 && {toUpper (_x select 0) == "ACRE_PRC343"} && {(_x select 2) isEqualType []}};
            if (_explicitShortAssignments isEqualTo [] && {!(_explicit343 isEqualTo [])}) then {
                if (count _explicit343 != 2 || {(_explicit343 select 0) < 1} || {(_explicit343 select 0) > _max343Block} || {!((_explicit343 select 1) in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16])}) then {
                    _errors pushBack format ["%1/%2 has invalid fallback PRC-343 assignment %3.", _sideKey, _groupKey, _explicit343];
                } else {
                    private _flat = ((_explicit343 select 0) - 1) * 16 + (_explicit343 select 1);
                    if (_flat in _assignments) then {
                        private _message = format ["%1 PRC-343 collision at %2.", _sideKey, _explicit343];
                        if (_strict) then {_errors pushBack _message} else {_warnings pushBack _message};
                    };
                    _assignments pushBack _flat;
                };
            };
            [_radioAssignments, format ["%1/%2", _sideKey, _groupKey], _netKeys, _max343Block] call _validateAssignments;
            {
                private _target = _x select 2;
                if (count _target == 2 && {(_target select 0) >= 1} && {(_target select 0) <= _max343Block} && {(_target select 1) in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]}) then {
                    private _flat = ((_target select 0) - 1) * 16 + (_target select 1);
                    if (_flat in _assignments) then {
                        if (_strict) then {
                            _errors pushBack format ["%1 explicit PRC-343 collision at %2.", _sideKey, _target];
                        } else {
                            _warnings pushBack format ["%1 explicit PRC-343 collision at %2.", _sideKey, _target];
                        };
                    };
                    _assignments pushBack _flat;
                };
            } forEach _explicitShortAssignments;
        };
    } forEach _groups;
} forEach _sideData;

{
    if (count _x < 2 || {count (_x select 0) != 2}) then {
        _errors pushBack format ["Malformed radio override: %1", _x];
    } else {
        private _selector = _x select 0;
        private _selectorType = toUpper (_selector select 0);
        if !(_selectorType in ["UID", "VARIABLE", "ROLE"]) then {_errors pushBack format ["Invalid radio override selector %1.", _selectorType]};
        if ((_selector select 1) == "") then {_errors pushBack format ["%1 radio override has an empty selector value.", _selectorType]};
        [_x select 1, format ["override %1/%2", _selectorType, _selector select 1], _allNetKeys, if (_prc343PresetPolicy == "FULL_RANGE") then {16} else {5}] call _validateAssignments;
    };
} forEach (_config getOrDefault ["radioOverrides", []]);

private _babel = _config getOrDefault ["babel", createHashMap];
{
    _x params ["_key", "_default"];
    if !((_babel getOrDefault [_key, _default]) isEqualType true) then {_errors pushBack format ["Babel %1 must be true or false.", _key]};
} forEach [["enabled", false], ["changeOnSideChange", false], ["followPlayerUnit", true]];
private _languageIds = [];
{
    if (count _x != 2 || {!((_x select 0) isEqualType "")} || {!((_x select 1) isEqualType "")} || {(_x select 0) == ""} || {(_x select 1) == ""}) then {
        _errors pushBack format ["Malformed Babel language: %1", _x];
    } else {
        if ((_x select 0) in _languageIds) then {_errors pushBack format ["Duplicate Babel language ID %1.", _x select 0]};
        _languageIds pushBack (_x select 0);
    };
} forEach (_babel getOrDefault ["languages", []]);
if (_babel getOrDefault ["enabled", false] && {count _languageIds == 0}) then {_errors pushBack "Enabled Babel configuration requires at least one language."};
private _babelSides = [];
{
    if (count _x != 3) then {
        _errors pushBack format ["Malformed Babel side default: %1", _x];
    } else {
        private _sideKey = [_x select 0] call _normaliseSide;
        if !(_sideKey in ["WEST", "EAST", "GUER", "CIV"]) then {_errors pushBack format ["Invalid Babel side %1.", _x select 0]};
        if (_sideKey in _babelSides) then {_errors pushBack format ["Duplicate Babel side default %1.", _sideKey]};
        _babelSides pushBack _sideKey;
        {if !(_x in _languageIds) then {_errors pushBack format ["Babel %1 default references unknown language %2.", _sideKey, _x]}} forEach (_x select 1);
        if !((_x select 2) in (_x select 1)) then {_errors pushBack format ["Babel %1 speaking language must be understood.", _sideKey]};
    };
} forEach (_babel getOrDefault ["sideDefaults", []]);
{
    if (count _x != 3 || {count (_x select 0) != 2}) then {
        _errors pushBack format ["Malformed Babel unit override: %1", _x];
    } else {
        private _selectorType = toUpper ((_x select 0) select 0);
        if !(_selectorType in ["UID", "VARIABLE"]) then {_errors pushBack format ["Invalid Babel override selector %1.", _selectorType]};
        {if !(_x in _languageIds) then {_errors pushBack format ["Babel override references unknown language %1.", _x]}} forEach (_x select 1);
        if !((_x select 2) in (_x select 1)) then {_errors pushBack "A Babel override speaking language must be understood."};
    };
} forEach (_babel getOrDefault ["unitOverrides", []]);

[count _errors == 0, _errors, _warnings]
