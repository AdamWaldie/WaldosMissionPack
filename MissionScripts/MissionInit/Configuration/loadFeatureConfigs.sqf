/*
 * Author: WaldoTheWarfighter
 * Loads the pure-data feature config manifest and applies only the requested execution-locality
 * scope. Existing variables always win. SERVER entries may publish their retained/default value
 * for current clients and JIP; SHARED and PLAYER_LOCAL entries are never broadcast by this loader.
 * Aliases and conditional defaults preserve the few settings that depend on another configured
 * value or an optional CfgPatches dependency. Fallbacks preserve an older source-variable value
 * when present without making the pure-data files executable. This function starts no feature.
 *
 * Arguments:
 * 0: scope <STRING> - SHARED, SERVER or PLAYER_LOCAL.
 *
 * Return Value:
 * BOOL - true when every manifest/config entry was structurally valid and applied.
 *
 * Example:
 * ["SERVER"] call Waldo_fnc_LoadFeatureConfigs;
 *
 * Current callers: init.sqf, initServer.sqf and initPlayerLocal.sqf at their original config points.
 */
params [['_scope', '', ['']]];
_scope = toUpperANSI _scope;
if !(_scope in ['SHARED', 'SERVER', 'PLAYER_LOCAL']) exitWith {
    diag_log format ['[WMP CONFIG] Invalid feature-config scope: %1', _scope];
    false
};
if (_scope == 'SERVER' && {!isServer}) exitWith {false};
if (_scope == 'PLAYER_LOCAL' && {!hasInterface}) exitWith {false};

private _scopeKey = switch (_scope) do {
    case 'PLAYER_LOCAL': {'playerLocal'};
    case 'SERVER': {'server'};
    default {'shared'};
};
private _manifest = call compile preprocessFileLineNumbers 'MissionConfig\featureConfigManifest.sqf';
if !(_manifest isEqualType []) exitWith {
    diag_log '[WMP CONFIG] featureConfigManifest.sqf did not return an ARRAY.';
    false
};

private _valid = true;
{
    private _path = _x;
    if !(_path isEqualType '') then {
        diag_log format ['[WMP CONFIG] Non-string manifest entry: %1', _path];
        _valid = false;
    } else {
        private _config = call compile preprocessFileLineNumbers _path;
        if !(_config isEqualType createHashMap) then {
            diag_log format ['[WMP CONFIG] %1 did not return a HASHMAP.', _path];
            _valid = false;
        } else {
            {
                if !(_x isEqualType [] && {count _x >= 2}) then {
                    diag_log format ['[WMP CONFIG] Invalid %1 entry in %2: %3', _scopeKey, _path, _x];
                    _valid = false;
                } else {
                    _x params ['_name', '_default', ['_publish', false]];
                    if !(_name isEqualType '') then {
                        diag_log format ['[WMP CONFIG] Non-string variable name in %1: %2', _path, _x];
                        _valid = false;
                    } else {
                        if (isNil _name) then {missionNamespace setVariable [_name, _default]};
                        if (_scope == 'SERVER' && {_publish}) then {
                            missionNamespace setVariable [_name, missionNamespace getVariable [_name, _default], true];
                        };
                    };
                };
            } forEach (_config getOrDefault [_scopeKey, []]);

            {
                if !(_x isEqualType [] && {count _x == 3}) then {
                    diag_log format ['[WMP CONFIG] Invalid alias in %1: %2', _path, _x];
                    _valid = false;
                } else {
                    _x params ['_aliasScope', '_target', '_source'];
                    if (toUpperANSI _aliasScope == _scope && {isNil _target} && {!isNil _source}) then {
                        missionNamespace setVariable [_target, missionNamespace getVariable _source];
                    };
                };
            } forEach (_config getOrDefault ['aliases', []]);

            {
                if !(_x isEqualType [] && {count _x == 4}) then {
                    diag_log format ['[WMP CONFIG] Invalid fallback in %1: %2', _path, _x];
                    _valid = false;
                } else {
                    _x params ['_fallbackScope', '_target', '_source', '_default'];
                    if (toUpperANSI _fallbackScope == _scope && {isNil _target}) then {
                        missionNamespace setVariable [_target, missionNamespace getVariable [_source, _default]];
                    };
                };
            } forEach (_config getOrDefault ['fallbacks', []]);

            {
                if !(_x isEqualType [] && {count _x == 6}) then {
                    diag_log format ['[WMP CONFIG] Invalid conditional default in %1: %2', _path, _x];
                    _valid = false;
                } else {
                    _x params ['_conditionalScope', '_name', '_patch', '_loadedDefault', '_absentDefault', '_publish'];
                    if (toUpperANSI _conditionalScope == _scope) then {
                        private _default = if (isClass (configFile >> 'CfgPatches' >> _patch)) then {_loadedDefault} else {_absentDefault};
                        if (isNil _name) then {missionNamespace setVariable [_name, _default]};
                        if (_scope == 'SERVER' && {_publish}) then {
                            missionNamespace setVariable [_name, missionNamespace getVariable [_name, _default], true];
                        };
                    };
                };
            } forEach (_config getOrDefault ['conditional', []]);
        };
    };
} forEach _manifest;
if (_scope == 'SERVER') then {
    missionNamespace setVariable ['Waldo_Jamming_ConfigReady', _valid, true];
};
missionNamespace setVariable [format ['Waldo_FeatureConfig_%1_Ready', _scope], _valid];
_valid
