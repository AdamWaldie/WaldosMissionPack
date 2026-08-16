/*
 * Author: WaldoTheWarfighter
 * Introduction / title text overlay - shows a styled intro (mission name, location, date, time).
 * With no overrides it auto-derives the title from description.ext and the location from worldName.
 * Registered as Waldo_fnc_InfoText. Called automatically, once, from initPlayerLocal.sqf.
 *
 * Content and timing are mission-maker settings in MissionConfig\interfaceConfig.sqf
 * (Waldo_InfoText_Title, Waldo_InfoText_Locale, Waldo_InfoText_LongDate, Waldo_InfoText_Animation,
 * Waldo_InfoText_FakeLoadHold, Waldo_InfoText_SkipFakeLoad) - edit those instead of this file. The
 * four positional arguments below still exist only for a one-off custom call (for example a trigger
 * that wants a different title mid-mission without touching the mission-wide config); each falls
 * back to its configured value when omitted.
 *
 * Arguments:
 * 0: _title <STRING> - mission title override (optional, default: Waldo_InfoText_Title)
 * 1: _locale <STRING> - location override (optional, default: Waldo_InfoText_Locale)
 * 2: _longDate <BOOL> - long date format ("1st November 2010") vs short ("01/11/2010") (optional, default: Waldo_InfoText_LongDate)
 * 3: _anim <STRING> - text animation style (optional, default: Waldo_InfoText_Animation)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] spawn Waldo_fnc_InfoText;
 * ["Operation Iron Fist", "Altis"] spawn Waldo_fnc_InfoText; // one-off override, e.g. from a trigger
 */

params[
    ["_title", missionNamespace getVariable ["Waldo_InfoText_Title", ""]],
    ["_locale", missionNamespace getVariable ["Waldo_InfoText_Locale", ""]],
    ["_longDate", missionNamespace getVariable ["Waldo_InfoText_LongDate", false]],
    ["_anim", missionNamespace getVariable ["Waldo_InfoText_Animation", "NONE"]]
];

missionNamespace setVariable ["Waldo_InfoText_Active", true];
missionNamespace setVariable ["Waldo_InfoText_Complete", false];

// Client-local timing capture for Waldo_fnc_RunDiagnosticsClient's "mission-flow"/"infotext-timing"
// check. Every stage is a real diag_tickTime delta, not a guess, so a mission maker reporting a slow
// or mistimed intro can be pointed at the exact stage (display wait, fake-load hold, feature-init
// wait, and so on) instead of the whole sequence being one opaque block. Not broadcast - this is a
// per-client observation, and each player's own load-in timing is independent.
private _tStart = diag_tickTime;
missionNamespace setVariable ["Waldo_InfoText_Timings", createHashMapFromArray [["startedAt", _tStart]]];

waitUntil {!isNull findDisplay 46};
private _tDisplay = diag_tickTime;
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

// findDisplay 46 (above) and time > 0 are both mission/global-state signals - "the mission has
// actually started" from the engine's synchronised standpoint - not a per-client "this machine has
// finished streaming its own textures/models in" signal. Arma has no such signal exposed to SQF: a
// client (especially a heavier mod/terrain setup, or one joining a session already running) can
// legitimately have both of those true while it is still individually streaming assets in, which is
// the real loading screen/pop-in a player can still see for a few seconds after this point - not our
// own fauxLoad screen below, and not something any waitUntil condition here can detect completing.
// time > 1 instead of the previous > 0 is a small, still-imperfect improvement: `time` can tick to a
// negligible epsilon almost immediately even on a client that is still heavily loading, so a full
// second is a more realistic floor than "any nonzero value" without pretending it's a real signal.
waitUntil { uiSleep 0.2; (!isNull player && time > 1) };
private _tPlayerReady = diag_tickTime;

