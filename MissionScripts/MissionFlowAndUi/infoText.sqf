/*
 * Author: WaldoTheWarfighter
 * Introduction / title text overlay - shows a styled intro (mission name, location, date, time).
 * With no overrides it auto-derives the title from description.ext and the location from worldName.
 * Registered as Waldo_fnc_InfoText.
 *
 * Arguments:
 * 0: _title <STRING> - mission title override (optional, default: "" = from description.ext)
 * 1: _locale <STRING> - location override (optional, default: "" = from worldName)
 * 2: _longDate <BOOL> - long date format ("1st November 2010") vs short ("01/11/2010") (optional, default: false)
 * 3: _anim <STRING> - text animation style (optional, default: "NONE")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["", ""] spawn Waldo_fnc_InfoText;
 */

params[["_title",""],["_locale",""],["_longDate",false],["_anim","NONE"]];

missionNamespace setVariable ["Waldo_InfoText_Active", true];
missionNamespace setVariable ["Waldo_InfoText_Complete", false];

waitUntil {!isNull findDisplay 46};
//Grab Mission Name & Terrain Name automatically
//If provided with a string in the correct parameter slot, accepts that inplace of the automatic generation
_missionTitle = getText (missionConfigFile >> "onLoadName");; 
if (_title != "") then {
    _missionTitle = _title;
};
_localeName = worldName;
if (_locale != "") then {
    _localeName = _locale;
};
_animate = "NONE";
if (_anim != "NONE") then {
    _animate = _anim;
};

//No runnin' off..
disableUserInput true;

// ----- DATE SETTING -----
_date = if (_longDate) then {


    _dateOW = [date select 0,date select 1,date select 2,0,0];
    _yearBefore = ((_dateOW select 0)-1) max 0;
    _qttLeapYears = floor (_yearBefore/4);
    _qttNormalYears = _yearBefore-_qttLeapYears;
    _daysOW = _qttNormalYears+_qttLeapYears*(366/365);
    _daysOW = _daysOW+dateToNumber _dateOW;
    _dayOfWeekNo = (round (_daysOW/(1/365))) mod 7;

    _dayOfWeek = switch (_dayOfWeekNo) do{
        case 0: {"Sunday"};
        case 1: {"Monday"};
        case 2: {"Tuesday"};
        case 3: {"Wednesday"};
        case 4: {"Thursday"};
        case 5: {"Friday"};
        case 6: {"Saturday"};
        default {""};
    };

    _dayExt = switch (date select 2) do {
        case 1: {"st"};
        case 2: {"nd"};
        case 3: {"rd"};
        case 21: {"st"};
        case 22: {"nd"};
        case 23: {"rd"};
        case 31: {"st"};
        default {"th"};
    };

    _day = str (date select 2) + _dayExt;

    _month = switch (date select 1) do {
        case 1: {"January"};
        case 2: {"February"};
        case 3: {"March"};
        case 4: {"April"};
        case 5: {"May"};
        case 6: {"June"};
        case 7: {"July"};
        case 8: {"August"};
        case 9: {"September"};
        case 10: {"October"};
        case 11: {"November"};
        case 12: {"December"};
        default {date select 2};
    };

    _dayOfWeek + ' ' + _day + ' ' + _month + ' ' + str (date select 0);

} else {
    str (date select 2) + '/' + str (date select 1) + '/' + str (date select 0);
};

// Use the below parameter to overwrite the date - useful for fictional dates in Star Wars or Warhammer 40k. Put your date inbetween the 2 quotation marks.
//_date = "";

// ----- TIME SETTING -----
_timeConfig = [dayTime, "ARRAY"] call BIS_fnc_timeToString; 
_time = (_timeConfig select 0) + (_timeConfig select 1) + ' hrs';

// ----- LOCATION SETTING -----
_missionTime = str (time/60);
_localePos = 'Grid ' + mapGridPosition player + ', ' + _localeName; 
_groupInfo = rank player + ' ' + name player + ', ' + groupID (group player);

// ---- TEXT FORMATTING -----
_textColour = switch (side player) do
{
    case west: {"'#0055aa'"};
    case east: {"'#770000'"};
    case resistance: {"'#008e00'"};
    case civilian: {"'#65007e'"};
    default {"'#ed9d18'"};
};

