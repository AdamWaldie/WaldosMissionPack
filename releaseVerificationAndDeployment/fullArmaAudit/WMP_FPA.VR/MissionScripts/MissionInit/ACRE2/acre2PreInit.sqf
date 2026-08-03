/*
 * Author: WaldoTheWarfighter
 * Loads and validates MissionConfig\acreConfig.sqf before mission radios become unique, registers Babel
 * languages in deterministic order and applies label-only changes to existing side presets.
 *
 * Arguments: None.
 * Return Value: BOOL - true when configuration was accepted, including when ACRE is absent.
 *
 * Example: Automatically called by CfgFunctions preInit.
 * Current caller: CfgFunctions preInit registration in WaldosFunctions.sqf.
 */
private _config = call compile preprocessFileLineNumbers 'MissionConfig\acreConfig.sqf';
private _validation = [_config] call Waldo_fnc_ACRE2ValidateConfig;
missionNamespace setVariable ['Waldo_ACRE2_Config', _config];
missionNamespace setVariable ['Waldo_ACRE2_ConfigValid', _validation select 0];
{diag_log format ['[WMP ACRE] CONFIG WARNING: %1', _x]} forEach (_validation param [2, []]);
if !(_validation select 0) exitWith {
    {diag_log format ['[WMP ACRE] CONFIG ERROR: %1', _x]} forEach (_validation select 1);
    false
};
if !(_config getOrDefault ['enabled', true]) exitWith {
    missionNamespace setVariable ['Waldo_ACRE2_Enabled', false];
    true
};
missionNamespace setVariable ['Waldo_ACRE2_Enabled', true];
if !(isClass (configFile >> 'CfgPatches' >> 'acre_main')) exitWith {true};

// Select presets explicitly instead of setupMission so PRC-343 capacity and side isolation are
// independent choices. This follows ACRE's non-blocking player-ready callback and runs before unique
// carried radios consume their base-class preset.
[{
    !isNil "acre_player" && {!isNull acre_player}
}, {
    params ['_config'];
    private _sideKey = switch (side acre_player) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'}};
    private _sideAliases = switch (_sideKey) do {case 'WEST': {['WEST', 'BLUFOR']}; case 'EAST': {['EAST', 'OPFOR']}; case 'GUER': {['GUER', 'INDEP', 'INDEPENDENT']}; default {['CIV', 'CIVILIAN']}};
    private _sideIndex = (_config getOrDefault ['sides', []]) findIf {toUpper (_x select 0) in _sideAliases};
    private _sidePreset = if (_sideIndex >= 0) then {((_config get 'sides') select _sideIndex) select 1} else {'default'};
    private _shortPreset = if (toUpper (_config getOrDefault ['prc343PresetPolicy', 'FULL_RANGE']) == 'FULL_RANGE') then {'default'} else {_sidePreset};
    {
        private _base = _x select 0;
        [_base, if (toUpper _base == 'ACRE_PRC343') then {_shortPreset} else {_sidePreset}] call acre_api_fnc_setPreset;
    } forEach ([_config] call Waldo_fnc_ACRE2GetRadioProfiles);
}, [_config]] call CBA_fnc_waitUntilAndExecute;
private _babel = _config getOrDefault ['babel', createHashMap];
if (_babel getOrDefault ['enabled', false]) then {
    {
        _x params ['_languageId', '_languageName'];
        private _registrationResult = [_languageId, _languageName] call acre_api_fnc_babelAddLanguageType;
        private _registrationAccepted = if (isNil '_registrationResult') then {true} else {
            if (_registrationResult isEqualType false) then {_registrationResult} else {true}
        };
        if (!_registrationAccepted) then {
            diag_log format ['[WMP ACRE] Babel registration was explicitly rejected: %1', _x];
        };
    } forEach (_babel getOrDefault ['languages', []]);
};
[_config] call Waldo_fnc_ACRE2ApplyPresetNames
