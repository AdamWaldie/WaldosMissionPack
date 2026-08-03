/*
 * Author: WaldoTheWarfighter
 * Builds the local CEOI directly from the authoritative communications plan, filtering it to the
 * player's side and highlighting the current group's short- and long-range assignments.
 *
 * Arguments: None.
 * Return Value: BOOL - true when the CEOI diary record was replaced.
 *
 * Example: [] call Waldo_fnc_ACRE2BuildCEOI;
 * Current callers: Waldo_fnc_ACRE2Init and player-object replacement handling.
 */
if (!hasInterface || {isNull player}) exitWith {false};
private _plan = missionNamespace getVariable ['Waldo_ACRE2_Plan', []];
if (count _plan < 4) exitWith {false};
private _sideKey = switch (side player) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'}};
private _sideIndex = (_plan select 2) findIf {(_x select 0) == _sideKey};
if (_sideIndex < 0) exitWith {false};
private _sidePlan = (_plan select 2) select _sideIndex;
_sidePlan params ['_unusedSide', '_preset', '_nets', '_groups'];
private _groupKey = toUpper groupId group player;
private _groupIndex = _groups findIf {(_x select 0) == _groupKey};
private _myNets = if (_groupIndex >= 0) then {(_groups select _groupIndex) select 1} else {[]};
private _text = "<font size='16'>Communications Electronics Operating Instructions</font><br/><br/>";
_text = _text + "<font size='14'>Squad Radio Assignments</font><br/>";
{
    private _assignment = _x select 2;
    private _line = format ['%1 - Block %2, Channel %3', _x select 0, _assignment select 0, _assignment select 1];
    if ((_x select 0) == _groupKey) then {_line = format ["<font color='#47ff47'>%1</font>", _line]};
    _text = _text + _line + '<br/>';
} forEach _groups;
_text = _text + "<br/><font size='14'>Long Range Nets</font><br/>";
{
    private _line = format ['Channel %1: %2', _x select 2, _x select 1];
    if ((_x select 0) in _myNets) then {_line = format ["<font color='#47ff47'>%1</font>", _line]};
    _text = _text + _line + '<br/>';
} forEach _nets;
private _old = uiNamespace getVariable ['Waldo_ACRE2_CEOIRecord', -1];
if (_old isEqualType 0 && {_old >= 0}) then {player removeDiaryRecord ['ACRE2', _old]};
if !(uiNamespace getVariable ['Waldo_ACRE2_DiarySubject', false]) then {
    player createDiarySubject ['ACRE2', 'ACRE2'];
    uiNamespace setVariable ['Waldo_ACRE2_DiarySubject', true];
};
private _record = player createDiaryRecord ['ACRE2', ['CEOI', _text]];
uiNamespace setVariable ['Waldo_ACRE2_CEOIRecord', _record];
true
