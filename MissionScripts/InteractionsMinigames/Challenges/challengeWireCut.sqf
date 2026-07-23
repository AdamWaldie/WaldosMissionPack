/*
 * Author: Waldo
 * Wire-cut defusal mini game (the default built-in interaction challenge).
 * Opens a self-contained dialog on the calling player: a set of numbered, patterned and coloured wires and a
 * printed instruction identifying exactly one correct wire to cut. Cutting the correct
 * wire succeeds; cutting a wrong wire, letting the timer expire, or pressing Escape fails.
 * The whole challenge runs locally on the actor and reports a single boolean back through
 * the provided resolve callback, so it is safe to drive any authoritative outcome from it.
 *
 * This is a challenge opener: it is dispatched by Waldo_fnc_MiniGameChallenge and follows
 * the opener contract [_config, _resolve]. Register more challenge types the same way with
 * Waldo_fnc_MiniGameRegisterChallenge.
 *
 * Arguments:
 * _config  - Array - challenge config, all optional:
 *              0: _wireCount - Number - number of wires (clamped 3..6, default 5)
 *              1: _timeLimit - Number - seconds on the clock (0 = no clock, default 20)
 *              2: _title     - String - dialog heading (default "DEFUSAL")
 * _resolve - Code  - called once with boolean success and typed outcome metadata
 *
 * Return Value:
 * Nothing (result delivered asynchronously through _resolve)
 *
 * Example:
 * [[5, 20, "DEFUSAL"], { params ["_ok"]; systemChat str _ok; }] call Waldo_fnc_MiniGameWireCut;
 */

disableSerialization;

params [
    ["_config", []],
    ["_resolve", {}]
];

if (!hasInterface) exitWith { [false] call _resolve; };

_config params [
    ["_wireCount", 5],
    ["_timeLimit", 20],
    ["_title", "EOD CONTROLLER"]
];

_wireCount = round _wireCount;
if (_wireCount < 3) then { _wireCount = 3; };
if (_wireCount > 6) then { _wireCount = 6; };

// Do not stack a second defusal dialog on top of an open one.
if (!isNull (missionNamespace getVariable ["Waldo_MG_WC_ActiveDisplay", displayNull])) exitWith {
    [false] call _resolve;
};
if (!isNull (missionNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])) exitWith {
    [false] call _resolve;
};

// Colour palette: [name, [r,g,b,a]].
private _palette = [
    ["RED",    [0.78, 0.16, 0.16, 1]],
    ["BLUE",   [0.20, 0.42, 0.85, 1]],
    ["YELLOW", [0.86, 0.78, 0.18, 1]],
    ["GREEN",  [0.22, 0.62, 0.28, 1]],
    ["WHITE",  [0.90, 0.90, 0.92, 1]],
    ["BLACK",  [0.12, 0.12, 0.13, 1]]
];

// Build the wire list.
private _wires = [];
for "_i" from 0 to (_wireCount - 1) do {
    _wires pushBack (selectRandom _palette);
};

// Pick the correct wire and craft an unambiguous instruction for it.
private _correct = floor (random _wireCount);
private _correctName = (_wires select _correct) select 0;

private _sameColour = [];
{
    if ((_x select 0) == _correctName) then { _sameColour pushBack _forEachIndex; };
} forEach _wires;

private _ordinalWords = ["first", "second", "third", "fourth", "fifth", "sixth"];
private _instruction = "";

// Randomly present the clue as a colour rule or a positional rule, both always solvable.
if (random 1 < 0.5) then {
    // Colour-based clue.
    if ((count _sameColour) <= 1) then {
        _instruction = format ["Cut the only %1 wire.", _correctName];
    } else {
        private _rank = _sameColour find _correct;
        _instruction = format ["Cut the %1 %2 wire (counting from the top).", _ordinalWords select _rank, _correctName];
    };
} else {
    // Positional clue.
    _instruction = format ["Cut wire number %1 (counting from the top).", _correct + 1];
};

private _parent = findDisplay 46;
if (isNull _parent) exitWith { [false] call _resolve; };
private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith { [false] call _resolve; };

