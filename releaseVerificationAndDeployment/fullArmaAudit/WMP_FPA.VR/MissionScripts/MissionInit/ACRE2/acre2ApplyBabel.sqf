/*
 * Author: WaldoTheWarfighter
 * Applies configured understood and speaking Babel languages to the local player. UID/variable
 * overrides support partial multilingual characters. Knowledge persists across side changes unless
 * changeOnSideChange is enabled, and is reapplied after local player-object replacement.
 *
 * Arguments: None.
 * Return Value: BOOL - true when Babel was disabled or successfully applied.
 *
 * Example: [] call Waldo_fnc_ACRE2ApplyBabel;
 * Current callers: Waldo_fnc_ACRE2Init, Waldo_fnc_BabelActivation and player unit handler.
 */
if (!hasInterface || {isNull player} || {!(isClass (configFile >> 'CfgPatches' >> 'acre_main'))}) exitWith {false};
private _config = missionNamespace getVariable ['Waldo_ACRE2_Config', createHashMap];
private _babel = _config getOrDefault ['babel', createHashMap];
if !(_babel getOrDefault ['enabled', false]) exitWith {true};
private _sideKey = switch (side player) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'}};
private _languages = [];
private _initial = '';
private _defaultIndex = (_babel getOrDefault ['sideDefaults', []]) findIf {toUpper (_x select 0) == _sideKey};
if (_defaultIndex >= 0) then {
    private _entry = (_babel get 'sideDefaults') select _defaultIndex;
    _languages = +(_entry select 1);
    _initial = _entry select 2;
};
{
    _x params ['_selector', '_overrideLanguages', '_overrideInitial'];
    private _matches = false;
    if (toUpper (_selector select 0) == 'UID') then {_matches = getPlayerUID player == (_selector select 1)};
    if (toUpper (_selector select 0) == 'VARIABLE') then {_matches = vehicleVarName player == (_selector select 1)};
    if (_matches) exitWith {_languages = +_overrideLanguages; _initial = _overrideInitial};
} forEach (_babel getOrDefault ['unitOverrides', []]);
private _lastSide = uiNamespace getVariable ['Waldo_ACRE2_BabelSide', ''];
if (_lastSide != '' && {_lastSide != _sideKey} && {!(_babel getOrDefault ['changeOnSideChange', false])}) then {
    _languages = +(uiNamespace getVariable ['Waldo_ACRE2_BabelLanguages', _languages]);
    _initial = uiNamespace getVariable ['Waldo_ACRE2_BabelSpeaking', _initial];
};
private _knownIds = (_babel getOrDefault ['languages', []]) apply {_x select 0};
_languages = _languages select {_x in _knownIds};
if (count _languages == 0) exitWith {diag_log '[WMP ACRE] Babel has no valid language for this player.'; false};
if !(_initial in _languages) then {_initial = _languages select 0};
private _spoken = _languages call acre_api_fnc_babelSetSpokenLanguages;
private _speaking = [_initial] call acre_api_fnc_babelSetSpeakingLanguage;
private _spokenAccepted = if (isNil '_spoken') then {true} else {
    if (_spoken isEqualType false) then {_spoken} else {true}
};
private _speakingAccepted = if (isNil '_speaking') then {true} else {
    if (_speaking isEqualType false) then {_speaking} else {true}
};
private _speakingReadBack = [] call acre_api_fnc_babelGetSpeakingLanguageId;
private _speakingMatches = if (isNil '_speakingReadBack') then {true} else {
    if (_speakingReadBack isEqualType 0) then {
        _speakingReadBack == (_knownIds find _initial)
    } else {
        _speakingReadBack isEqualTo _initial
    }
};
if (!_spokenAccepted || {!_speakingAccepted} || {!_speakingMatches}) exitWith {
    diag_log format ['[WMP ACRE] Babel API rejected the local language application (expected speaking language %1).', _initial];
    false
};
uiNamespace setVariable ['Waldo_ACRE2_BabelSide', _sideKey];
uiNamespace setVariable ['Waldo_ACRE2_BabelLanguages', +_languages];
uiNamespace setVariable ['Waldo_ACRE2_BabelSpeaking', _initial];
private _old = uiNamespace getVariable ['Waldo_ACRE2_BabelRecord', -1];
if (_old isEqualType 0 && {_old >= 0}) then {player removeDiaryRecord ['ACRE2', _old]};
if !(uiNamespace getVariable ['Waldo_ACRE2_DiarySubject', false]) then {
    player createDiarySubject ['ACRE2', 'ACRE2'];
    uiNamespace setVariable ['Waldo_ACRE2_DiarySubject', true];
};
private _names = _languages apply {private _index = _knownIds find _x; ((_babel get 'languages') select _index) select 1};
private _record = player createDiaryRecord ['ACRE2', ['Babel', format ['Understood: %1<br/>Speaking: %2', _names joinString ', ', _initial]]];
uiNamespace setVariable ['Waldo_ACRE2_BabelRecord', _record];
true
