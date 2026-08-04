/*
 * Author: WaldoTheWarfighter
 * Builds the local CEOI from the authoritative communications plan and the most recent verified
 * local application. It highlights the current group's short/long assignments, identifies which
 * physical carried-radio occurrence received each setting and reports preserved or missing radios.
 *
 * Arguments: None.
 * Return Value: BOOL - true when the CEOI diary record was replaced.
 *
 * Example: [] call Waldo_fnc_ACRE2BuildCEOI;
 * Current callers: Waldo_fnc_ACRE2Init and player-object replacement handling.
 */
if (!hasInterface || {isNull player}) exitWith {false};
private _plan = missionNamespace getVariable ['Waldo_ACRE2_Plan', []];
if (count _plan < 4 || {(_plan select 0) != 3}) exitWith {false};
private _sideKey = switch (side player) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'}};
private _sideIndex = (_plan select 2) findIf {(_x select 0) == _sideKey};
if (_sideIndex < 0) exitWith {false};
private _sidePlan = (_plan select 2) select _sideIndex;
private _nets = _sidePlan select 2;
private _groups = _sidePlan select 3;
private _groupKey = toUpper groupId group player;
private _groupIndex = _groups findIf {(_x select 0) == _groupKey};
private _myNets = if (_groupIndex >= 0) then {(_groups select _groupIndex) select 1} else {[]};
private _text = "<font size='16'>Communications Electronics Operating Instructions</font><br/><br/>";
_text = _text + "<font size='14'>Squad Radio Assignments</font><br/>";
{
    private _assignment = _x select 2;
    private _line = if (_assignment isEqualType [] && {count _assignment >= 2}) then {
        format ['%1 - Block %2, Channel %3', _x select 0, _assignment select 0, _assignment select 1]
    } else {
        format ["%1 - <font color='#ffb347'>no PRC-343 assignment</font>", _x select 0]
    };
    if ((_x select 0) == _groupKey) then {_line = format ["<font color='#47ff47'>%1</font>", _line]};
    _text = _text + _line + '<br/>';
} forEach _groups;
_text = _text + "<br/><font size='14'>Radio Nets</font><br/>";
{
    private _tunings = (_x select 2) apply {format ['%1: %2', _x select 0, _x select 1]};
    private _line = format ['%1 - %2', _x select 1, _tunings joinString ', '];
    if ((_x select 0) in _myNets) then {_line = format ["<font color='#47ff47'>%1</font>", _line]};
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
