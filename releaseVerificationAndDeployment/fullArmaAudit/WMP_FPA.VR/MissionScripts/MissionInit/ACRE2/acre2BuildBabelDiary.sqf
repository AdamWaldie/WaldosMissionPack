/*
 * Author: WaldoTheWarfighter
 * Builds the local Babel briefing record from mission configuration without waiting for ACRE's
 * runtime initialization. This makes the planned language information available in the multiplayer
 * briefing map. Waldo_fnc_ACRE2ApplyBabel later applies and verifies the same values after startup,
 * then calls this function again to replace the record rather than duplicate it.
 * Locality and authority: local presentation only. It reads pure mission configuration and the
 * local player's side, UID and variable name; it never changes radio or language state.
 *
 * Arguments: None.
 * Return Value: BOOL - true when Babel is disabled or the diary record was replaced.
 *
 * Example: [] call Waldo_fnc_ACRE2BuildBabelDiary;
 * Current callers: Waldo_fnc_AddDocs and Waldo_fnc_ACRE2ApplyBabel.
 */
if (!hasInterface || {isNull player}) exitWith {false};
private _config = missionNamespace getVariable ['Waldo_ACRE2_Config', createHashMap];
if !(_config getOrDefault ['enabled', true]) exitWith {true};
if !(isClass (configFile >> 'CfgPatches' >> 'acre_main')) exitWith {true};
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
    private _selectorType = toUpper (_selector select 0);
    private _matches = (_selectorType == 'UID' && {getPlayerUID player == (_selector select 1)})
        || {_selectorType in ['VARIABLE', 'VARIABLENAME'] && {vehicleVarName player == (_selector select 1)}};
    if (_matches) exitWith {_languages = +_overrideLanguages; _initial = _overrideInitial};
} forEach (_babel getOrDefault ['unitOverrides', []]);

private _known = createHashMapFromArray (_babel getOrDefault ['languages', []]);
private _names = _languages apply {_known getOrDefault [_x, _x]};
private _oldOwner = missionNamespace getVariable ['Waldo_ACRE2_BabelOwner', objNull];
{
    player removeDiaryRecord ['ACRE2', _x];
    if (!isNull _oldOwner && {_oldOwner != player}) then {_oldOwner removeDiaryRecord ['ACRE2', _x]};
} forEach +(missionNamespace getVariable ['Waldo_ACRE2_BabelRecords', []]);
if ((missionNamespace getVariable ['Waldo_ACRE2_DiarySubjectOwner', objNull]) != player) then {
    player createDiarySubject ['ACRE2', 'ACRE2'];
    missionNamespace setVariable ['Waldo_ACRE2_DiarySubjectOwner', player];
};
private _record = player createDiaryRecord ['ACRE2', ['Babel', format ['Understood: %1<br/>Speaking: %2', _names joinString ', ', _known getOrDefault [_initial, _initial]]]];
missionNamespace setVariable ['Waldo_ACRE2_BabelRecord', _record];
missionNamespace setVariable ['Waldo_ACRE2_BabelRecords', [_record]];
missionNamespace setVariable ['Waldo_ACRE2_BabelOwner', player];
true