// ----- COMPLILE INFO AND DISPLAY TO PLAYER -----
// Throw up our own fake loading screen purely as a cinematic transition into the intro below.
//
// Timing below is deliberately tight: control returns to the player as soon as the content actually
// needs (readable text + a chosen animation finishing cleanly), not on padded guesswork. Two
// exceptions are kept intentionally generous rather than cut to the bone:
//  - FAKE_LOAD_HOLD is this script's only real mitigation for the per-client streaming gap explained
//    above: extra time, after the best available "mission has started" signals, for a heavier client
//    to actually catch up before the intro text starts drawing over it. It is a guess, not a
//    guarantee - there is no reliable SQF signal for "this client's streaming has fully settled", so
//    the right guess depends entirely on this mission's own terrain/mod list. Set
//    Waldo_InfoText_FakeLoadHold in MissionConfig\interfaceConfig.sqf to override the shipped default
//    per mission instead of editing this file - the default here is a moderate assumption, not a
//    measurement of any specific mission's actual settle time. Raise it first if the world still
//    looks like it's loading when the title text appears.
//  - The final wait below for WALDO_INIT_COMPLETE: initPlayerLocal.sqf now spawns this script instead of
//    calling it (so server/feature startup - crates, jamming, safestart, Dynamic AA, etc. - runs in
//    parallel with this intro, not after it), which means this intro can no longer be assumed to
//    outlast that startup. disableUserInput stays true until whichever finishes last, so a fast
//    reader on a fast-loading mission still can't reach a crate/feature before it exists.
private _fakeLoadHold = missionNamespace getVariable ["Waldo_InfoText_FakeLoadHold", 5]; // was 9 originally, 2.5 in the previous pass - too short for a modded client's real streaming time
private _blackoutFade = 1;       // was 5
// Must be >= _blackoutFade: endLoadingScreen below reveals whatever is behind the loading screen, so
// the blackout fade needs to have actually finished fading to black before that happens - otherwise
// (as originally reported) the still-transitioning fade is what's visible when the screen ends, and
// the text reveal below (which starts right after) reads as starting before the load screen is done.
// Derived from _blackoutFade rather than a second independent number so shortening the fade can never
// silently reopen this gap again.
private _postBlackoutBuffer = _blackoutFade + 0.1;
private _postLoadBuffer = 0.75;  // was 5 - lets the now-black screen settle before text starts drawing
private _blackInFade = 1;        // was 3
private _featureInitTimeout = 60; // bounded safety cap on the WALDO_INIT_COMPLETE wait below

// Waldo_InfoText_SkipFakeLoad (default false): skips the fake loading screen and both fades below
// entirely, going straight from the readiness wait above into the text reveal drawn directly over
// whatever is currently on screen. Primarily a diagnostic switch - it isolates whether streaming
// pop-in is visible with none of WMP's own presentation covering it, useful for telling apart "our
// transition is timed wrong" from "the world genuinely is not settled yet" - but also a legitimate
// permanent choice for a mission maker who wants no loading-screen presentation at all. blackIn below
// is skipped along with it, since it has no matching blackOut to reverse when this is set.
private _skipFakeLoad = missionNamespace getVariable ["Waldo_InfoText_SkipFakeLoad", false];
if (_skipFakeLoad) then {
    diag_log "[WMP INFOTEXT] Waldo_InfoText_SkipFakeLoad is true - fake loading screen and fades skipped.";
} else {
    ["fauxLoad", ""] call BIS_fnc_startLoadingScreen;
    uiSleep _fakeLoadHold;
    ["wakeUpID", false, _blackoutFade] call BIS_fnc_blackOut; // Fade screen out to black for intro sequence.
    uiSleep _postBlackoutBuffer;
    "fauxLoad" call BIS_fnc_endLoadingScreen; // End fake loading screen and begin displaying text.
    uiSleep _postLoadBuffer;
};
private _tFakeLoadDone = diag_tickTime;

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

// This intro no longer gates WALDO_INIT_COMPLETE (init.sqf spawns it), so it can finish before
// server/feature startup does on a fast-loading mission. Wait for that flag before the text reveal
// starts (not just before control returns, as an earlier pass had it) - bounded so a mission that
// never sets it (broken init.sqf) doesn't hold the intro forever.
//
// This ordering fix closes a real bug, root-caused from an actual playtest RPT, not a guess: the
// text reveal below used to be spawned immediately here and run fully detached from control-return,
// on BIS_fnc_typeText's own few-second timeline - deliberately, so reading it never delayed getting
// control back. But init.sqf's own mandatory `sleep 10` before it sets WALDO_INIT_COMPLETE (a
// pre-existing, unrelated buffer, well outside this script) reliably takes far longer than that
// timeline. The detached text thread would start, run to completion and vanish while still blocked
// waiting on this same flag lower down - "the text has already finished by the time the player is
// actually there", confirmed against an RPT showing WMP's own init.sqf systems (jamming, ACRE, ZEN,
// loadout, etc.) all completing within about a second of CBA's postinit, and Dynamic AA's queued
// system materialising (gated on WALDO_INIT_COMPLETE) only firing roughly ten seconds later - the
// exact width of that sleep 10, not real engine asset streaming. Starting the text reveal only once
// this wait clears means it can no longer finish before the player has any chance to see it.
private _featureInitDeadline = diag_tickTime + _featureInitTimeout;
waitUntil {
    uiSleep 0.2;
    missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] || {diag_tickTime >= _featureInitDeadline}
};
if !(missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]) then {
    diag_log "[WMP INFOTEXT] WALDO_INIT_COMPLETE never became true within the timeout; releasing player input anyway.";
};

