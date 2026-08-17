/*
 * Author: WaldoTheWarfighter
 * Compiles validated ACRE settings into one network-safe side/group plan. Explicit
 * PRC-343 slots are reserved first; automatic slots are allocated in sorted callsign order using a
 * stable callsign hash and deterministic collision probing, never configuration order or clamping.
 * Locality and authority: call on the server. The returned pure-data plan is published as one
 * authoritative value by Waldo_fnc_ACRE2Init for existing clients and JIP.
 *
 * Arguments:
 * 0: configuration <HASHMAP>
 * 1: revision <NUMBER>
 *
 * Return Value: ARRAY - [schema, revision, side plans, diagnostics].
 *
 * Example: private _plan = [_config, 1] call Waldo_fnc_ACRE2CompilePlan;
 * Result: `_plan` contains deterministic side/group assignments plus compile diagnostics.
 * Current caller: server branch of Waldo_fnc_ACRE2Init.
 */
params [["_config", createHashMap, [createHashMap]], ["_revision", 1, [0]]];
private _sidePlans = [];
private _diagnostics = [];
private _normaliseGroupKey = {toUpperANSI (((_this splitString " -_.") joinString ""))};
// Mirrors Waldo_fnc_ACRE2ValidateConfig's own side normaliser - needed here to match each jointNets
// [side, channel] entry's raw side string against this loop's already-normalised _sideKey below.
private _normaliseJointSide = {
    switch (toUpper _this) do {
        case "BLUFOR"; case "WEST": {"WEST"}; case "OPFOR"; case "EAST": {"EAST"};
        case "INDEPENDENT"; case "INDEP"; case "GUER": {"GUER"}; case "CIVILIAN"; case "CIV": {"CIV"};
        default {toUpper _this};
    }
};
private _hashText = {
    params ["_text", "_modulus"];
    private _hash = 5381;
    {_hash = ((_hash * 33) + _x) mod _modulus} forEach toArray toUpper _text;
    _hash
};
{
    _x params ["_sourceSide", "_preset", "_sourceNets", "_sourceGroups"];
    private _sideKey = switch (toUpper _sourceSide) do {
        case "BLUFOR"; case "WEST": {"WEST"};
        case "OPFOR"; case "EAST": {"EAST"};
        case "INDEPENDENT"; case "INDEP"; case "GUER": {"GUER"};
        default {"CIV"};
    };
    // A named net has one value and one compatibility family. Radio profiles, not the mission
    // maker, define which physical radios belong to that family.
    private _nets = _sourceNets apply {[toUpper (_x select 0), _x select 1, toUpper (_x select 2), _x select 3]};
    // Merge each joint net's channel resolved for THIS side into the same _nets table, using the
    // identical [key, label, family, value] shape (key/family uppercased, matching the line above) -
    // so an assignment row can target a joint net by its own netId exactly like an ordinary named
    // net. Waldo_fnc_ACRE2ValidateConfig performs the equivalent merge before this ever runs, and
    // already guarantees (as a hard validation error otherwise) that a joint net's id can never
    // collide with this side's own net keys and that this side/channel/family combination is unique -
    // this loop can trust that and merge unconditionally rather than re-checking it.
    {
        _x params ["_netId", "_label", "_family", "_frequency", "_sideChannels"];
        private _matchIndex = _sideChannels findIf {((_x select 0) call _normaliseJointSide) == _sideKey};
        if (_matchIndex >= 0) then {
            _nets pushBack [toUpper _netId, _label, toUpper _family, (_sideChannels select _matchIndex) select 1];
        };
    } forEach (_config getOrDefault ["jointNets", []]);
    private _maxBlock = if (toUpper (_config getOrDefault ["prc343PresetPolicy", "FULL_RANGE"]) == "FULL_RANGE" || {_preset == "default"}) then {16} else {5};
    private _capacity = _maxBlock * 16;
    private _used = [];
    private _autoKeys = [];
    private _autoSources = createHashMap;
    private _allocations = createHashMap;
    {
        _x params ["_groupId", "_assignments"];
        private _shortRules = _assignments select {toUpper (_x select 0) == "ACRE_PRC343"};
        {
            private _target = _x select 2;
            if (_target isEqualType [] && {count _target == 2}) then {
                _used pushBackUnique (((_target select 0) - 1) * 16 + (_target select 1));
            };
        } forEach _shortRules;
        private _primaryIndex = _shortRules findIf {(_x select 1) isEqualType 0 && {(_x select 1) == 1}};
        if (_primaryIndex < 0) then {
            _primaryIndex = _shortRules findIf {
                (_x select 1) isEqualType "" && {toUpper (_x select 1) == "ALL"}
            };
        };
        if (_primaryIndex >= 0) then {
            private _target = (_shortRules select _primaryIndex) select 2;
            if (_target isEqualType [] && {count _target == 2}) then {
                _allocations set [_groupId call _normaliseGroupKey, +_target];
            } else {
                private _normalisedGroup = _groupId call _normaliseGroupKey;
                _autoKeys pushBack _normalisedGroup;
                // Matching deliberately ignores separators, but shorthand needs the original
                // callsign so `Viking 2-3` remains two numbers instead of becoming 23.
                _autoSources set [_normalisedGroup, _groupId];
            };
        };
    } forEach _sourceGroups;
    _autoKeys sort true;
    {
        private _groupKey = _x;
        private _allocationSource = _autoSources getOrDefault [_groupKey, _groupKey];
        private _matches = _allocationSource regexFind ["[0-9]+"];
        private _numbers = _matches apply {parseNumber (((_x select 0) select 0))};
        private _candidate = -1;
        if (count _numbers >= 2) then {
            private _block = _numbers select ((count _numbers) - 2);
            private _channel = _numbers select ((count _numbers) - 1);
            if (_block >= 1 && {_block <= _maxBlock} && {_channel >= 1} && {_channel <= 16}) then {_candidate = (_block - 1) * 16 + _channel};
        };
        if (_candidate < 1 && {count _numbers == 1} && {(_numbers select 0) >= 1} && {(_numbers select 0) <= 16}) then {
            private _prefixMatches = _allocationSource regexFind ["^[^0-9]+"];
            private _prefix = if (count _prefixMatches > 0) then {((_prefixMatches select 0) select 0) select 0} else {_groupKey};
            _candidate = ([_prefix, _maxBlock] call _hashText) * 16 + (_numbers select 0);
        };
        if (_candidate < 1 || {_candidate > _capacity}) then {_candidate = ([_groupKey, _capacity] call _hashText) + 1};
        private _start = _candidate;
        while {_candidate in _used} do {
            _candidate = (_candidate mod _capacity) + 1;
            if (_candidate == _start) exitWith {_candidate = -1};
        };
        if (_candidate < 1) then {
            _diagnostics pushBack format ["%1/%2 has no free PRC-343 slot.", _sideKey, _groupKey];
            _allocations set [_groupKey, [_maxBlock, 16]];
        } else {
            _used pushBack _candidate;
            _allocations set [_groupKey, [floor ((_candidate - 1) / 16) + 1, ((_candidate - 1) mod 16) + 1]];
        };
    } forEach _autoKeys;
    private _groups = _sourceGroups apply {
        _x params ["_groupId", "_assignments"];
        private _normalisedAssignments = _assignments apply {
            private _ear = toUpper (_x select 3);
            if (_ear == "BOTH") then {_ear = "CENTER"};
            private _scope = _x select 1;
            if (_scope isEqualType "") then {_scope = toUpper _scope};
            private _target = _x select 2;
            if (toUpper (_x select 0) == "ACRE_PRC343" && {_target isEqualTo []}) then {
                _target = +(_allocations getOrDefault [_groupId call _normaliseGroupKey, []]);
            };
            [toUpper (_x select 0), _scope, _target, _ear]
        };
        [_groupId call _normaliseGroupKey, _normalisedAssignments]
    };
    _sidePlans pushBack [_sideKey, _preset, _nets, _groups];
} forEach (_config getOrDefault ["sides", []]);
[5, _revision, _sidePlans, _diagnostics]
