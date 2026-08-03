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
    private _line = format ['%1 - Block %2, Channel %3', _x select 0, _assignment select 0, _assignment select 1];
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
private _last = uiNamespace getVariable ['Waldo_ACRE2_LastApplication', []];
_text = _text + "<br/><font size='14'>Carried Radio Verification</font><br/>";
if (count _last >= 7 && {(_last select 2) == _sideKey} && {(_last select 3) == _groupKey}) then {
    {
        _x params ['_radioId', '_base', '_occurrence', '_setting', '_spatial', '_netLabel', ['_mode', 'CHANNEL']];
        private _ear = if (_spatial == 'CENTER') then {'BOTH'} else {_spatial};
        private _verification = if (_mode == 'FREQUENCY') then {'REQUEST ACCEPTED; PHYSICAL CHECK REQUIRED'} else {'READ BACK'};
        _text = _text + format ['%1 #%2 - %3 - %4 ear (%5; %6)<br/>', _base, _occurrence, _netLabel, _ear, _setting, _verification];
    } forEach (_last select 4);
    {
        _text = _text + format ["<font color='#ffb347'>UNAPPLIED: %1</font><br/>", _x];
    } forEach (_last select 5);
    if (count (_last select 6) > 0) then {
        _text = _text + format ['Preserved/unmanaged carried radios: %1<br/>', count (_last select 6)];
    };
} else {
    _text = _text + 'No verified local radio application is available yet.<br/>';
};
private _old = uiNamespace getVariable ['Waldo_ACRE2_CEOIRecord', -1];
if (_old isEqualType 0 && {_old >= 0}) then {player removeDiaryRecord ['ACRE2', _old]};
if !(uiNamespace getVariable ['Waldo_ACRE2_DiarySubject', false]) then {
    player createDiarySubject ['ACRE2', 'ACRE2'];
    uiNamespace setVariable ['Waldo_ACRE2_DiarySubject', true];
};
private _record = player createDiaryRecord ['ACRE2', ['CEOI', _text]];
uiNamespace setVariable ['Waldo_ACRE2_CEOIRecord', _record];
true