waitUntil { uiSleep 0.2; (!isNull player && time > 0) };

// ----- COMPLILE INFO AND DISPLAY TO PLAYER -----
// Throw up a fake loading screen to buffer over actual loading screen.
//
// Timing below is deliberately tight: control returns to the player as soon as the content actually
// needs (readable text + a chosen animation finishing cleanly), not on padded guesswork. Two
// exceptions are kept intentionally generous rather than cut to the bone:
//  - FAKE_LOAD_HOLD masks real asset streaming (models/textures still loading in), not our own
//    presentation - too short here risks revealing pop-in on a heavy mod list, so tune this one up
//    per mission rather than trusting the shipped default blindly.
//  - The final wait below for WALDO_INIT_COMPLETE: init.sqf now spawns this script instead of
//    calling it (so server/feature startup - crates, jamming, safestart, Dynamic AA, etc. - runs in
//    parallel with this intro, not after it), which means this intro can no longer be assumed to
//    outlast that startup. disableUserInput stays true until whichever finishes last, so a fast
//    reader on a fast-loading mission still can't reach a crate/feature before it exists.
private _fakeLoadHold = 2;       // was 9 - pure padding; real streaming margin, tune per mission/modlist
private _blackoutFade = 1;       // was 5
// Must be >= _blackoutFade: endLoadingScreen below reveals whatever is behind the loading screen, so
// the blackout fade needs to have actually finished fading to black before that happens - otherwise
// (as originally reported) the still-transitioning fade is what's visible when the screen ends, and
// the text reveal below (which starts right after) reads as starting before the load screen is done.
// Derived from _blackoutFade rather than a second independent number so shortening the fade can never
// silently reopen this gap again.
private _postBlackoutBuffer = _blackoutFade + 0.1;
private _postLoadBuffer = 0.5;   // was 5
private _textBlock1Hold = 3;     // was 6 - time/date line, short text, quick to read
private _textBlock2Hold = 2.5;   // was 3 - title/locale/group lines
private _blackInFade = 1;        // was 3
private _featureInitTimeout = 60; // bounded safety cap on the WALDO_INIT_COMPLETE wait below

["fauxLoad", ""] call BIS_fnc_startLoadingScreen;
uiSleep _fakeLoadHold;
["wakeUpID", false, _blackoutFade] call BIS_fnc_blackOut; // Fade screen out to black for intro sequence.
uiSleep _postBlackoutBuffer;
"fauxLoad" call BIS_fnc_endLoadingScreen; // End fake loading screen and begin displaying text.

uiSleep _postLoadBuffer;

// ----- ANIMATION SETTING -----
// Triggered here, in parallel with the text reveal below, instead of only after it - so total wait
// is however long the LONGER of "an animation finished cleanly" or "feature init is ready" takes,
// not the sum of everything. Only WALK/SIT/COFFIN have a defined return-to-standing duration.
_unit = player;
_animationDurations = createHashMapFromArray [["WALK", 8.333], ["SIT", 8.666], ["COFFIN", 6.666]];
_animationStart = diag_tickTime;
// Determine animation to use from given Params
_usedAnimation = switch (_animate) do {
    case "NONE": {};

    case "WALK": {
        [_unit] spawn {
            params ["_unit"];
            [_unit, "Acts_welcomeOnHUB02_PlayerWalk_1"] remoteExec ["switchMove", 0];
            sleep 8.333;
            [_unit, "AmovPercMstpSlowWrflDnon"] remoteExec ["switchMove", 0];
        };
    };

    case "SIT": {
        [_unit] spawn {
            params ["_unit"];
            [_unit, "AmovPsitMstpSrasWrflDnon_WeaponCheck1"] remoteExec ["switchMove", 0];
            sleep 8.666;
            [_unit, "AmovPsitMstpSrasWrflDnon_AmovPercMstpSlowWrflDnon"] remoteExec ["switchMove", 0];
        };
    };

    case "WAKE" : {
        [_unit] spawn {
            params ["_unit"];
            [_unit, "Acts_Waking_Up_Player"] remoteExec ["switchMove", 0];
        };
    };

    case "WAKESLOW" : {
        [_unit] spawn {
            params ["_unit"];
            [_unit, "Acts_UnconsciousStandUp_part1"] remoteExec ["switchMove", 0];
        };
    };

    case "COFFIN" : {
        [_unit] spawn {
            params ["_unit"];
            [_unit, "Acts_Undead_Coffin"] remoteExec ["switchMove", 0];
            sleep 6.666;
            [_unit, "AmovPercMstpSlowWrflDnon"] remoteExec ["switchMove", 0];
        };
    };

    default {};
};

