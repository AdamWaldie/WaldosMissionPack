/*
 * Author: Waldo
 * Applies the shared WMP presentation and lifecycle guard to the original interaction challenge
 * displays while preserving their established game-state and configuration contracts.
 *
 * Arguments:
 * _display   - Display - challenge display to decorate
 * _inputHint - String  - concise control reminder
 * _name      - String  - challenge name for HOW TO PLAY
 * _objective - String  - objective for HOW TO PLAY
 * _hint      - String  - strategy hint for HOW TO PLAY
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_display, "Mouse: choose a wire"] call Waldo_fnc_MiniGameChallengeUILegacy;
 */

disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_inputHint", "Use the mouse to interact", [""]],
    ["_name", "CHALLENGE", [""]],
    ["_objective", "Complete the interaction.", [""]],
    ["_hint", "Watch the status line after every input.", [""]]
];
if (isNull _display) exitWith {};
private _upperName = toUpper _name;
private _fallbackId = if (_upperName find "MINE" >= 0 || {_upperName find "TRIGGER" >= 0}) then {"minesweeper"} else {
    if (_upperName find "KEY" >= 0 || {_upperName find "ACCESS" >= 0}) then {"keypad"} else {
        if (_upperName find "LOCK" >= 0 || {_upperName find "CYLINDER" >= 0}) then {"lockpick"} else {
            if (_upperName find "CIRCUIT" >= 0 || {_upperName find "BREAKER" >= 0}) then {"circuit"} else {"wirecut"};
        };
    };
};
private _profile = missionNamespace getVariable ["Waldo_IMG_ActiveProfile", [_fallbackId, []] call Waldo_fnc_MiniGameEquipmentProfile];
private _accent = _profile getOrDefault ["accent", [0.82, 0.58, 0.18, 1]];
private _casing = _profile getOrDefault ["casing", [0.16, 0.17, 0.15, 1]];
_display setVariable ["Waldo_IMG_Profile", _profile];
_display setVariable ["Waldo_IMG_AbortPending", false];
_display setVariable ["Waldo_IMG_Started", false];
_display setVariable ["Waldo_IMG_Bounds", [safezoneX + 0.12 * safezoneW, safezoneY + 0.055 * safezoneH, 0.76 * safezoneW, 0.87 * safezoneH]];
_display setVariable ["Waldo_IMG_ShowResult", {
    params ["_disp", "_success", ["_resultKey", ""]];
    private _profile = _disp getVariable ["Waldo_IMG_Profile", createHashMap];
    if ((_profile getOrDefault ["soundProfile", "equipment"]) != "silent") then {
        playSound (if (_success) then {"FD_Finish_F"} else {"FD_CP_Not_Clear_F"});
    };
    private _result = _disp getVariable ["Waldo_IMG_LegacyResult", controlNull];
    if (!isNull _result) then {
        private _caption = if (_disp getVariable ["Waldo_IMG_AudioCaptions", true] && {(_profile getOrDefault ["soundProfile", "equipment"]) != "silent"}) then {if (_success) then {"  [AUDIO: CONFIRMATION TONE]"} else {"  [AUDIO: FAULT TONE]"}} else {""};
        if (_resultKey == "") then {_resultKey = if (_success) then {"successText"} else {"failureText"};};
        private _text = _profile getOrDefault [_resultKey, if (_success) then {"PROCEDURE COMPLETE"} else {"PROCEDURE FAILED"}];
        _result ctrlSetText format ["%1  %2%3", if (_success) then {"[OK]"} else {"[X]"}, _text, _caption];
        _result ctrlSetTextColor if (_success) then {_disp getVariable ["Waldo_IMG_ColourOK", [0.25, 0.72, 0.90, 1]]} else {_disp getVariable ["Waldo_IMG_ColourBad", [0.86, 0.36, 0.72, 1]]};
        _result ctrlSetBackgroundColor [0.025, 0.03, 0.03, 0.97];
        _result ctrlShow true;
        ctrlSetFocus _result;
    };
}];
if (_profile getOrDefault ["customTitle", false]) then {
    _name = _profile getOrDefault ["title", _name];
} else {
    _profile set ["title", _name];
};
_objective = _profile getOrDefault ["objective", _objective];
private _profileControls = _profile getOrDefault ["controls", ""];
if (_profileControls != "") then {_inputHint = _profileControls;};
private _profileHint = _profile getOrDefault ["hint", ""];
if (_profileHint != "") then {_hint = _profileHint;};

