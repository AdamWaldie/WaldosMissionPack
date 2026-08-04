/*
 * Author: WaldoTheWarfighter
 * Builds the local CEOI from the authoritative communications plan and the most recent verified
 * local application. It highlights only assignments matching a carried radio's current read-back.
 * Nets sharing one channel are shown once as a channel number instead of repeating every radio class.
 *
 * Arguments: None.
 * Return Value: BOOL - true when the CEOI diary record was replaced.
 *
 * Example: [] call Waldo_fnc_ACRE2BuildCEOI;
 * Current callers: Waldo_fnc_ACRE2Init and player-object replacement handling.
 */
if (!hasInterface || {isNull player}) exitWith {false};
private _config = missionNamespace getVariable ['Waldo_ACRE2_Config', createHashMap];
if !(_config getOrDefault ['enabled', true]) exitWith {false};
if !(isClass (configFile >> 'CfgPatches' >> 'acre_main')) exitWith {false};
private _plan = missionNamespace getVariable ['Waldo_ACRE2_Plan', []];
// During the pre-start briefing the server plan may not yet have reached this client. Compilation is
// pure and deterministic, so a local display-only preview is safe; it is never stored or used to tune.
if (count _plan < 4 || {(_plan select 0) != 3}) then {
    _plan = [_config, 0] call Waldo_fnc_ACRE2CompilePlan;
};
if (count _plan < 4 || {(_plan select 0) != 3}) exitWith {false};
private _sideKey = switch (side player) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'}};
private _sideIndex = (_plan select 2) findIf {(_x select 0) == _sideKey};
if (_sideIndex < 0) exitWith {false};
private _sidePlan = (_plan select 2) select _sideIndex;
private _nets = _sidePlan select 2;
private _groups = _sidePlan select 3;
private _groupKey = toUpper groupId group player;
private _groupIndex = _groups findIf {(_x select 0) == _groupKey};
private _radios = if (isNil 'acre_api_fnc_getCurrentRadioList') then {[]} else {[] call Waldo_fnc_ACRE2GetOrderedRadios};
private _current = createHashMap;
{
    private _base = toUpper ([_x] call acre_api_fnc_getBaseRadio);
    private _setting = [_x] call acre_api_fnc_getRadioChannel;
    if (_base == 'ACRE_PRC343' && {_setting isEqualType 0} && {_setting >= 1}) then {
        private _zeroBased = _setting - 1;
        _setting = [(floor (_zeroBased / 16)) + 1, (_zeroBased mod 16) + 1];
    };
    private _values = _current getOrDefault [_base, []];
    _values pushBackUnique _setting;
    _current set [_base, _values];
} forEach _radios;
private _netIsCurrent = {
    params ['_netKey', '_tunings'];
    private _currentIndex = _tunings findIf {
        private _base = toUpper (_x select 0);
        private _setting = _x select 1;
        // ACRE exposes channel read-back for channel radios, but not the tuned frequency for
        // manual-frequency radios. Do not claim those are current from stale setup state.
        private _canRead = !(_base in ['ACRE_PRC77', 'ACRE_SEM70'])
            && {_setting in (_current getOrDefault [_base, []])};
        if (!_canRead) then {
            false
        } else {
            // A physical channel cannot identify which named net was intended when configuration
            // duplicates a tuning. Ambiguous nets remain unhighlighted instead of both appearing live.
            private _matchingNets = _nets select {
                private _candidateIndex = (_x select 2) findIf {
                    toUpper (_x select 0) == _base && {(_x select 1) isEqualTo _setting}
                };
                _candidateIndex >= 0
            };
            count _matchingNets == 1 && {((_matchingNets select 0) select 0) == _netKey}
        }
    };
    _currentIndex >= 0
};
private _shortName = {
    params ['_base'];
    createHashMapFromArray [
        ['ACRE_PRC148', '148'], ['ACRE_PRC152', '152'], ['ACRE_PRC117F', '117F'],
        ['ACRE_BF888S', '888'], ['ACRE_SEM52SL', 'SEM52'], ['ACRE_PRC77', '77'],
        ['ACRE_SEM70', 'SEM70']
    ] getOrDefault [toUpper _base, _base]
};
private _displaySetting = {
    params ['_setting'];
    if (_setting isEqualType []) exitWith {format ['%1.%2', _setting param [0, 0], _setting param [1, 0]]};
    str _setting
};
private _text = "<font size='16'>Communications Electronics Operating Instructions</font><br/><br/>";
_text = _text + "<font size='14'>Squad Radio Assignments</font><br/>";
{
    private _assignment = _x select 2;
    private _line = if (_assignment isEqualType [] && {count _assignment >= 2}) then {
        format ['%1 - Block %2, Channel %3', _x select 0, _assignment select 0, _assignment select 1]
    } else {
        format ["%1 - <font color='#ffb347'>no PRC-343 assignment</font>", _x select 0]
    };
    private _isOwnSquad = (_x select 0) == _groupKey;
    if (_isOwnSquad) then {
        // This section documents assignment, not live tuning. The player's squad is therefore
        // always green; current channel state is shown independently in Radio Nets below.
        _line = format ["<font color='#47ff47'>%1</font>", _line];
    };
    _text = _text + _line + '<br/>';
} forEach _groups;
_text = _text + "<br/><font size='14'>Radio Nets</font><br/>";
{
    private _tunings = _x select 2;
    private _settings = [];
    {_settings pushBackUnique ([_x select 1] call _displaySetting)} forEach _tunings;
    private _detail = if (count _settings == 1) then {
        private _firstBase = toUpper ((_tunings select 0) select 0);
        if (_firstBase in ['ACRE_PRC77', 'ACRE_SEM70']) then {
            (_settings select 0) + ' MHz'
        } else {
            'Ch. ' + (_settings select 0)
        }
    } else {
        (_tunings apply {format ['%1 %2', [_x select 0] call _shortName, [_x select 1] call _displaySetting]}) joinString ', '
    };
    private _line = format ['%1 - %2', _x select 1, _detail];
    if ([_x select 0, _tunings] call _netIsCurrent) then {
        _line = format ["<font color='#47ff47'>[CURRENT] %1</font>", _line];
    };
    _text = _text + _line + '<br/>';
} forEach _nets;
private _oldOwner = missionNamespace getVariable ['Waldo_ACRE2_CEOIOwner', objNull];
private _records = +(missionNamespace getVariable ['Waldo_ACRE2_CEOIRecords', []]);
private _legacyRecord = missionNamespace getVariable ['Waldo_ACRE2_CEOIRecord', -1];
if !(_legacyRecord isEqualType 0) then {_records pushBack _legacyRecord};
{
    // Diary content remains visible when Arma replaces the player object on respawn. Remove each
    // known handle from the current diary first; also ask the previous owner while it still exists.
    player removeDiaryRecord ['ACRE2', _x];
    if (!isNull _oldOwner && {_oldOwner != player}) then {_oldOwner removeDiaryRecord ['ACRE2', _x]};
} forEach _records;
missionNamespace setVariable ['Waldo_ACRE2_CEOIRecords', []];
if ((missionNamespace getVariable ['Waldo_ACRE2_DiarySubjectOwner', objNull]) != player) then {
    player createDiarySubject ['ACRE2', 'ACRE2'];
    missionNamespace setVariable ['Waldo_ACRE2_DiarySubjectOwner', player];
};
private _record = player createDiaryRecord ['ACRE2', ['CEOI', _text]];
missionNamespace setVariable ['Waldo_ACRE2_CEOIRecord', _record];
missionNamespace setVariable ['Waldo_ACRE2_CEOIRecords', [_record]];
missionNamespace setVariable ['Waldo_ACRE2_CEOIOwner', player];
missionNamespace setVariable ['Waldo_ACRE2_CEOIReady', true];
diag_log format ['[WMP ACRE] CEOI built for %1/%2.', _sideKey, _groupKey];
true