missionNamespace setVariable ["Waldo_MG_WC_ActiveDisplay", _display];
missionNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", _display];
[_display, "Mouse: choose one numbered and patterned wire", _title, _instruction, "Check both the number and pattern before cutting. The wrong wire fails immediately."] call Waldo_fnc_MiniGameChallengeUILegacy;

_display setVariable ["Waldo_MG_WC_Correct", _correct];
_display setVariable ["Waldo_MG_WC_Resolve", _resolve];
_display setVariable ["Waldo_MG_WC_Done", false];

// Single-shot finisher: closes the dialog and delivers the result once.
_display setVariable ["Waldo_MG_WC_Finish", {
    params ["_disp", "_ok", ["_resultKey", ""]];
    if (isNull _disp) exitWith {};
    if (_disp getVariable ["Waldo_MG_WC_Done", false]) exitWith {};
    _disp setVariable ["Waldo_MG_WC_Done", true];
    [_disp, _ok, _resultKey] call (_disp getVariable ["Waldo_IMG_ShowResult", {}]);
    private _fnResolve = _disp getVariable ["Waldo_MG_WC_Resolve", {}];
    private _outcomeCode = if (_ok) then {"SUCCESS"} else {if (_resultKey == "timeoutText") then {"TIMEOUT"} else {if (_resultKey == "abortText") then {"ABORTED"} else {"FAILURE"};};};
    private _reason = if (_resultKey == "") then {""} else {(_disp getVariable ["Waldo_IMG_Profile", createHashMap]) getOrDefault [_resultKey, _resultKey]};
    missionNamespace setVariable ["Waldo_MG_WC_ActiveDisplay", displayNull];
    [{
        params ["_disp", "_res", "_ok", "_outcomeCode", "_reason"];
        if (!isNull _disp) then {_disp closeDisplay 1;};
        [_ok, [_outcomeCode, _reason]] call _res;
    }, [_disp, _fnResolve, _ok, _outcomeCode, _reason], if (_disp getVariable ["Waldo_IMG_ReducedMotion", false]) then {0.12} else {0.5}] call CBA_fnc_waitAndExecute;
}];

// Layout (safezone-relative).
private _w = 0.42 * safezoneW;
private _h = 0.5 * safezoneH;
private _x = safezoneX + (safezoneW - _w) / 2;
private _y = safezoneY + (safezoneH - _h) / 2;

// WMP brand palette.
private _cPanel = [0.04, 0.05, 0.07, 0.94];
private _cHeader = [0.10, 0.13, 0.20, 1];
private _cAccent = [0.243, 0.463, 0.827, 1];
private _cAccentLt = [0.55, 0.72, 0.98, 1];

private _panel = _display ctrlCreate ["RscText", -1];
_panel ctrlSetPosition [_x - 0.01 * safezoneW, _y - 0.01 * safezoneH, _w + 0.02 * safezoneW, _h + 0.02 * safezoneH];
_panel ctrlSetBackgroundColor _cPanel;
_panel ctrlCommit 0;

private _accentBar = _display ctrlCreate ["RscText", -1];
_accentBar ctrlSetPosition [_x - 0.01 * safezoneW, _y - 0.01 * safezoneH, _w + 0.02 * safezoneW, 0.006 * safezoneH];
_accentBar ctrlSetBackgroundColor _cAccent;
_accentBar ctrlCommit 0;

private _heading = _display ctrlCreate ["RscText", -1];
_heading ctrlSetPosition [_x, _y, _w, 0.06 * safezoneH];
_heading ctrlSetText _title;
_heading ctrlSetTextColor _cAccentLt;
_heading ctrlSetBackgroundColor _cHeader;
_heading ctrlCommit 0;

private _timer = _display ctrlCreate ["RscText", -1];
_timer ctrlSetPosition [_x, _y + 0.065 * safezoneH, _w, 0.05 * safezoneH];
_timer ctrlSetTextColor [0.90, 0.90, 0.92, 1];
_timer ctrlSetText "";
_timer ctrlCommit 0;
_display setVariable ["Waldo_MG_WC_TimerCtrl", _timer];

private _clue = _display ctrlCreate ["RscStructuredText", -1];
_clue ctrlSetPosition [_x, _y + 0.12 * safezoneH, _w, 0.09 * safezoneH];
_clue ctrlSetStructuredText parseText format ["<t align='center' size='1.05'>%1</t>", _instruction];
_clue ctrlCommit 0;