private _shade = _display ctrlCreate ["RscText", -1];
_shade ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
_shade ctrlSetBackgroundColor [0, 0, 0, 0.58];
_shade ctrlCommit 0;

private _equipment = _display ctrlCreate ["RscText", -1];
_equipment ctrlSetPosition [safezoneX + 0.12 * safezoneW, safezoneY + 0.055 * safezoneH, 0.76 * safezoneW, 0.87 * safezoneH];
_equipment ctrlSetBackgroundColor _casing;
_equipment ctrlCommit 0;

private _texturePath = _profile getOrDefault ["texture", ""];
if (_texturePath != "") then {
    private _texture = _display ctrlCreate ["RscPicture", -1];
    _texture ctrlSetPosition [safezoneX + 0.12 * safezoneW, safezoneY + 0.055 * safezoneH, 0.76 * safezoneW, 0.87 * safezoneH];
    _texture ctrlSetText _texturePath;
    _texture ctrlSetTextColor [1, 1, 1, _profile getOrDefault ["textureOpacity", 0.14]];
    _texture ctrlCommit 0;
};

private _plate = _display ctrlCreate ["RscStructuredText", -1];
_plate ctrlSetPosition [safezoneX + 0.15 * safezoneW, safezoneY + 0.07 * safezoneH, 0.70 * safezoneW, 0.06 * safezoneH];
_plate ctrlSetStructuredText parseText format ["<t size='1.25' color='#EEE9D8'>%1</t><br/><t size='0.72' color='#9C9D8F'>%2  //  %3</t>", _name, _profile getOrDefault ["manufacturer", "FIELD SYSTEMS"], _profile getOrDefault ["model", "UNIT"]];
_plate ctrlSetBackgroundColor [0.055, 0.06, 0.055, 0.98];
_plate ctrlCommit 0;

private _topAccent = _display ctrlCreate ["RscText", -1];
_topAccent ctrlSetPosition [safezoneX, safezoneY, safezoneW, 0.004 * safezoneH];
_topAccent ctrlSetBackgroundColor _accent;
_topAccent ctrlCommit 0;

private _footer = _display ctrlCreate ["RscStructuredText", -1];
_footer ctrlSetPosition [safezoneX + 0.04 * safezoneW, safezoneY + safezoneH - 0.055 * safezoneH, safezoneW - 0.08 * safezoneW, 0.045 * safezoneH];
_footer ctrlSetBackgroundColor [0.055, 0.06, 0.055, 0.97];
_footer ctrlSetStructuredText parseText format [
    "<t align='left' color='#DDD8C8'>%1</t><t align='right' color='#F2BE55'>ESC TWICE: ABORT  [FAILURE]</t>",
    _inputHint
];
_footer ctrlCommit 0;

_display displayAddEventHandler ["Unload", {
    params ["_disp"];
    if ((missionNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull]) isEqualTo _disp) then {
        missionNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
    };
}];

_display setVariable ["Waldo_IMG_RequestAbort", {
    params ["_disp", "_finish"];
    if !(_disp getVariable ["Waldo_IMG_AbortPending", false]) exitWith {
        _disp setVariable ["Waldo_IMG_AbortPending", true];
        private _profile = _disp getVariable ["Waldo_IMG_Profile", createHashMap];
        hintSilent format ["WARNING: press Escape again within 3 seconds. %1", _profile getOrDefault ["abortText", "Aborting counts as a failed procedure."]];
        [_disp] spawn {params ["_d"]; uiSleep 3; if (!isNull _d) then {_d setVariable ["Waldo_IMG_AbortPending", false];};};
    };
    [_disp, false] call _finish;
}];

[_display, _name, _objective, _inputHint, _hint] call Waldo_fnc_MiniGameChallengeHelp;
