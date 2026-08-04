/*
 * Author: WaldoTheWarfighter
 * Validates the current mission-facing ACRE settings without mutating radios or presets. Validation
 * is per side and per radio capability: unrelated radio types never impose a shared net limit.
 * Locality and authority: pure-data validation; safe on any machine. It changes no radio, preset,
 * missionNamespace value or network state.
 *
 * Arguments:
 * 0: configuration <HASHMAP>
 *
 * Return Value: ARRAY - [valid <BOOL>, errors <ARRAY>, warnings <ARRAY>].
 *
 * Example: private _result = [_config] call Waldo_fnc_ACRE2ValidateConfig;
 * Result: `_result` reports structural validity, blocking errors and non-blocking warnings.
 * Current callers: Waldo_fnc_ACRE2PreInit and Waldo_fnc_ACRE2Init.
 */
params [["_config", createHashMap, [createHashMap]]];
private _errors = [];
private _warnings = [];
private _strict = _config getOrDefault ["strict", true];
private _policy = toUpper (_config getOrDefault ["prc343PresetPolicy", "FULL_RANGE"]);
if !(_policy in ["FULL_RANGE", "SIDE_ISOLATED"]) then {_errors pushBack "prc343PresetPolicy must be FULL_RANGE or SIDE_ISOLATED."};
{
    _x params ["_key", "_default"];
    if !((_config getOrDefault [_key, _default]) isEqualType true) then {_errors pushBack format ["%1 must be true or false.", _key]};
} forEach [["enabled", true], ["strict", true], ["namedDisplays", true], ["notifyAssignmentProblems", true]];
private _normaliseSide = {
    params ["_value"];
    switch (toUpper _value) do {
        case "BLUFOR"; case "WEST": {"WEST"}; case "OPFOR"; case "EAST": {"EAST"};
        case "INDEPENDENT"; case "INDEP"; case "GUER": {"GUER"}; case "CIVILIAN"; case "CIV": {"CIV"};
        default {toUpper _value};
    }
};
private _normaliseEar = {params ["_ear"]; private _value = toUpper _ear; if (_value == "BOTH") then {"CENTER"} else {_value}};
private _profiles = [_config] call Waldo_fnc_ACRE2GetRadioProfiles;
private _profileFor = {params ["_class"]; private _index = _profiles findIf {toUpper (_x select 0) == toUpper _class}; if (_index < 0) then {[]} else {_profiles select _index}};
private _frequencyValid = {
    params ["_value", "_range"];
    if (count _range != 4) exitWith {false};
    private _mhz = -1;
    if (_value isEqualType 0) then {_mhz = _value};
    if (_value isEqualType [] && {count _value == 2}) then {_mhz = (_value select 0) + ((_value select 1) / (_range select 3))};
    if (_mhz < (_range select 0) || {_mhz > (_range select 1)}) exitWith {false};
    private _khz = round ((_mhz - floor _mhz) * 1000);
    abs ((_khz / (_range select 2)) - round (_khz / (_range select 2))) < 0.001
};
private _profileAcceptsValue = {
    params ["_value", "_profile", "_max343Block"];
    private _mode = toUpper (_profile select 1);
    switch (_mode) do {
        case "BLOCK_CHANNEL": {
            _value isEqualType [] && {count _value == 2} &&
            {(_value select 0) >= 1} && {(_value select 0) <= _max343Block} &&
            {(_value select 1) >= 1} && {(_value select 1) <= 16}
        };
        case "CHANNEL": {
            _value isEqualType 0 && {_value >= 1} &&
            {_value <= (_profile select 3)} && {_value == floor _value}
        };
        case "FREQUENCY": {[_value, _profile select 4] call _frequencyValid};
        default {false};
    }
};
private _profileClasses = [];
private _profileFamilies = [];
{
    if (count _x != 6) then {_errors pushBack format ["Malformed radio profile %1; expected [class, mode, ears, maximum channel, frequency range, net family].", _x]} else {
        _x params ["_class", "_mode", "_ears", "_maxChannel", "_range", "_family"];
        private _upperClass = toUpper _class;
        if (_upperClass in _profileClasses) then {_errors pushBack format ["Duplicate radio profile %1.", _class]};
        _profileClasses pushBack _upperClass;
        if !(toUpper _mode in ["BLOCK_CHANNEL", "CHANNEL", "FREQUENCY"]) then {_errors pushBack format ["%1 has invalid mode %2.", _class, _mode]};
        if (count _ears == 0 || {{!(([toUpper _x] call _normaliseEar) in ["LEFT", "RIGHT", "CENTER"])} count _ears > 0}) then {_errors pushBack format ["%1 has invalid default ears.", _class]};
        if (toUpper _mode in ["BLOCK_CHANNEL", "CHANNEL"] && {_maxChannel < 1}) then {_errors pushBack format ["%1 requires a positive channel capacity.", _class]};
        if (toUpper _mode == "FREQUENCY" && {count _range != 4}) then {_errors pushBack format ["%1 requires [minimum MHz, maximum MHz, step kHz, divisor].", _class]};
        if (_family == "") then {_errors pushBack format ["%1 requires a net family.", _class]} else {_profileFamilies pushBackUnique (toUpper _family)};
    };
} forEach _profiles;
private _expectedPresets = createHashMapFromArray [["WEST", "default3"], ["EAST", "default2"], ["GUER", "default4"], ["CIV", "default"]];
private _sideData = createHashMap;
private _sideKeys = [];
private _validateAssignment = {
    params ["_assignment", "_context", "_netMap", "_max343Block", ["_allowAutomatic343", false]];
    if (count _assignment != 4) exitWith {_errors pushBack format ["Malformed %1 assignment %2.", _context, _assignment]};
    _assignment params ["_class", "_occurrence", "_target", "_ear"];
    private _profile = [_class] call _profileFor;
    if (count _profile == 0) exitWith {_errors pushBack format ["%1 uses unsupported radio %2.", _context, _class]};
    private _all = _occurrence isEqualType "" && {toUpper _occurrence == "ALL"};
    if !(_all || {_occurrence isEqualType 0 && {_occurrence >= 1} && {_occurrence == floor _occurrence}}) then {_errors pushBack format ["%1/%2 scope must be ALL or an occurrence number of 1 or greater.", _context, _class]};
    if !(([_ear] call _normaliseEar) in ["LEFT", "RIGHT", "CENTER"]) then {_errors pushBack format ["%1/%2 has invalid ear %3.", _context, _class, _ear]};
    private _mode = toUpper (_profile select 1);
    private _resolved = _target;
    if (_target isEqualType "") then {
        private _net = _netMap getOrDefault [toUpper _target, []];
        if (count _net == 0) exitWith {_errors pushBack format ["%1 references unknown net %2.", _context, _target]};
        if (toUpper (_net select 2) != toUpper (_profile select 5)) exitWith {_errors pushBack format ["%1 cannot assign %2 to %3: net family %4 does not match radio family %5.", _context, _target, _class, _net select 2, _profile select 5]};
        _resolved = _net select 3;
    };
    if (_mode == "BLOCK_CHANNEL" && {!(_allowAutomatic343 && {_resolved isEqualTo []})} && {!(_resolved isEqualType [] && {count _resolved == 2} && {(_resolved select 0) >= 1} && {(_resolved select 0) <= _max343Block} && {(_resolved select 1) >= 1} && {(_resolved select 1) <= 16})}) then {_errors pushBack format ["%1 PRC-343 target must be [] for callsign inference or [block 1-%2, channel 1-16].", _context, _max343Block]};
    if (_mode == "CHANNEL" && {!(_resolved isEqualType 0 && {_resolved >= 1} && {_resolved <= (_profile select 3)} && {_resolved == floor _resolved})}) then {_errors pushBack format ["%1/%2 channel %3 is outside this radio's supported range 1-%4.", _context, _class, _resolved, _profile select 3]};
    if (_mode == "FREQUENCY" && {!([_resolved, _profile select 4] call _frequencyValid)}) then {_errors pushBack format ["%1/%2 has invalid frequency %3.", _context, _class, _resolved]};
};
{
    if (count _x != 4) then {_errors pushBack format ["Malformed side entry %1.", _x]} else {
        _x params ["_sourceSide", "_preset", "_nets", "_groups"];
        private _sideKey = [_sourceSide] call _normaliseSide;
        if !(_sideKey in ["WEST", "EAST", "GUER", "CIV"]) then {_errors pushBack format ["Invalid side %1.", _sourceSide]};
        if (_sideKey in _sideKeys) then {_errors pushBack format ["Duplicate side %1.", _sideKey]};
        _sideKeys pushBack _sideKey;
        if (_preset != (_expectedPresets getOrDefault [_sideKey, ""])) then {_errors pushBack format ["%1 must use official ACRE preset %2.", _sideKey, _expectedPresets getOrDefault [_sideKey, ""]]};
        private _netMap = createHashMap;
        private _sideTuningTargets = [];
        {
            if (count _x != 4) then {_errors pushBack format ["Malformed %1 net %2; expected [key, display name, radio family, one value].", _sideKey, _x]} else {
                _x params ["_netKey", "_label", "_family", "_value"];
                private _key = toUpper _netKey;
                if !((_netMap getOrDefault [_key, []]) isEqualTo []) then {_errors pushBack format ["Duplicate %1 net %2.", _sideKey, _key]};
                if (count _label > 12) then {_warnings pushBack format ["%1/%2 physical label will be truncated to 12 characters.", _sideKey, _key]};
                private _upperFamily = toUpper _family;
                if !(_upperFamily in _profileFamilies) then {_errors pushBack format ["%1/%2 uses unknown radio family %3.", _sideKey, _key, _family]};
                private _tuningIdentity = format ["%1#%2", _upperFamily, _value];
                if (_tuningIdentity in _sideTuningTargets) then {_errors pushBack format ["%1 reuses %2 in multiple named nets, so current-net highlighting would be ambiguous.", _sideKey, _tuningIdentity]};
                _sideTuningTargets pushBack _tuningIdentity;
                _netMap set [_key, [_key, _label, _upperFamily, _value]];
                private _familyProfiles = _profiles select {toUpper (_x select 5) == _upperFamily};
                private _netMax343Block = if (_policy == "FULL_RANGE" || {_preset == "default"}) then {16} else {5};
                if (count _familyProfiles > 0 && {_familyProfiles findIf {[_value, _x, _netMax343Block] call _profileAcceptsValue} < 0}) then {
                    _errors pushBack format ["%1/%2 value %3 is unsupported by every radio in family %4.", _sideKey, _key, _value, _upperFamily];
                };
            };
        } forEach _nets;
        private _groupKeys = [];
        private _used343 = [];
        private _maxBlock = if (_policy == "FULL_RANGE" || {_preset == "default"}) then {16} else {5};
        {
            if (count _x != 2) then {_errors pushBack format ["Malformed %1 group %2; expected [group ID, assignment rows].", _sideKey, _x]} else {
                _x params ["_groupId", "_assignments"];
                private _groupKey = toUpperANSI (((_groupId splitString " -_.") joinString ""));
                if (_groupKey in _groupKeys) then {_errors pushBack format ["Duplicate %1 group %2.", _sideKey, _groupKey]};
                _groupKeys pushBack _groupKey;
                private _identities = [];
                private _group343Slots = [];
                {
                    private _scope = _x param [1, 0];
                    if (_scope isEqualType "") then {_scope = toUpper _scope};
                    private _identity = format ["%1#%2", toUpper (_x param [0, ""]), _scope];
                    if (_identity in _identities) then {_errors pushBack format ["%1/%2 duplicates %3.", _sideKey, _groupKey, _identity]};
                    _identities pushBack _identity;
                    [_x, format ["%1/%2/%3", _sideKey, _groupKey, _identity], _netMap, _maxBlock, true] call _validateAssignment;
                    if (toUpper (_x param [0, ""]) == "ACRE_PRC343" && {(_x param [2, []]) isEqualType []} && {count (_x param [2, []]) == 2}) then {
                        private _target = _x select 2;
                        private _flat = ((_target select 0) - 1) * 16 + (_target select 1);
                        _group343Slots pushBackUnique _flat;
                    };
                } forEach _assignments;
                {
                    if (_x in _used343) then {
                        private _block = floor ((_x - 1) / 16) + 1;
                        private _channel = ((_x - 1) mod 16) + 1;
                        private _message = format ["%1 explicit PRC-343 collision at Block %2, Channel %3.", _sideKey, _block, _channel];
                        if (_strict) then {_errors pushBack _message} else {_warnings pushBack _message};
                    };
                    _used343 pushBackUnique _x;
                } forEach _group343Slots;
            };
        } forEach _groups;
        _sideData set [_sideKey, [_netMap, _maxBlock]];
    };
} forEach (_config getOrDefault ["sides", []]);
{
    if (count _x != 4 || {count (_x select 1) != 2}) then {_errors pushBack format ["Malformed radio override %1.", _x]} else {
        _x params ["_sourceSide", "_selector", "_mode", "_assignments"];
        private _sideKey = [_sourceSide] call _normaliseSide;
        private _data = _sideData getOrDefault [_sideKey, []];
        if (count _data == 0) then {_errors pushBack format ["Override references unknown side %1.", _sourceSide]} else {
            if !(toUpper (_selector select 0) in ["UID", "VARIABLE", "ROLE"]) then {_errors pushBack format ["Invalid override selector %1.", _selector select 0]};
            if !(toUpper _mode in ["MERGE", "REPLACE"]) then {_errors pushBack format ["Override mode must be MERGE or REPLACE, not %1.", _mode]};
            {[_x, format ["override %1/%2", _sideKey, _selector select 1], _data select 0, _data select 1] call _validateAssignment} forEach _assignments;
        };
    };
} forEach (_config getOrDefault ["radioOverrides", []]);
private _babel = _config getOrDefault ["babel", createHashMap];
{
    _x params ["_key", "_default"];
    if !((_babel getOrDefault [_key, _default]) isEqualType true) then {_errors pushBack format ["Babel %1 must be true or false.", _key]};
} forEach [["enabled", false], ["changeOnSideChange", false], ["followPlayerUnit", true]];
private _languageIds = [];
{
    if (count _x != 2 || {(_x select 0) == ""} || {(_x select 1) == ""}) then {_errors pushBack format ["Malformed Babel language %1.", _x]} else {
        if ((_x select 0) in _languageIds) then {_errors pushBack format ["Duplicate Babel language %1.", _x select 0]};
        _languageIds pushBack (_x select 0);
    };
} forEach (_babel getOrDefault ["languages", []]);
{
    if (count _x != 3) then {_errors pushBack format ["Malformed Babel side default %1.", _x]} else {
        {if !(_x in _languageIds) then {_errors pushBack format ["Babel default references unknown language %1.", _x]}} forEach (_x select 1);
        if !((_x select 2) in (_x select 1)) then {_errors pushBack format ["Babel %1 speaking language must be understood.", _x select 0]};
    };
} forEach (_babel getOrDefault ["sideDefaults", []]);
{
    if (count _x != 3 || {count (_x select 0) != 2}) then {_errors pushBack format ["Malformed Babel unit override %1.", _x]} else {
        private _selectorType = toUpper ((_x select 0) select 0);
        if !(_selectorType in ["UID", "VARIABLE", "VARIABLENAME"]) then {
            _errors pushBack format ["Invalid Babel selector %1; use UID, VARIABLENAME or VARIABLE.", _selectorType]
        };
        {if !(_x in _languageIds) then {_errors pushBack format ["Babel override references unknown language %1.", _x]}} forEach (_x select 1);
        if !((_x select 2) in (_x select 1)) then {_errors pushBack "Babel override speaking language must be understood."};
    };
} forEach (_babel getOrDefault ["unitOverrides", []]);
[count _errors == 0, _errors, _warnings]