// Wire buttons. (_x is reused by forEach as the wire element, so capture the column x first.)
private _colX = _x;
private _listTop = _y + 0.225 * safezoneH;
private _rowH = 0.045 * safezoneH;
private _gap = 0.012 * safezoneH;
{
    private _row = _listTop + _forEachIndex * (_rowH + _gap);
    private _btn = _display ctrlCreate ["RscButton", -1];
    _btn ctrlSetPosition [_colX, _row, _w, _rowH];
    private _patterns = ["///", "XXX", "===", "+++", "...", "###"];
    _btn ctrlSetText format ["  WIRE %1  [%2]  %3", _forEachIndex + 1, _patterns select _forEachIndex, (_x select 0)];
    _btn ctrlSetTooltip format ["Cut wire %1 - %2 - pattern %3", _forEachIndex + 1, (_x select 0), _patterns select _forEachIndex];
    _btn ctrlSetBackgroundColor (_x select 1);
    _btn ctrlSetTextColor [0.05, 0.05, 0.05, 1];
    _btn setVariable ["Waldo_MG_WC_Index", _forEachIndex];
    _btn ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = ctrlParent _ctrl;
        if (isNull _disp || {_disp getVariable ["Waldo_MG_WC_Done", false]} || {_disp getVariable ["Waldo_MG_WC_InputLocked", false]}) exitWith {};
        private _idx = _ctrl getVariable ["Waldo_MG_WC_Index", -1];
        private _cor = _disp getVariable ["Waldo_MG_WC_Correct", -2];
        private _fin = _disp getVariable ["Waldo_MG_WC_Finish", {}];
        private _ok = _idx == _cor;
        _disp setVariable ["Waldo_MG_WC_InputLocked", true];
        _ctrl ctrlSetText if (_ok) then {"WIRE CUT - CIRCUIT SAFE"} else {"WRONG WIRE - CIRCUIT TRIPPED"};
        _ctrl ctrlSetBackgroundColor if (_ok) then {[0.10, 0.44, 0.18, 1]} else {[0.80, 0.18, 0.16, 1]};
        [{ params ["_disp", "_ok", "_fin"]; [_disp, _ok] call _fin; }, [_disp, _ok, _fin], 0.45] call CBA_fnc_waitAndExecute;
    }];
    _btn ctrlCommit 0;
} forEach _wires;

// Escape aborts the attempt (counts as a failure).
_display displayAddEventHandler ["KeyDown", {
    params ["_disp", "_key"];
    if (_key == 1) then {
        private _fin = _disp getVariable ["Waldo_MG_WC_Finish", {}];
        [_disp, _fin] call (_disp getVariable ["Waldo_IMG_RequestAbort", {}]);
        true
    } else {
        false
    };
}];

// Countdown loop (skipped when _timeLimit <= 0).
if (_timeLimit > 0) then {
    [_display, _timeLimit] spawn {
        params ["_disp", "_timeLimit"];
        waitUntil {isNull _disp || {_disp getVariable ["Waldo_IMG_Started", false]}};
        if (isNull _disp) exitWith {};
        private _deadline = time + _timeLimit;
        while { !isNull _disp && {!(_disp getVariable ["Waldo_MG_WC_Done", false])} } do {
            private _remain = _deadline - time;
            private _timerCtrl = _disp getVariable ["Waldo_MG_WC_TimerCtrl", controlNull];
            if (_remain <= 0) exitWith {
                if !(_disp getVariable ["Waldo_MG_WC_InputLocked", false]) then {
                    private _fin = _disp getVariable ["Waldo_MG_WC_Finish", {}];
                    [_disp, false, "timeoutText"] call _fin;
                };
            };
            if (!isNull _timerCtrl) then {
                _timerCtrl ctrlSetText format ["TIME REMAINING: %1s", (_remain max 0) toFixed 1];
                if (_remain <= (_timeLimit * 0.3)) then {
                    _timerCtrl ctrlSetTextColor [0.85, 0.20, 0.20, 1];
                };
            };
            sleep 0.08;
        };
    };
} else {
    _timer ctrlSetText "NO TIME LIMIT";
};
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;