// Text reveal is purely cosmetic and reads fine whether or not the player already has control back
// (a title card over live gameplay is a normal pattern), so it runs on its own detached timeline
// instead of blocking control return - the only thing that still needs to block is protecting a
// chosen movement animation and giving feature init a chance to finish (both below). scriptDone on
// the returned handle is polled further down purely to keep Waldo_InfoText_Active/Complete accurate
// (gunshipNotifyLocal.sqf/fieldResupplyNotifyGrantLocal.sqf defer their own notices on it so nothing
// draws over this text) - it is never waited on before returning control.
_text1 = str composeText ["<t align = 'center' shadow = '1' size = '1.0' font='PuristaBold' color=", _textColour, ">%1</t><br/>"];
_text2 = "<t align = 'center' shadow = '1' size = '0.8' color='#808080'>%1</t><br/>";
_text3 = "<t align = 'center' shadow = '1' size = '0.7'>%1</t>";

_textRevealHandle = [_time, _date, _missionTitle, _localePos, _groupInfo, _text1, _text2, _text3, _textBlock1Hold, _textBlock2Hold] spawn {
    params ["_time", "_date", "_missionTitle", "_localePos", "_groupInfo", "_text1", "_text2", "_text3", "_textBlock1Hold", "_textBlock2Hold"];
    [
        [
            [_time, "<t align = 'center' shadow = '1' size = '1.0'>%1</t><br/>"],
            [_date, "<t align = 'center' shadow = '1' size = '0.7' font='PuristaBold'>%1</t><br/>", 10]
        ]
    ] spawn BIS_fnc_typeText;
    uiSleep _textBlock1Hold;

    [
        [
            [_missionTitle, _text1],
            [_localePos, _text2],
            [_groupInfo, _text3, 5]
        ]
    ] spawn BIS_fnc_typeText;
    uiSleep _textBlock2Hold;
};

// Give WALK/SIT/COFFIN's own switchMove sequence its full duration - unlocking input mid-animation
// would let the player interrupt/desync from it. NONE (and WAKE/WAKESLOW, which have no defined
// return-to-standing duration to wait for) fall straight through with no added wait here.
_animationDuration = _animationDurations getOrDefault [_animate, 0];
_animationRemaining = _animationDuration - (diag_tickTime - _animationStart);
if (_animationRemaining > 0) then {
    uiSleep _animationRemaining;
};

// This intro no longer gates WALDO_INIT_COMPLETE (init.sqf spawns it), so it can finish before
// server/feature startup does on a fast-loading mission. Hold the lock until that flag is up too,
// bounded so a mission that never sets it (broken init.sqf) doesn't lock the player out forever.
private _featureInitDeadline = diag_tickTime + _featureInitTimeout;
waitUntil {
    uiSleep 0.2;
    missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] || {diag_tickTime >= _featureInitDeadline}
};
if !(missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]) then {
    diag_log "[WMP INFOTEXT] WALDO_INIT_COMPLETE never became true within the timeout; releasing player input anyway.";
};

["wakeUpID", true, _blackInFade] call BIS_fnc_blackIn;
disableUserInput false;

// Active/Complete track the on-screen text, not player control - wait for the detached reveal above
// to actually finish before flipping them, so a notification deferred on Waldo_InfoText_Complete
// still never draws over still-typing intro text even though control returned earlier.
waitUntil { uiSleep 0.2; scriptDone _textRevealHandle };
missionNamespace setVariable ["Waldo_InfoText_Active", false];
missionNamespace setVariable ["Waldo_InfoText_Complete", true];
