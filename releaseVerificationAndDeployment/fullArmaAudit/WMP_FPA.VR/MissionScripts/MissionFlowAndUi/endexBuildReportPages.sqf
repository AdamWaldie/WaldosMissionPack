/*
 * Author: WaldoTheWarfighter
 * Builds compact After-Action Report pages for the persistent ENDEX notification card. Short,
 * outcome-focused sections share one page; only genuinely excessive content creates balanced
 * additional pages. Temporary WIA is deliberately omitted because it duplicates the more useful
 * KIA and named confirmed-death outcomes.
 * Reads server-broadcast AAR and Obituary state locally without changing authority. The caller may
 * rotate the returned pages through one REPLACE-keyed UI element without consuming extra lanes.
 *
 * Arguments: None.
 * Return Value: ARRAY of [page title <STRING>, formatted body <STRING>].
 * Current caller: Waldo_fnc_ENDEX on each interface client.
 *
 * Example: private _pages = [] call Waldo_fnc_ENDEXBuildReportPages;
 */
if (isNil {missionNamespace getVariable "Waldo_AAR_StartTime"}) exitWith {[]};
private _elapsed = (time - (missionNamespace getVariable ["Waldo_AAR_StartTime", time])) max 0;
private _kia = missionNamespace getVariable ["Waldo_AAR_KIA", [0,0,0,0]];
private _veh = missionNamespace getVariable ["Waldo_AAR_VehKIA", [0,0,0,0]];
_kia params ["_wKia", "_eKia", "_iKia", "_cKia"];
_veh params ["_wVeh", "_eVeh", "_iVeh", "_cVeh"];
private _sections = [["SUMMARY", [
    format ["Duration: %1m %2s | Player losses: %3 | Friendly fire: %4", floor (_elapsed / 60), floor (_elapsed % 60), missionNamespace getVariable ["Waldo_AAR_PlayerKIA", 0], missionNamespace getVariable ["Waldo_AAR_FF", 0]],
    format ["KIA // BLUFOR %1 | OPFOR %2 | INDEP %3 | CIV %4", _wKia, _eKia, _iKia, _cKia],
    format ["Vehicles // BLUFOR %1 | OPFOR %2 | INDEP %3 | CIV %4", _wVeh, _eVeh, _iVeh, _cVeh]
]]];
private _obituary = missionNamespace getVariable ["Waldo_AAR_Obituary", []];
if !(_obituary isEqualTo []) then {
    private _lines = [];
    {_lines pushBack format ["%1 (%2)", _x select 0, _x select 1]} forEach ([_obituary, [], {toLower (_x select 0)}, "ASCEND"] call BIS_fnc_sortBy);
    _sections pushBack ["CONFIRMED DEATHS", _lines];
};
private _tasks = missionNamespace getVariable ["Waldo_AAR_Tasks", []];
if !(_tasks isEqualTo []) then {
    private _lines = [];
    {_lines pushBack format ["%1 - %2", _x param [0, "Objective"], _x param [1, "UNKNOWN"]]} forEach _tasks;
    _sections pushBack ["OBJECTIVES", _lines];
};
private _frags = missionNamespace getVariable ["Waldo_AAR_Frags", []];
if !(_frags isEqualTo []) then {
    private _lines = [];
    private _sorted = [_frags, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;
    {_lines pushBack format ["%1. %2 (%3)", _forEachIndex + 1, _x select 0, _x select 1]} forEach (_sorted select [0, 5 min count _sorted]);
    _sections pushBack ["TOP FRAGGERS", _lines];
};

// Treat the available card as one report first. Only paginate once the report genuinely exceeds a
// useful page, then distribute content evenly: 13 rows become 7 + 6, never 12 + 1. Section labels
// are inserted while rendering and do not become orphaned pages of their own.
private _rows = [];
{
    _x params ["_sectionTitle", "_sectionLines"];
    {_rows pushBack [_sectionTitle, _x]} forEach _sectionLines;
} forEach _sections;

private _singlePageRows = 12;
private _pagedContentRows = 10;
private _pageCount = if (count _rows <= _singlePageRows) then {1} else {ceil ((count _rows) / _pagedContentRows)};
private _pages = [];
private _offset = 0;
for "_pageIndex" from 0 to (_pageCount - 1) do {
    private _remainingRows = (count _rows) - _offset;
    private _remainingPages = _pageCount - _pageIndex;
    private _take = ceil (_remainingRows / _remainingPages);
    private _slice = _rows select [_offset, _take];
    _offset = _offset + _take;

    private _pageLines = [];
    private _pageTitles = [];
    private _lastSection = "";
    {
        _x params ["_sectionTitle", "_line"];
        if !(_sectionTitle in _pageTitles) then {_pageTitles pushBack _sectionTitle};
        if (_sectionTitle != "SUMMARY" && {_sectionTitle != _lastSection}) then {
            _pageLines pushBack format ["<t color='#106bb5'>%1</t>", _sectionTitle];
        };
        _pageLines pushBack _line;
        _lastSection = _sectionTitle;
    } forEach _slice;
    _pages pushBack [_pageTitles joinString " + ", "<t align='center'>" + (_pageLines joinString "<br/>") + "</t>"];
};
_pages
