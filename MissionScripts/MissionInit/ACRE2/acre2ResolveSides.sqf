/*
 * Author: WaldoTheWarfighter
 * Resolves the "INHERIT:<SIDE>" nets sentinel in MissionConfig\acreConfig.sqf's "sides" array into a
 * literal nets array, before validation or anything else reads the config. This lets a mission maker
 * fold multiple sides onto one identical channel set with one line per side - point a side's nets at
 * another side's by name - instead of copy-pasting (and risking drift in) an identical nets array into
 * every sharing side's own row. Deliberately non-transitive: the referenced side's own nets must
 * already be a literal array, not another "INHERIT:..." string - this single check rejects
 * self-reference, cycles and inheritance chains all at once with no graph-walk.
 *
 * Arguments:
 * 0: configuration <HASHMAP>
 *
 * Return Value: ARRAY - [resolvedConfig <HASHMAP>, errors <ARRAY of STRING>]. resolvedConfig is always
 * returned, even when errors is non-empty: a side with an invalid inheritance reference resolves to an
 * empty nets array (a safe, well-defined state) rather than leaving the raw sentinel string in place
 * for a downstream consumer to choke on.
 *
 * Example: private _resolution = [_config] call Waldo_fnc_ACRE2ResolveSides;
 * Current callers: Waldo_fnc_ACRE2PreInit and Waldo_fnc_ACRE2Init, before Waldo_fnc_ACRE2ValidateConfig.
 */
params [["_config", createHashMap, [createHashMap]]];
private _errors = [];
private _sides = _config getOrDefault ["sides", []];
private _normaliseSide = {
    params ["_value"];
    switch (toUpper _value) do {
        case "BLUFOR"; case "WEST": {"WEST"}; case "OPFOR"; case "EAST": {"EAST"};
        case "INDEPENDENT"; case "INDEP"; case "GUER": {"GUER"}; case "CIVILIAN"; case "CIV": {"CIV"};
        default {toUpper _value};
    }
};
// Side-key -> raw row lookup, built first, so a side may inherit from another side regardless of
// which one is defined earlier in the array.
private _rowsByKey = createHashMap;
{
    if (_x isEqualType [] && {count _x == 4} && {(_x select 0) isEqualType ""}) then {
        _rowsByKey set [[_x select 0] call _normaliseSide, _x];
    };
} forEach _sides;
private _resolvedSides = [];
{
    if !(_x isEqualType [] && {count _x == 4}) then {
        _resolvedSides pushBack _x; // malformed row shape - left as-is; the existing validator rejects it with its own clear error.
    } else {
        _x params ["_sourceSide", "_preset", "_nets", "_groups"];
        private _sideKey = [_sourceSide] call _normaliseSide;
        if (_nets isEqualType "") then {
            private _sentinelValid = (count _nets > 8) && {(toUpper (_nets select [0, 8])) == "INHERIT:"};
            if !(_sentinelValid) then {
                _errors pushBack format ['%1 has an invalid nets value %2 - expected an array of net rows, or "INHERIT:<SIDE>".', _sideKey, _nets];
                _nets = [];
            } else {
                private _targetKey = [(_nets select [8, (count _nets) - 8])] call _normaliseSide;
                private _targetRow = _rowsByKey getOrDefault [_targetKey, []];
                if (count _targetRow != 4) then {
                    _errors pushBack format ["%1 inherits nets from unknown side %2.", _sideKey, _targetKey];
                    _nets = [];
                } else {
                    private _targetNets = _targetRow select 2;
                    private _targetPreset = _targetRow select 1;
                    if !(_targetNets isEqualType []) then {
                        _errors pushBack format ["%1 inherits nets from %2, but %2's own nets are not a literal array - inherit directly from the side that defines them (chained inheritance is not supported).", _sideKey, _targetKey];
                        _nets = [];
                    } else {
                        if (_preset != _targetPreset) then {
                            _errors pushBack format ["%1 inherits nets from %2 but uses a different preset (%3 vs %4) - give both sides the same preset, or the inherited channel numbers won't actually be the same frequency.", _sideKey, _targetKey, _preset, _targetPreset];
                            _nets = [];
                        } else {
                            _nets = +_targetNets; // a copy, not a shared reference - each resolved side owns its own array.
                        };
                    };
                };
            };
        };
        _resolvedSides pushBack [_sourceSide, _preset, _nets, _groups];
    };
} forEach _sides;
private _resolvedConfig = +_config;
_resolvedConfig set ["sides", _resolvedSides];
[_resolvedConfig, _errors]
