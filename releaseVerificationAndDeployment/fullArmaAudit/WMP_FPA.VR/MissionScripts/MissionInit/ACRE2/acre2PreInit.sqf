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
[false, true] call acre_api_fnc_setupMission;
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
