/*
 * Author: WaldoTheWarfighter
 * Builds the local CEOI from the authoritative communications plan and the most recent verified
 * local application. It highlights the player's authored group assignments during the pre-mission
 * briefing, then also recognises assignments matching a carried radio's current read-back.
 * Nets sharing one channel are shown once as a channel number instead of repeating every radio class.
 * The squad-radio section is omitted when no group on the player's side has a valid PRC-343
 * block/channel assignment, avoiding an empty list of "not assigned" placeholders.
 *
 * Locality and authority:
 * Player-local diary/UI work only. It reads the server-compiled plan plus verified local ACRE
 * read-back and replaces its own record, so repeated initialisation/respawn/JIP never duplicates it.
 *
 * Arguments: None.
 * Return Value: BOOL - true when the CEOI diary record was replaced.
 *
 * Example: [] call Waldo_fnc_ACRE2BuildCEOI;
 * Result: the local map diary contains one current, compact CEOI record when ACRE setup is enabled.
 * Current callers: Waldo_fnc_ACRE2Init and player-object replacement handling.
 */
if (!hasInterface || {isNull player}) exitWith {false};
private _config = missionNamespace getVariable ['Waldo_ACRE2_Config', createHashMap];
if !(_config getOrDefault ['enabled', true]) exitWith {false};
if !(isClass (configFile >> 'CfgPatches' >> 'acre_main')) exitWith {false};
private _plan = missionNamespace getVariable ['Waldo_ACRE2_Plan', []];
// During the pre-start briefing the server plan may not yet have reached this client. Compilation is
// pure and deterministic, so a local display-only preview is safe; it is never stored or used to tune.
if (count _plan < 4 || {(_plan select 0) != 5}) then {
    _plan = [_config, 0] call Waldo_fnc_ACRE2CompilePlan;
};
if (count _plan < 4 || {(_plan select 0) != 5}) exitWith {false};
private _sideKey = switch (side player) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'}};
private _sideIndex = (_plan select 2) findIf {(_x select 0) == _sideKey};
if (_sideIndex < 0) exitWith {false};
private _sidePlan = (_plan select 2) select _sideIndex;
private _nets = _sidePlan select 2;
private _groups = _sidePlan select 3;
private _groupKey = toUpperANSI ((((groupId group player) splitString ' -_.') joinString ''));
private _groupIndex = _groups findIf {(_x select 0) == _groupKey};
private _assignedNetKeys = [];
if (_groupIndex >= 0) then {
    {
        private _target = _x param [2, ""];
        if (_target isEqualType "" && {_target != ""}) then {
            _assignedNetKeys pushBackUnique (toUpperANSI _target);
        };
    } forEach ((_groups select _groupIndex) select 1);
};
private _radios = if (isNil 'acre_api_fnc_getCurrentRadioList') then {[]} else {[] call Waldo_fnc_ACRE2GetOrderedRadios};
private _profiles = [_config] call Waldo_fnc_ACRE2GetRadioProfiles;
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
    params ['_family', '_setting'];
    private _compatibleClasses = _profiles select {toUpper (_x select 5) == toUpper _family && {toUpper (_x select 1) == 'CHANNEL'}} apply {toUpper (_x select 0)};
    (_compatibleClasses findIf {_setting in (_current getOrDefault [_x, []])}) >= 0
};
private _displaySetting = {
    params ['_setting'];
    if (_setting isEqualType []) exitWith {format ['%1.%2', _setting param [0, 0], _setting param [1, 0]]};
    str _setting
};
private _text = "<font size='16'>Communications Electronics Operating Instructions</font><br/><br/>";
private _squadAssignments = [];
{
    private _rules = _x select 1;
    private _ruleIndex = _rules findIf {toUpper (_x select 0) == 'ACRE_PRC343' && {(_x select 1) isEqualType 0} && {(_x select 1) == 1}};
    if (_ruleIndex < 0) then {
        _ruleIndex = _rules findIf {
            toUpper (_x select 0) == 'ACRE_PRC343'
                && {(_x select 1) isEqualType ''}
                && {toUpper (_x select 1) == 'ALL'}
        };
    };
    private _assignment = if (_ruleIndex < 0) then {[]} else {(_rules select _ruleIndex) select 2};
    if (_assignment isEqualType [] && {count _assignment >= 2}) then {
        _squadAssignments pushBack [_x select 0, _assignment];
    };
} forEach _groups;
if !(_squadAssignments isEqualTo []) then {
    _text = _text + "<font size='14'>Squad Radio Assignments</font><br/>";
    {
        _x params ['_assignmentGroup', '_assignment'];
        private _line = format ['%1 - Block %2, Channel %3', _assignmentGroup, _assignment select 0, _assignment select 1];
        if (_assignmentGroup == _groupKey) then {
            // This section documents assignment, not live tuning. The player's squad is therefore
            // always green; current channel state is shown independently in Radio Nets below.
            _line = format ["<font color='#47ff47'>%1</font>", _line];
        };
        _text = _text + _line + '<br/>';
    } forEach _squadAssignments;
    _text = _text + '<br/>';
};
_text = _text + "<font size='14'>Radio Nets</font><br/>";
{
    private _family = _x select 2;
    private _setting = _x select 3;
    private _detail = if (toUpper _family == 'LEGACY_VHF') then {([_setting] call _displaySetting) + ' MHz'} else {'Ch. ' + ([_setting] call _displaySetting)};
    private _line = format ['%1 - %2', _x select 1, _detail];
    if (toUpperANSI (_x select 0) in _assignedNetKeys || {[_family, _setting] call _netIsCurrent}) then {
        // Green means this net is part of the player's authored group plan, or is confirmed by
        // live radio read-back after mission start. Keeping the label unchanged makes the briefing
        // compact while still making long-range assignments visible before unique radios exist.
        _line = format ["<font color='#47ff47'>%1</font>", _line];
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
