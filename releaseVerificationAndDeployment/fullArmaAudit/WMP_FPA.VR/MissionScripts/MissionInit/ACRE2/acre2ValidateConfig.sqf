/*
 * Author: WaldoTheWarfighter
 * Validates the root ACRE2 configuration without mutating radios, presets or network state.
 * Strict mode rejects invalid PRC-343 assignments, duplicate net keys and collisions.
 *
 * Arguments:
 * 0: configuration <HASHMAP>
 *
 * Return Value: ARRAY - [valid <BOOL>, diagnostics <ARRAY>].
 *
 * Example: private _result = [_config] call Waldo_fnc_ACRE2ValidateConfig;
 * Current callers: Waldo_fnc_ACRE2PreInit and Waldo_fnc_ACRE2Init.
 */
params [['_config', createHashMap, [createHashMap]]];
private _errors = [];
if ((_config getOrDefault ['version', -1]) != 1) then {_errors pushBack 'Unsupported configuration version.'};
private _profiles = _config getOrDefault ['radioProfiles', []];
private _profileClasses = [];
{
    if (count _x < 3 || {!((_x select 1) in ['BLOCK_CHANNEL', 'CHANNEL', 'FREQUENCY'])}) then {
        _errors pushBack format ['Invalid radio profile: %1', _x];
    } else {
        private _class = toUpper (_x select 0);
        if (_class in _profileClasses) then {_errors pushBack format ['Duplicate radio profile %1.', _class]};
        _profileClasses pushBack _class;
    };
} forEach _profiles;
private _sideKeys = [];
{
    if (count _x < 4) then {
        _errors pushBack format ['Malformed side entry: %1', _x];
    } else {
        _x params ['_sideKey', '_preset', '_nets', '_groups'];
        _sideKey = toUpper _sideKey;
        if !(_sideKey in ['WEST', 'EAST', 'GUER', 'CIV']) then {_errors pushBack format ['Invalid side key %1.', _sideKey]};
        if (_sideKey in _sideKeys) then {_errors pushBack format ['Duplicate side key %1.', _sideKey]};
        _sideKeys pushBack _sideKey;
        private _netKeys = [];
        {
            if (count _x < 3) then {
                _errors pushBack format ['Malformed %1 net: %2', _sideKey, _x];
            } else {
                private _netKey = toUpper (_x select 0);
                if (_netKey in _netKeys) then {_errors pushBack format ['Duplicate %1 net key %2.', _sideKey, _netKey]};
                _netKeys pushBack _netKey;
            };
        } forEach _nets;
        private _assignments = [];
        private _groupKeys = [];
        {
            if (count _x < 3) then {
                _errors pushBack format ['Malformed %1 group: %2', _sideKey, _x];
            } else {
                private _groupKey = toUpper (_x select 0);
                if (_groupKey in _groupKeys) then {_errors pushBack format ['Duplicate %1 group %2.', _sideKey, _groupKey]};
                _groupKeys pushBack _groupKey;
                {if !((toUpper _x) in _netKeys) then {_errors pushBack format ['%1/%2 references unknown net %3.', _sideKey, _groupKey, _x]}} forEach (_x select 1);
                private _explicit = _x select 2;
                if !(_explicit isEqualTo []) then {
                    if (count _explicit != 2 || {(_explicit select 0) < 1} || {(_explicit select 0) > 16} || {(_explicit select 1) < 1} || {(_explicit select 1) > 16}) then {
                        _errors pushBack format ['%1/%2 has invalid PRC-343 assignment %3.', _sideKey, _groupKey, _explicit];
                    } else {
                        private _flat = ((_explicit select 0) - 1) * 16 + (_explicit select 1);
                        if (_flat in _assignments) then {_errors pushBack format ['%1 PRC-343 collision at %2.', _sideKey, _explicit]};
                        _assignments pushBack _flat;
                    };
                };
            };
        } forEach _groups;
    };
} forEach (_config getOrDefault ['sides', []]);
[count _errors == 0, _errors]
