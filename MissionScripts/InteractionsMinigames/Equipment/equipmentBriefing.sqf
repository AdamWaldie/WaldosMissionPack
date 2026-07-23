/* Creates the equipment's integrated pre-operation procedure card. */
disableSerialization;
params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {};
private _profile = _display getVariable ["Waldo_IMG_Profile", createHashMap];
private _briefingControls = _profile getOrDefault ["controls", ""];
if (_briefingControls == "") then {_briefingControls = _display getVariable ["Waldo_MG_Help_Controls", "Use the displayed controls."];};
private _w = (0.55 * safezoneW) min (0.82 * safezoneH);
private _h = 0.48 * safezoneH;
private _x = safezoneX + (safezoneW - _w) / 2;
private _y = safezoneY + (safezoneH - _h) / 2;
private _controls = [];
private _shade = _display ctrlCreate ["RscText", -1];
_shade ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
_shade ctrlSetBackgroundColor [0,0,0,0.78];
_shade ctrlCommit 0;
_controls pushBack _shade;
private _card = _display ctrlCreate ["RscText", -1];
_card ctrlSetPosition [_x,_y,_w,_h];
_card ctrlSetBackgroundColor [0.14,0.13,0.105,0.995];
_card ctrlCommit 0;
_controls pushBack _card;
private _text = _display ctrlCreate ["RscStructuredText", -1];
_text ctrlSetPosition [_x + 0.035 * safezoneW, _y + 0.03 * safezoneH, _w - 0.07 * safezoneW, _h - 0.13 * safezoneH];
_text ctrlSetStructuredText parseText format [
    "<t size='1.25' color='#F2BE55'>%6</t><br/><t size='0.78' color='#A5A697'>%1 // %2</t><br/><br/><t size='1.08' color='#EEE9D8'>%3</t><br/><br/><t color='#E6C15A'>OPERATION</t><br/><t color='#EEE9D8'>%4</t><br/><br/><t color='#E6C15A'>CONTROLS</t><br/><t color='#EEE9D8'>%5</t><br/><br/><t color='#F2BE55'>[!] %7</t>",
    _profile getOrDefault ["manufacturer", "FIELD SYSTEMS"], _profile getOrDefault ["model", "UNIT"],
    _profile getOrDefault ["title", _display getVariable ["Waldo_MG_Help_Name", "EQUIPMENT"]],
    _profile getOrDefault ["objective", _display getVariable ["Waldo_MG_Help_Objective", "Complete the procedure."]],
    _briefingControls,
    _profile getOrDefault ["briefing", "FIELD OPERATING PROCEDURE"],
    _profile getOrDefault ["abortText", "ABORTING COUNTS AS A FAILED PROCEDURE"]
];
_text ctrlCommit 0;
_controls pushBack _text;
private _begin = _display ctrlCreate ["RscButtonMenu", -1];
_begin ctrlSetPosition [_x + _w - 0.24 * safezoneW, _y + _h - 0.075 * safezoneH, 0.205 * safezoneW, 0.05 * safezoneH];
_begin ctrlSetText (_profile getOrDefault ["activation", "BEGIN PROCEDURE"]);
_begin ctrlCommit 0;
_controls pushBack _begin;
_display setVariable ["Waldo_IMG_BriefingControls", _controls];
private _result = _display ctrlCreate ["RscText", -1];
_result ctrlSetPosition [safezoneX + 0.20 * safezoneW, safezoneY + 0.445 * safezoneH, 0.60 * safezoneW, 0.11 * safezoneH];
_result ctrlSetText "";
_result ctrlSetFontHeight (0.038 * safezoneH);
_result ctrlShow false;
_result ctrlCommit 0;
_display setVariable ["Waldo_IMG_LegacyResult", _result];
[_display] call Waldo_fnc_MiniGameApplyAccessibility;
_begin ctrlAddEventHandler ["ButtonClick", {
    private _disp = ctrlParent (_this select 0);
    private _controls = _disp getVariable ["Waldo_IMG_BriefingControls", []];
    _disp setVariable ["Waldo_IMG_BriefingControls", []];
    _disp setVariable ["Waldo_IMG_Started", true];
    private _profile = _disp getVariable ["Waldo_IMG_Profile", createHashMap];
    if ((_profile getOrDefault ["soundProfile", "equipment"]) != "silent") then {playSound "FD_Start_F";};
    private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {
        private _caption = if (((_profile getOrDefault ["accessibility", createHashMap]) getOrDefault ["audioCaptions", true]) && {(_profile getOrDefault ["soundProfile", "equipment"]) != "silent"}) then {"  [AUDIO: START TONE]"} else {""};
        _status ctrlSetText format ["%1%2", _profile getOrDefault ["statusText", "[ACTIVE] FOLLOW THE OPERATING PROCEDURE"], _caption];
    };
    _controls spawn {
        params ["_deferredControls"];
        uiSleep 0;
        {if (!isNull _x) then {ctrlDelete _x;};} forEach _deferredControls;
    };
}];
ctrlSetFocus _begin;