// Text reveal is purely cosmetic and reads fine whether or not the player already has control back
// (a title card over live gameplay is a normal pattern), so it still runs on its own detached
// timeline rather than blocking control return below - only its START moved, not this. scriptDone on
// the returned handle is polled further down purely to keep Waldo_InfoText_Active/Complete accurate
// (gunshipNotifyLocal.sqf/fieldResupplyNotifyGrantLocal.sqf defer their own notices on it so nothing
// draws over this text) - it is never waited on before returning control.
_text1 = str composeText ["<t align = 'center' shadow = '1' size = '1.0' font='PuristaBold' color=", _textColour, ">%1</t><br/>"];
_text2 = "<t align = 'center' shadow = '1' size = '0.8' color='#808080'>%1</t><br/>";
_text3 = "<t align = 'center' shadow = '1' size = '0.7'>%1</t>";

_textRevealHandle = [_time, _date, _missionTitle, _localePos, _groupInfo, _text1, _text2, _text3] spawn {
    params ["_time", "_date", "_missionTitle", "_localePos", "_groupInfo", "_text1", "_text2", "_text3"];
    // BIS_fnc_typeText owns its own complete reveal-and-hold timeline once spawned - confirmed against
    // respawnText.sqf, which spawns an equivalent block and the script simply ends right after with no
    // wait at all, and the text still displays correctly. A guessed uiSleep here to "give it time to be
    // read" was never actually controlling how long the text stays up; it only controlled how soon the
    // NEXT block/phase started, and a guess shorter than the real animation cuts the current block off
    // mid-reveal - exactly the "cuts halfway between the text being sequenced" bug reported after
    // in-game testing. waitUntil {scriptDone} on the real handle instead of guessing removes this
    // class of bug entirely, the same fix already applied to the blackout/buffer race above.
    private _block1Handle = [
        [
            [_time, "<t align = 'center' shadow = '1' size = '1.0'>%1</t><br/>"],
            [_date, "<t align = 'center' shadow = '1' size = '0.7' font='PuristaBold'>%1</t><br/>", 2]
        ]
    ] spawn BIS_fnc_typeText;
    waitUntil { uiSleep 0.2; scriptDone _block1Handle };

    private _block2Handle = [
        [
            [_missionTitle, _text1],
            [_localePos, _text2],
            [_groupInfo, _text3, 1.5]
        ]
    ] spawn BIS_fnc_typeText;
    waitUntil { uiSleep 0.2; scriptDone _block2Handle };
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
private _featureInitTimedOut = !(missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]);
if (_featureInitTimedOut) then {
    diag_log "[WMP INFOTEXT] WALDO_INIT_COMPLETE never became true within the timeout; releasing player input anyway.";
};
private _tFeatureInitDone = diag_tickTime;

if !(_skipFakeLoad) then {
    ["wakeUpID", true, _blackInFade] call BIS_fnc_blackIn;
};
disableUserInput false;
private _tControlReturned = diag_tickTime;

// Active/Complete track the on-screen text, not player control - wait for the detached reveal above
// to actually finish before flipping them, so a notification deferred on Waldo_InfoText_Complete
// still never draws over still-typing intro text even though control returned earlier.
waitUntil { uiSleep 0.2; scriptDone _textRevealHandle };
private _tComplete = diag_tickTime;
missionNamespace setVariable ["Waldo_InfoText_Active", false];
missionNamespace setVariable ["Waldo_InfoText_Complete", true];

// Final timing snapshot for diagnostics. Each *Wait key is that specific stage's own duration (not a
// running total), so a mission maker can see exactly which stage is slow: display readiness, the
// per-client streaming-settle wait, the fake loading screen/fades, feature startup, then how long the
// text itself kept typing after control was already returned.
missionNamespace setVariable ["Waldo_InfoText_Timings", createHashMapFromArray [
    ["startedAt", _tStart],
    ["displayWait", _tDisplay - _tStart],
    ["playerReadyWait", _tPlayerReady - _tDisplay],
    ["fakeLoadWait", _tFakeLoadDone - _tPlayerReady],
    ["featureInitWait", _tFeatureInitDone - _tFakeLoadDone],
    ["featureInitTimedOut", _featureInitTimedOut],
    ["controlReturnedAt", _tControlReturned - _tStart],
    ["textRevealAfterControl", _tComplete - _tControlReturned],
    ["totalToComplete", _tComplete - _tStart]
]];
