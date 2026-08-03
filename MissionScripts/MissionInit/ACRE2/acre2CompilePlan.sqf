/*
 * Author: WaldoTheWarfighter
 * Compiles the validated ACRE configuration into a versioned, network-safe side/group plan.
 * Explicit PRC-343 assignments are reserved first; remaining fallback assignments are deterministic.
 * Per-radio assignments are normalised but retain their same-type occurrence identity.
 *
 * Arguments:
 * 0: configuration <HASHMAP>
 * 1: revision <NUMBER>
 *
 * Return Value: ARRAY - [schema, revision, side plans, diagnostics].
 *
 * Example: private _plan = [_config, 1] call Waldo_fnc_ACRE2CompilePlan;
 * Current caller: server branch of Waldo_fnc_ACRE2Init.
 */
params [['_config', createHashMap, [createHashMap]], ['_revision', 1, [0]]];
private _sidePlans = [];
private _diagnostics = [];
{
    _x params ['_sideKey', '_preset', '_sourceNets', '_sourceGroups'];
    _sideKey = switch (toUpper _sideKey) do {case 'BLUFOR'; case 'WEST': {'WEST'}; case 'OPFOR'; case 'EAST': {'EAST'}; case 'INDEPENDENT'; case 'INDEP'; case 'GUER': {'GUER'}; default {'CIV'}};
    private _nets = [];
    {
        private _overrides = (_x select 2) apply {[toUpper (_x select 0), _x select 1]};
        _nets pushBack [toUpper (_x select 0), _x select 1, _forEachIndex + 1, _overrides];
    } forEach _sourceNets;
    private _used = [];
    private _max343Block = if (toUpper (_config getOrDefault ['prc343PresetPolicy', 'FULL_RANGE']) == 'FULL_RANGE' || {_preset == 'default'}) then {16} else {5};
    private _max343Flat = _max343Block * 16;
    {
        private _explicit = _x select 2;
        private _radioAssignments = _x select 3;
        private _explicitShort = _radioAssignments select {toUpper (_x select 0) == 'ACRE_PRC343' && {(_x select 2) isEqualType []}};
        if (count _explicitShort > 0) then {
            {
                private _target = _x select 2;
                _used pushBackUnique (((_target select 0) - 1) * 16 + (_target select 1));
            } forEach _explicitShort;
        } else {
            if !(_explicit isEqualTo []) then {_used pushBack (((_explicit select 0) - 1) * 16 + (_explicit select 1))};
        };
    } forEach _sourceGroups;
    private _prefixBlocks = createHashMap;
    private _groups = [];
    {
        _x params ['_groupId', '_netKeys', '_explicit', '_sourceAssignments'];
        private _assignment = +_explicit;
        if (_assignment isEqualTo []) then {
            private _upperId = toUpper _groupId;
            private _wordMatches = _upperId regexFind ['^[A-Z]+'];
            private _prefix = if (count _wordMatches > 0) then {((_wordMatches select 0) select 0) select 0} else {'GROUP'};
            private _numberMatches = _upperId regexFind ['[0-9]+'];
            private _numbers = _numberMatches apply {parseNumber (((_x select 0) select 0))};
            private _block = _prefixBlocks getOrDefault [_prefix, 0];
            if (_block == 0) then {
                _block = count _prefixBlocks + 1;
                _prefixBlocks set [_prefix, _block];
            };
            private _channel = if (count _numbers > 0) then {_numbers select (count _numbers - 1)} else {1};
            if (count _numbers > 1) then {_block = _numbers select (count _numbers - 2)};
            _block = (_block max 1) min _max343Block;
            _channel = (_channel max 1) min 16;
            private _flat = (_block - 1) * 16 + _channel;
            while {_flat in _used && {_flat <= _max343Flat}} do {_flat = _flat + 1};
            if (_flat > _max343Flat) then {
                _assignment = [_max343Block, 16];
                _diagnostics pushBack format ['%1/%2 has no free PRC-343 assignment.', _sideKey, _groupId];
            } else {
                _used pushBack _flat;
                _assignment = [floor ((_flat - 1) / 16) + 1, ((_flat - 1) mod 16) + 1];
            };
        };
        private _radioAssignments = _sourceAssignments apply {
            private _spatial = toUpper (_x select 3);
            if (_spatial == 'BOTH') then {_spatial = 'CENTER'};
            [toUpper (_x select 0), _x select 1, _x select 2, _spatial]
        };
        _groups pushBack [toUpper _groupId, _netKeys apply {toUpper _x}, _assignment, _radioAssignments];
    } forEach _sourceGroups;
    _sidePlans pushBack [toUpper _sideKey, _preset, _nets, _groups];
} forEach (_config getOrDefault ['sides', []]);
[2, _revision, _sidePlans, _diagnostics]
