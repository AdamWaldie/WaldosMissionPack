/*
 * Author: WaldoTheWarfighter
 * Introduction / title text overlay - shows a styled intro (mission name, location, date, time).
 * With no overrides it auto-derives the title from description.ext and the location from worldName.
 * Registered as Waldo_fnc_InfoText. Called automatically, once, from initPlayerLocal.sqf.
 *
 * Locality / lifecycle: interface client only. The automatic call is spawned after PLAYER_LOCAL
 * configuration has loaded. initPlayerLocal.sqf synchronously records the engine's first local
 * PreloadFinished mission event; this worker waits for that event, then immediately opens WMP's own
 * cover (before waiting on the local player/display, so the real loading screen is never visibly
 * followed by a gap before WMP's cover appears) and only starts the title text once the player/display
 * are also ready. It never changes authoritative state and does not rerun on respawn. The fake screen
 * is paired by ID and every readiness wait is bounded so a broken client cannot be locked indefinitely.
 * Player control is no longer held for cosmetic text, optional animations or unrelated feature init.
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
// or mistimed intro can be pointed at the exact stage (engine readiness, fake cover and title reveal)
// instead of the whole sequence being one opaque block. Not broadcast - this is a
// per-client observation, and each player's own load-in timing is independent.
private _tStart = diag_tickTime;
missionNamespace setVariable ["Waldo_InfoText_Timings", createHashMapFromArray [["startedAt", _tStart]]];

// The engine's first local PreloadFinished event is the authority for the mission preload screen
// ending. BRIEFING READ, BIS_fnc_init and `time` all become available earlier and therefore cannot
// prove that title text is visible. initPlayerLocal registers the event synchronously before doing
// any other local setup and removes its handler after the first event, because PreloadFinished also
// fires after a player closes the map later in the mission.
private _preloadDeadline = diag_tickTime + 120;
waitUntil {
    uiSleep 0.05;
    missionNamespace getVariable ["Waldo_InfoText_InitialPreloadFinished", false]
    || {diag_tickTime >= _preloadDeadline}
};
private _preloadObserved = missionNamespace getVariable ["Waldo_InfoText_InitialPreloadFinished", false];
private _tPreloadFinished = diag_tickTime;

// Waldo_InfoText_SkipFakeLoad (default false): skips the fake loading screen and both fades below
// entirely, going straight from the readiness wait into the text reveal drawn directly over whatever
// is currently on screen. Read here (rather than only later) so the cover can be started immediately
// below, right as the engine's own preload phase ends.
private _skipFakeLoad = missionNamespace getVariable ["Waldo_InfoText_SkipFakeLoad", false];

// Start WMP's own cover the instant the engine's real preload screen is done, before waiting below
// on display/player readiness. That readiness wait can itself take a visible moment (observed
// live), and previously WMP's cover only started after it - so the real loading screen would fade
// out, briefly reveal the world, and only then be visibly replaced by WMP's fake screen a moment
// later. Starting the cover here closes that gap; it is closed again below if readiness never
// completes, so a broken client is never left staring at a stuck black screen.
private _fakeLoadStarted = _preloadObserved && {!_skipFakeLoad};
if (_fakeLoadStarted) then {
    ["WMP_InfoText_FauxLoad", ""] call BIS_fnc_startLoadingScreen;
};

// The event precedes this scheduled worker resuming. Give the UI one scheduler hand-off, then only
// require the actual in-game display and local player object used by the title.
uiSleep 0.05;
private _clientReadyDeadline = diag_tickTime + 30;
waitUntil {
    uiSleep 0.05;
    (!isNull findDisplay 46 && {!isNull player} && {local player})
    || {diag_tickTime >= _clientReadyDeadline}
};
private _clientReady = !isNull findDisplay 46
    && {!isNull player}
    && {local player};
private _clientStateAtRelease = getClientStateNumber;

if (!_preloadObserved || {!_clientReady}) exitWith {
    // The cover above was started as soon as preload finished, before this readiness check could
    // fail. Close it now so a broken/slow client is never left staring at a stuck black screen -
    // "without changing input" above refers to not holding control for the intro, not to leaving
    // WMP's own cover up.
    if (_fakeLoadStarted) then {
        "WMP_InfoText_FauxLoad" call BIS_fnc_endLoadingScreen;
    };
    diag_log format [
        "[WMP INFOTEXT] Playable preload readiness failed; intro skipped without changing input. preloadFinished=%1 display46=%2 player=%3 local=%4 clientState=%5.",
        _preloadObserved,
        !isNull findDisplay 46,
        !isNull player,
        !isNull player && {local player},
        _clientStateAtRelease
    ];
    missionNamespace setVariable ["Waldo_InfoText_Active", false];
    missionNamespace setVariable ["Waldo_InfoText_Complete", true];
    missionNamespace setVariable ["Waldo_InfoText_Timings", createHashMapFromArray [
        ["startedAt", _tStart],
        ["preloadWait", _tPreloadFinished - _tStart],
        ["preloadTimedOut", !_preloadObserved],
        ["clientReadyWait", diag_tickTime - _tPreloadFinished],
        ["clientReadyTimedOut", !_clientReady],
        ["clientStateAtRelease", _clientStateAtRelease]
    ]];
};
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

private _tPlayerReady = diag_tickTime;
diag_log format [
    "[WMP INFOTEXT] Visible intro starting after PreloadFinished. preloadWait=%1 clientReadyWait=%2 clientState=%3.",
    _tPreloadFinished - _tStart,
    _tPlayerReady - _tPreloadFinished,
    _clientStateAtRelease
];

// ----- COMPLILE INFO AND DISPLAY TO PLAYER -----
// WMP's fake screen is already up by this point (started right as the engine's preload finished, so
// the real loading screen is never visibly followed by a gap of exposed world before WMP's cover
// appears). This block is a short visual bridge that hides blackout/animation setup underneath it,
// not a guessed substitute for engine readiness. An explicit mission override may add a small hold,
// but the default adds no artificial delay.
private _fakeLoadHold = 0 max (missionNamespace getVariable ["Waldo_InfoText_FakeLoadHold", 0]);
private _blackoutFade = 0.2;     // short cover transition; setup should not delay play
// Must be >= _blackoutFade: endLoadingScreen below reveals whatever is behind the loading screen, so
// the blackout fade needs to have actually finished fading to black before that happens - otherwise
// (as originally reported) the still-transitioning fade is what's visible when the screen ends, and
// the text reveal below (which starts right after) reads as starting before the load screen is done.
// Derived from _blackoutFade rather than a second independent number so shortening the fade can never
// silently reopen this gap again.
private _postBlackoutBuffer = _blackoutFade + 0.05;
private _postLoadBuffer = 0.05;  // one UI hand-off after WMP's loading screen closes
private _blackInFade = 0.75;     // visual only; input is already available

// Waldo_InfoText_SkipFakeLoad (default false): skips the fake loading screen and both fades below
// entirely, going straight from the readiness wait above into the text reveal drawn directly over
// whatever is currently on screen. Primarily a diagnostic switch - it isolates whether streaming
// pop-in is visible with none of WMP's own presentation covering it, useful for telling apart "our
// transition is timed wrong" from "the world genuinely is not settled yet" - but also a legitimate
// permanent choice for a mission maker who wants no loading-screen presentation at all. blackIn below
// is skipped along with it, since it has no matching blackOut to reverse when this is set.
// The cover itself (BIS_fnc_startLoadingScreen) was already started right as preload finished, above -
// _skipFakeLoad and _fakeLoadStarted were read/computed there too, so only the hold/fade remain here.
if (_skipFakeLoad) then {
    diag_log "[WMP INFOTEXT] Waldo_InfoText_SkipFakeLoad is true - fake loading screen and fades skipped.";
} else {
    if (_fakeLoadHold > 0) then {uiSleep _fakeLoadHold};
    ["wakeUpID", false, _blackoutFade] call BIS_fnc_blackOut; // Fade screen out to black for intro sequence.
    uiSleep _postBlackoutBuffer;
};

// ----- ANIMATION SETTING -----
// Set up the optional animation while WMP's cover is still present. It never extends the input lock:
// the loading screen releases control immediately afterward and the player may interrupt a cosmetic
// animation. This hides the switchMove setup without delaying gameplay for the animation duration.
_unit = player;
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

// Close WMP's cover before starting either title block. endLoadingScreen restores normal scene/input;
// blackIn is only a visual fade and does not justify holding player control. The short UI hand-off
// prevents typeText being queued in the same instant as the loading display is destroyed.
if !(_skipFakeLoad) then {
    "WMP_InfoText_FauxLoad" call BIS_fnc_endLoadingScreen;
    uiSleep _postLoadBuffer;
    ["wakeUpID", true, _blackInFade] call BIS_fnc_blackIn;
};
private _tFakeLoadDone = diag_tickTime;
private _tControlReturned = diag_tickTime;

// The text starts only after the client is actually ready and WMP's cover has closed. It is cosmetic
// and runs while the player has control; unrelated feature readiness is deliberately not a gate.
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

// Active/Complete track the on-screen text, not player control - wait for the detached reveal above
// to actually finish before flipping them, so a notification deferred on Waldo_InfoText_Complete
// still never draws over still-typing intro text even though control returned earlier.
waitUntil { uiSleep 0.2; scriptDone _textRevealHandle };
private _tComplete = diag_tickTime;
diag_log format [
    "[WMP INFOTEXT] Intro text complete. controlReturnedAt=%1 textRevealAfterControl=%2 total=%3.",
    _tControlReturned - _tStart,
    _tComplete - _tControlReturned,
    _tComplete - _tStart
];
missionNamespace setVariable ["Waldo_InfoText_Active", false];
missionNamespace setVariable ["Waldo_InfoText_Complete", true];

// Final timing snapshot for diagnostics. Each *Wait key is that specific stage's own duration (not a
// running total), so a mission maker can see exactly which stage is slow: display readiness, the
// ready-to-play wait, WMP fake loading/fades, then how long the text kept typing after control was
// available. No value here is inferred from server time or unrelated feature initialization.
missionNamespace setVariable ["Waldo_InfoText_Timings", createHashMapFromArray [
    ["startedAt", _tStart],
    ["preloadWait", _tPreloadFinished - _tStart],
    ["preloadTimedOut", false],
    ["playerReadyWait", _tPlayerReady - _tPreloadFinished],
    ["clientReadyWait", _tPlayerReady - _tPreloadFinished],
    ["clientReadyTimedOut", false],
    ["clientStateAtRelease", _clientStateAtRelease],
    ["fakeLoadWait", _tFakeLoadDone - _tPlayerReady],
    ["controlReturnedAt", _tControlReturned - _tStart],
    ["textRevealAfterControl", _tComplete - _tControlReturned],
    ["totalToComplete", _tComplete - _tStart]
]];
