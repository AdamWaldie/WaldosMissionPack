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
    if !(_x isEqualType [] && {count _x == 6}) then {_errors pushBack format ["Malformed radio profile %1; expected [class, mode, ears, maximum channel, frequency range, net family].", _x]} else {
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
// PASS 1: side identity + named nets only. Groups/assignments are deliberately validated in a later
// pass (below jointNets) instead of inline here, so a group's assignment row can target a joint net
// by its own netId exactly like an ordinary named net - jointNets' per-side channel gets merged into
// this same _netMap before any assignment row is ever checked against it. _groups is stashed
// unvalidated in _sideData for that later pass to pick up.
{
    if !(_x isEqualType [] && {count _x == 4}) then {_errors pushBack format ["Malformed side entry %1; expected [side, official preset, nets, groups] - if you only have one side, make sure it is still wrapped in its own array inside sides' outer array.", _x]} else {
        _x params ["_sourceSide", "_preset", "_nets", "_groups"];
        private _sideKey = [_sourceSide] call _normaliseSide;
        if !(_sideKey in ["WEST", "EAST", "GUER", "CIV"]) then {_errors pushBack format ["Invalid side %1.", _sourceSide]};
        if (_sideKey in _sideKeys) then {_errors pushBack format ["Duplicate side %1.", _sideKey]};
        _sideKeys pushBack _sideKey;
        // A side's preset must be one of the four known official ACRE presets, but not necessarily
        // its OWN official one - two or more sides deliberately sharing a preset (and, via "sides"'
        // nets field, the same channel list) is how a mission maker folds them onto one identical
        // channel set for full cross-side comms. See MissionConfig\acreConfig.sqf's own guide.
        if !(_preset in (values _expectedPresets)) then {_errors pushBack format ["%1 must use one of the known official ACRE presets: %2.", _sideKey, values _expectedPresets]};
        private _netMap = createHashMap;
        private _sideTuningTargets = [];
        {
            if !(_x isEqualType [] && {count _x == 4}) then {_errors pushBack format ["Malformed %1 net %2; expected [key, display name, radio family, one value] - if this side only has one net, make sure it is still wrapped in its own array inside nets' outer array.", _sideKey, _x]} else {
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
        private _maxBlock = if (_policy == "FULL_RANGE" || {_preset == "default"}) then {16} else {5};
        _sideData set [_sideKey, [_netMap, _maxBlock, _groups]];
    };
} forEach (_config getOrDefault ["sides", []]);
// jointNets: ["netId", "label", "family", frequency, [[sideKey, channel], ...]]. Row shape mirrors an
// ordinary named net's [key, label, family, value] - label right after the id, same position, same
// meaning - with the per-side channel list appended after. "" means no label. Frequency is what's
// actually shared across sides; channel numbers stay per-side since they only mean something on that
// side's own preset. The label is written to the physical radio exactly like an ordinary named net's
// label (PRC_LR only, 12-char safe-charset truncation) - see Waldo_fnc_ACRE2ApplyJointNets. A collision
// with an ordinary named net on the same side/channel is always an error, not strict-gated, since that
// would silently misroute a real operational net onto the bridge; a joint net that wants a label uses
// its own label field instead of that workaround. netId is also a real lookup key now, not just a
// diagnostics label: each accepted [side, channel] entry below merges an entry keyed on netId into
// that side's own _netMap (built in PASS 1 above), so a group's assignment rows can target a joint net
// by name - ["ACRE_PRC152", "ALL", "GAME_CONTROL", "RIGHT"] - exactly like an ordinary named net,
// instead of only the raw channel number. Waldo_fnc_ACRE2CompilePlan performs the equivalent merge at
// apply time so the same lookup resolves for real, not just at validation.
private _usedJointSlots = [];
private _usedJointNetIds = [];
{
    // Check the row's own type before touching `count _x`: a mission maker with only one joint
    // net can easily paste that single row directly as jointNets' value, forgetting the outer
    // array wrapping every other row-list setting in this file expects. That flattens the row
    // into jointNets' top level, so _x here becomes each of the row's own fields in turn (a
    // string, then eventually a frequency Number) rather than the row itself - and `count` on a
    // Number is a hard Arma runtime error, not a caught validation failure. Guarding the type
    // first turns that into an ordinary, readable error message instead of a mission-start crash.
    if !(_x isEqualType [] && {count _x == 5}) then {_errors pushBack format ["Malformed joint net %1; expected [netId, label, radio family, shared frequency, [[side, channel], ...]] - if you only have one joint net, make sure it is still wrapped in its own array inside jointNets' outer array.", _x];} else {
        _x params ["_netId", "_label", "_family", "_frequency", "_sideChannels"];
        if (_netId == "" || !(_netId isEqualType "")) then {_errors pushBack format ["Joint net %1 requires a non-empty string id.", _x]};
        if (toUpper _netId in _usedJointNetIds) then {_errors pushBack format ["Duplicate joint net id %1 - each jointNets row needs its own unique netId, now that it also doubles as a lookup key for assignment rows.", _netId]};
        _usedJointNetIds pushBack (toUpper _netId);
        if !(_label isEqualType "") then {_errors pushBack format ['Joint net %1 label must be a string ("" for none).', _netId]};
        if (count _label > 12) then {_warnings pushBack format ["Joint net %1 label will be truncated to 12 characters.", _netId]};
        private _upperFamily = toUpper _family;
        if !(_upperFamily in _profileFamilies) then {_errors pushBack format ["Joint net %1 uses unknown radio family %2.", _netId, _family]};
        private _familyProfiles = _profiles select {toUpper (_x select 5) == _upperFamily};
        // jointNets' [side, channel] model only makes sense for CHANNEL-mode families (PRC_LR, BF888,
        // SEM52): a channel there is the same per-side preset slot index the ordinary nets system
        // already uses. BLOCK_CHANNEL (PRC343) needs a [block, channel] pair, not a bare number, and
        // FREQUENCY-mode families (LEGACY_VHF/PRC-77/SEM70) have no channel concept at all - their
        // preset "value" IS the raw frequency (see VHF_COMMON above) - so a plain channel number here
        // would either be rejected as an out-of-range frequency or, worse, silently fail to write
        // anything if it happened to parse as a valid frequency (their maximum channel is 0). Reject
        // both explicitly with a clear reason instead of a confusing generic range error.
        private _familyIsChannelMode = count _familyProfiles > 0 && {(_familyProfiles select 0) select 1 == "CHANNEL"};
        if (count _familyProfiles > 0 && {!_familyIsChannelMode}) then {
            _errors pushBack format ["Joint net %1 uses radio family %2, which is not CHANNEL-mode; jointNets v1 only supports CHANNEL-mode families such as PRC_LR, BF888 or SEM52.", _netId, _family];
        };
        // _frequency is a raw MHz value written directly to the chosen channel's frequencyTX/RX
        // fields (see Waldo_fnc_ACRE2ApplyJointNets), not a channel index - it must never be run
        // through _profileAcceptsValue's CHANNEL case, which validates a whole-number channel index
        // against that radio's channel COUNT (1-32/100/etc). Doing so here was a real bug: any
        // frequency with a fractional/kHz component - the normal case for ACRE2 tuning, and true of
        // the shipped 45.500 MHz example - failed the whole-number check outright; only a frequency
        // that happened to be a whole number within a family member's channel count (e.g. exactly
        // 50 MHz, since PRC-152/117F support up to 100) could pass by pure numeric coincidence, with
        // no relation to whether that frequency is actually valid radio hardware. CHANNEL-mode radio
        // profiles carry no documented frequency band ([] in this file's own
        // profile table - only FREQUENCY-mode profiles like LEGACY_VHF define one), so there is no
        // authoritative range to check here. ACRE2's own acre_api_fnc_setPresetChannelField performs
        // no validation of its own on this value either (confirmed against its source: it checks the
        // channel number is in range and the field name is recognised, then stores whatever is given
        // unconditionally) - so this positive-number check is the only guard against a bad frequency
        // anywhere in the pipeline, not a backstop-plus-typo-catch. It only catches an obviously wrong
        // value (non-numeric, zero, negative); a plausible-looking but wrong MHz figure is accepted
        // and written exactly as given, same as every other numeric setting in this file.
        if (_familyIsChannelMode && {!(_frequency isEqualType 0 && {_frequency > 0})}) then {
            _errors pushBack format ["Joint net %1 frequency %2 must be a positive number in MHz.", _netId, _frequency];
        };
        if !(_sideChannels isEqualType [] && {count _sideChannels > 0}) then {_errors pushBack format ["Joint net %1 requires at least one [side, channel] entry.", _netId];} else {
            {
                if !(_x isEqualType [] && {count _x == 2}) then {_errors pushBack format ["Joint net %1 has malformed side/channel entry %2; expected [side, channel].", _netId, _x];} else {
                    _x params ["_sourceSide", "_channel"];
                    private _sideKey = [_sourceSide] call _normaliseSide;
                    if !(_sideKey in _sideKeys) then {_errors pushBack format ["Joint net %1 references side %2, which is not defined in sides.", _netId, _sourceSide];} else {
                        private _sideEntry = _sideData getOrDefault [_sideKey, []];
                        private _sideMaxBlock = if (count _sideEntry >= 2) then {_sideEntry select 1} else {16};
                        if (_familyIsChannelMode && {_familyProfiles findIf {[_channel, _x, _sideMaxBlock] call _profileAcceptsValue} < 0}) then {
                            _errors pushBack format ["Joint net %1/%2 channel %3 is out of range for radio family %4.", _netId, _sideKey, _channel, _family];
                        };
                        private _slotIdentity = format ["%1#%2#%3", _sideKey, _upperFamily, _channel];
                        // A slot already claimed by an earlier joint net is reported once, right here,
                        // with its own specific message - the generic ordinary-net collision check just
                        // below is skipped for it. _sideEntryNets now also carries every joint net
                        // merged in by an earlier iteration of this same loop (see the merge at the
                        // bottom), so without this guard the same reused slot would additionally trip
                        // that check and misreport a joint net as an "ordinary named net".
                        private _slotAlreadyJoint = _slotIdentity in _usedJointSlots;
                        if (_slotAlreadyJoint) then {_errors pushBack format ["Joint net %1 reuses %2/%3 channel %4, already claimed by another joint net.", _netId, _sideKey, _family, _channel];};
                        _usedJointSlots pushBack _slotIdentity;
                        private _sideEntryNets = if (count _sideEntry >= 1) then {_sideEntry select 0} else {createHashMap};
                        if !(_slotAlreadyJoint) then {
                            private _collision = (keys _sideEntryNets) findIf {
                                private _net = _sideEntryNets get _x;
                                toUpper (_net select 2) == _upperFamily && {(_net select 3) isEqualTo _channel}
                            };
                            if (_collision >= 0) then {
                                _errors pushBack format ["Joint net %1/%2 channel %3 collides with the ordinary named net %4 already using that channel/family.", _netId, _sideKey, _channel, (_sideEntryNets get ((keys _sideEntryNets) select _collision)) select 0];
                            };
                        };
                        // Merge this side's resolved channel into its own _netMap under the joint
                        // net's id, so PASS 2 below (groups/assignments) can resolve it by name. A
                        // joint net's id landing on an already-used ordinary net key would otherwise
                        // silently shadow one or the other depending on lookup order - reject it
                        // explicitly instead. This can only ever match a genuine ordinary net, never
                        // another joint net's merged entry, since netId is already checked unique
                        // across every jointNets row before this per-side loop even runs.
                        if (count (_sideEntryNets getOrDefault [toUpper _netId, []]) > 0) then {
                            _errors pushBack format ["Joint net %1's id is already used as an ordinary net key on side %2 - rename one of them.", _netId, _sideKey];
                        } else {
                            _sideEntryNets set [toUpper _netId, [_netId, _label, _upperFamily, _channel]];
                        };
                    };
                };
            } forEach _sideChannels;
        };
    };
} forEach (_config getOrDefault ["jointNets", []]);
// PASS 2: groups/assignments, now that jointNets have merged their per-side channel into each side's
// _netMap above. An assignment row can therefore target a joint net by its own netId exactly like an
// ordinary named net - Waldo_fnc_ACRE2CompilePlan performs the equivalent merge so this also resolves
// for real at apply time, not just here. Iterates (keys _sideData) rather than _sideKeys so a
// mission-maker mistake that defines the same side twice (already reported above as "Duplicate side")
// validates that side's groups exactly once, against the one entry _sideData actually kept, instead
// of processing it twice while never validating the discarded duplicate's own groups at all.
{
    private _sideKey = _x;
    private _sideEntry = _sideData get _sideKey;
    _sideEntry params ["_netMap", "_maxBlock", "_groups"];
    private _groupKeys = [];
    private _used343 = [];
    {
        if !(_x isEqualType [] && {count _x == 2}) then {_errors pushBack format ["Malformed %1 group %2; expected [group ID, assignment rows] - if this side only has one group, make sure it is still wrapped in its own array inside groups' outer array.", _sideKey, _x]} else {
            _x params ["_groupId", "_assignments"];
            private _groupKey = toUpperANSI (((_groupId splitString " -_.") joinString ""));
            if (_groupKey in _groupKeys) then {_errors pushBack format ["Duplicate %1 group %2.", _sideKey, _groupKey]};
            _groupKeys pushBack _groupKey;
            private _identities = [];
            private _group343Slots = [];
            private _allClasses = [];
            private _numberedClasses = [];
            {
                private _scope = _x param [1, 0];
                if (_scope isEqualType "") then {_scope = toUpper _scope};
                private _class = toUpper (_x param [0, ""]);
                if (_scope isEqualType "" && {_scope == "ALL"}) then {
                    if (_class in _numberedClasses) then {_errors pushBack format ["%1/%2 mixes ALL and numbered rows for %3; use ALL alone or number every occurrence.", _sideKey, _groupKey, _class]};
                    _allClasses pushBackUnique _class;
                } else {
                    if (_class in _allClasses) then {_errors pushBack format ["%1/%2 mixes ALL and numbered rows for %3; use ALL alone or number every occurrence.", _sideKey, _groupKey, _class]};
                    _numberedClasses pushBackUnique _class;
                };
                private _identity = format ["%1#%2", _class, _scope];
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
} forEach (keys _sideData);
{
    if !(_x isEqualType [] && {count _x == 4} && {(_x select 1) isEqualType [] && {count (_x select 1) == 2}}) then {_errors pushBack format ["Malformed radio override %1; expected [side, selector, mode, assignment rows] - if you only have one override, make sure it is still wrapped in its own array inside radioOverrides' outer array.", _x]} else {
        _x params ["_sourceSide", "_selector", "_mode", "_assignments"];
        private _sideKey = [_sourceSide] call _normaliseSide;
        private _data = _sideData getOrDefault [_sideKey, []];
        if (count _data == 0) then {_errors pushBack format ["Override references unknown side %1.", _sourceSide]} else {
            if !(toUpper (_selector select 0) in ["UID", "VARIABLE", "ROLE"]) then {_errors pushBack format ["Invalid override selector %1.", _selector select 0]};
            if !(toUpper _mode in ["MERGE", "REPLACE"]) then {_errors pushBack format ["Override mode must be MERGE or REPLACE, not %1.", _mode]};
            if (toUpper _mode == "MERGE" && {_assignments findIf {!((_x param [1, 0]) isEqualType "" && {toUpper (_x select 1) == "ALL"})} >= 0}) then {_errors pushBack "MERGE radio overrides may use only ALL rows; use REPLACE with a complete numbered list when duplicate radios differ."};
            {[_x, format ["override %1/%2", _sideKey, _selector select 1], _data select 0, _data select 1] call _validateAssignment} forEach _assignments;
        };
    };
} forEach (_config getOrDefault ["radioOverrides", []]);
private _rackCompatibility = createHashMapFromArray [
    ["ACRE_VRC64", "ACRE_PRC77"], ["ACRE_VRC103", "ACRE_PRC117F"],
    ["ACRE_VRC110", "ACRE_PRC152"], ["ACRE_VRC111", "ACRE_PRC148"],
    ["ACRE_SEM90", "ACRE_SEM70"]
];
private _rackProfileNames = [];
{
    if !(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""}) then {
        _errors pushBack format ["Malformed vehicle rack profile %1; expected [profile name, settings].", _x];
    } else {
        _x params ["_profileName", "_sourceSettings"];
        private _upperName = toUpper _profileName;
        if (_profileName == "") then {_errors pushBack "A vehicle rack profile name cannot be empty."};
        if (_upperName in _rackProfileNames) then {_errors pushBack format ["Duplicate vehicle rack profile %1.", _profileName]};
        _rackProfileNames pushBack _upperName;
        private _profilePairs = _sourceSettings;
        if (_profilePairs isEqualType createHashMap) then {
            private _converted = [];
            {_converted pushBack [_x, _profilePairs get _x]} forEach keys _profilePairs;
            _profilePairs = _converted;
        };
        if !(_profilePairs isEqualType [] && {{_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""}} count _profilePairs == count _profilePairs}) then {
            _errors pushBack format ["Vehicle rack profile %1 settings must be [key,value] rows.", _profileName];
        } else {
            private _rackSettings = createHashMapFromArray _profilePairs;
            private _preset = _rackSettings getOrDefault ["preset", ""];
            if !(_preset isEqualType "") then {_errors pushBack format ["Vehicle rack profile %1 preset must be a string.", _profileName]};
            private _netSide = [_rackSettings getOrDefault ["netSide", "AUTO"]] call _normaliseSide;
            if !(_netSide in ["AUTO", "WEST", "EAST", "GUER", "CIV"]) then {_errors pushBack format ["Vehicle rack profile %1 netSide must be AUTO, WEST, EAST, GUER or CIV.", _profileName]};
            private _addRacks = _rackSettings getOrDefault ["addRacks", []];
            private _assignments = _rackSettings getOrDefault ["assignments", []];
            if !(_addRacks isEqualType []) then {_errors pushBack format ["Vehicle rack profile %1 addRacks must be an array.", _profileName]} else {
                {
                    if !(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""}) then {
                        _errors pushBack format ["Vehicle rack profile %1 has malformed addRacks row %2.", _profileName, _x];
                    } else {
                        _x params ["_rackClass", "_sourceRack"];
                        private _upperRack = toUpper _rackClass;
                        if !(_upperRack in keys _rackCompatibility) then {_errors pushBack format ["Vehicle rack profile %1 uses unknown built-in rack %2.", _profileName, _rackClass]};
                        private _rackPairs = _sourceRack;
                        if (_rackPairs isEqualType createHashMap) then {
                            private _convertedRack = [];
                            {_convertedRack pushBack [_x, _rackPairs get _x]} forEach keys _rackPairs;
                            _rackPairs = _convertedRack;
                        };
                        if !(_rackPairs isEqualType [] && {{_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""}} count _rackPairs == count _rackPairs}) then {
                            _errors pushBack format ["Vehicle rack profile %1/%2 settings must be named [key,value] rows.", _profileName, _rackClass];
                        } else {
                            private _definition = createHashMapFromArray _rackPairs;
                            private _count = _definition getOrDefault ["count", 1];
                            private _shortName = _definition getOrDefault ["shortName", "RADIO"];
                            private _mounted = toUpper (_definition getOrDefault ["mountedRadio", ""]);
                            if !(_count isEqualType 0 && {_count >= 1} && {_count == floor _count}) then {_errors pushBack format ["Vehicle rack profile %1/%2 count must be a whole number of 1 or greater.", _profileName, _rackClass]};
                            if !(_shortName isEqualType "" && {count _shortName <= 4} && {_shortName != ""}) then {_errors pushBack format ["Vehicle rack profile %1/%2 shortName must contain 1-4 characters.", _profileName, _rackClass]};
                            private _expectedRadio = _rackCompatibility getOrDefault [_upperRack, ""];
                            if (_mounted != "" && {_mounted != _expectedRadio}) then {_errors pushBack format ["Vehicle rack profile %1/%2 cannot mount %3; use %4.", _profileName, _rackClass, _mounted, _expectedRadio]};
                            if !((_definition getOrDefault ["removable", true]) isEqualType true) then {_errors pushBack format ["Vehicle rack profile %1/%2 removable must be true or false.", _profileName, _rackClass]};
                            {if !((_definition getOrDefault [_x, []]) isEqualType []) then {_errors pushBack format ["Vehicle rack profile %1/%2 %3 must be an array.", _profileName, _rackClass, _x]}} forEach ["access", "disabled", "components", "intercoms"];
                        };
                    };
                } forEach _addRacks;
            };
            if !(_assignments isEqualType []) then {_errors pushBack format ["Vehicle rack profile %1 assignments must be an array.", _profileName]} else {
                {
                    if !(_x isEqualType [] && {count _x >= 2} && {count _x <= 3}) then {
                        _errors pushBack format ["Vehicle rack profile %1 has malformed assignment %2.", _profileName, _x];
                    } else {
                        private _selector = _x select 0;
                        private _selectorValid = (_selector isEqualType 0 && {_selector >= 1 && {_selector == floor _selector}}) || {(_selector isEqualType "" && {_selector != ""})} || {
                            _selector isEqualType [] && {count _selector == 2} && {(_selector select 0) isEqualType ""} && {(_selector select 1) isEqualType 0 && {(_selector select 1) >= 1}}
                        };
                        if (!_selectorValid) then {_errors pushBack format ["Vehicle rack profile %1 has invalid selector %2.", _profileName, _selector]};
                        private _target = _x select 1;
                        if !((_target isEqualType "" && {_target != ""}) || {_target isEqualType 0 && {(_target == -1) || {_target >= 1}}}) then {
                            _errors pushBack format ["Vehicle rack profile %1 selector %2 has invalid target %3; use a named net, channel 1 or greater, or -1.", _profileName, _selector, _target];
                        };
                        private _rawReplacement = _x param [2, ""];
                        if !(_rawReplacement isEqualType "") then {_errors pushBack format ["Vehicle rack profile %1 selector %2 radio action must be text.", _profileName, _selector]};
                        private _replacement = if (_rawReplacement isEqualType "") then {toUpper _rawReplacement} else {""};
                        if (_selector isEqualType "" && {toUpper _selector == "ALL"} && {_replacement != ""}) then {
                            _errors pushBack format ["Vehicle rack profile %1 cannot use selector ALL for radio/rack hardware action %2; select a rack class or occurrence.", _profileName, _replacement];
                        };
                        private _selectorClass = if (_selector isEqualType "" && {toUpper _selector != "ALL"}) then {toUpper _selector} else {if (_selector isEqualType []) then {toUpper (_selector select 0)} else {""}};
                        if (_selectorClass != "" && {_replacement != ""} && {!(_replacement in ["REMOVE_RACK", "UNMOUNT_RADIO"])}) then {
                            private _expectedRadio = _rackCompatibility getOrDefault [_selectorClass, ""];
                            if (_expectedRadio == "" || {_expectedRadio != _replacement}) then {_errors pushBack format ["Vehicle rack profile %1 selector %2 cannot mount %3.", _profileName, _selector, _replacement]};
                        };
                        if (_target isEqualType "" && {_selectorClass != ""}) then {
                            private _radioClass = if (_replacement != "" && {!(_replacement in ["REMOVE_RACK", "UNMOUNT_RADIO"])}) then {_replacement} else {_rackCompatibility getOrDefault [_selectorClass, ""]};
                            private _radioProfile = [_radioClass] call _profileFor;
                            if (_radioProfile isEqualTo []) then {
                                _errors pushBack format ["Vehicle rack profile %1 selector %2 cannot resolve named net %3 without a known compatible radio.", _profileName, _selector, _target];
                            } else {
                                private _candidateSides = if (_netSide == "AUTO") then {["WEST", "EAST", "GUER", "CIV"]} else {[_netSide]};
                                private _matches = 0;
                                {
                                    private _sideEntry = _sideData getOrDefault [_x, []];
                                    if !(_sideEntry isEqualTo []) then {
                                        private _net = (_sideEntry select 0) getOrDefault [toUpper _target, []];
                                        if !(_net isEqualTo []) then {
                                            if (toUpper (_net select 2) == toUpper (_radioProfile select 5)) then {_matches = _matches + 1};
                                        };
                                    };
                                } forEach _candidateSides;
                                if (_matches != 1) then {_errors pushBack format ["Vehicle rack profile %1 net %2 is missing, ambiguous or incompatible for %3 on netSide %4.", _profileName, _target, _radioClass, _netSide]};
                            };
                        };
                    };
                } forEach _assignments;
            };
        };
    };
} forEach (_config getOrDefault ["rackProfiles", []]);
private _babel = _config getOrDefault ["babel", createHashMap];
{
    _x params ["_key", "_default"];
    if !((_babel getOrDefault [_key, _default]) isEqualType true) then {_errors pushBack format ["Babel %1 must be true or false.", _key]};
} forEach [["enabled", false], ["changeOnSideChange", false], ["followPlayerUnit", true]];
private _languageIds = [];
{
    if !(_x isEqualType [] && {count _x == 2} && {(_x select 0) != ""} && {(_x select 1) != ""}) then {_errors pushBack format ["Malformed Babel language %1; expected [id, display name] - if you only have one language, make sure it is still wrapped in its own array inside languages' outer array.", _x]} else {
        if ((_x select 0) in _languageIds) then {_errors pushBack format ["Duplicate Babel language %1.", _x select 0]};
        _languageIds pushBack (_x select 0);
    };
} forEach (_babel getOrDefault ["languages", []]);
{
    if !(_x isEqualType [] && {count _x == 3}) then {_errors pushBack format ["Malformed Babel side default %1; expected [side, spoken languages, understood language] - if you only have one side default, make sure it is still wrapped in its own array inside sideDefaults' outer array.", _x]} else {
        {if !(_x in _languageIds) then {_errors pushBack format ["Babel default references unknown language %1.", _x]}} forEach (_x select 1);
        if !((_x select 2) in (_x select 1)) then {_errors pushBack format ["Babel %1 speaking language must be understood.", _x select 0]};
    };
} forEach (_babel getOrDefault ["sideDefaults", []]);
{
    if !(_x isEqualType [] && {count _x == 3} && {(_x select 0) isEqualType [] && {count (_x select 0) == 2}}) then {_errors pushBack format ["Malformed Babel unit override %1; expected [selector, spoken languages, understood language] - if you only have one override, make sure it is still wrapped in its own array inside unitOverrides' outer array.", _x]} else {
        private _selectorType = toUpper ((_x select 0) select 0);
        if !(_selectorType in ["UID", "VARIABLE", "VARIABLENAME"]) then {
            _errors pushBack format ["Invalid Babel selector %1; use UID, VARIABLENAME or VARIABLE.", _selectorType]
        };
        {if !(_x in _languageIds) then {_errors pushBack format ["Babel override references unknown language %1.", _x]}} forEach (_x select 1);
        if !((_x select 2) in (_x select 1)) then {_errors pushBack "Babel override speaking language must be understood."};
    };
} forEach (_babel getOrDefault ["unitOverrides", []]);
[count _errors == 0, _errors, _warnings]
