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
    private _nets = _sourceNets apply {
        [toUpper (_x select 0), _x select 1, (_x select 2) apply {[toUpper (_x select 0), _x select 1]}]
    };
    private _maxBlock = if (toUpper (_config getOrDefault ["prc343PresetPolicy", "FULL_RANGE"]) == "FULL_RANGE" || {_preset == "default"}) then {16} else {5};
    private _capacity = _maxBlock * 16;
    private _used = [];
    private _autoKeys = [];
    private _allocations = createHashMap;
    {
        _x params ["_groupId", "_netKeys", "_fallback343", "_assignments"];
        private _explicit343 = _assignments select {toUpper (_x select 0) == "ACRE_PRC343" && {(_x select 2) isEqualType []}};
        if (count _explicit343 > 0) then {
            {private _target = _x select 2; _used pushBackUnique (((_target select 0) - 1) * 16 + (_target select 1))} forEach _explicit343;
            _allocations set [toUpper _groupId, +((_explicit343 select 0) select 2)];
        } else {
            if !(_fallback343 isEqualTo []) then {
                _used pushBackUnique (((_fallback343 select 0) - 1) * 16 + (_fallback343 select 1));
                _allocations set [toUpper _groupId, +_fallback343];
            } else {
                _autoKeys pushBack (toUpper _groupId);
            };
        };
    } forEach _sourceGroups;
    _autoKeys sort true;
    {
        private _groupKey = _x;
        private _matches = _groupKey regexFind ["[0-9]+"];
        private _numbers = _matches apply {parseNumber (((_x select 0) select 0))};
        private _candidate = -1;
        if (count _numbers >= 2) then {
            private _block = _numbers select ((count _numbers) - 2);
            private _channel = _numbers select ((count _numbers) - 1);
            if (_block >= 1 && {_block <= _maxBlock} && {_channel >= 1} && {_channel <= 16}) then {_candidate = (_block - 1) * 16 + _channel};
        };
        if (_candidate < 1 && {count _numbers == 1} && {(_numbers select 0) >= 1} && {(_numbers select 0) <= 16}) then {
            private _prefixMatches = _groupKey regexFind ["^[^0-9]+"];
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
        _x params ["_groupId", "_netKeys", "_unused343", "_assignments"];
        private _normalisedAssignments = _assignments apply {
            private _ear = toUpper (_x select 3);
            if (_ear == "BOTH") then {_ear = "CENTER"};
            [toUpper (_x select 0), _x select 1, _x select 2, _ear]
        };
        [toUpper _groupId, _netKeys apply {toUpper _x}, _allocations getOrDefault [toUpper _groupId, []], _normalisedAssignments]
    };
    _sidePlans pushBack [_sideKey, _preset, _nets, _groups];
} forEach (_config getOrDefault ["sides", []]);
[3, _revision, _sidePlans, _diagnostics]
