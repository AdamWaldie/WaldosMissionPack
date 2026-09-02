/*
 * Author: WaldoTheWarfighter
 * Cycles every built-in WMP visual theme through the production local resolver and notification
 * preview, emitting an RPT marker only after each themed frame has had time to render. This is an
 * audit-only interface-client sequence; it does not publish or change authoritative mission state.
 * It is repeat-safe through Waldo_QA_UiThemeGalleryCaptureRunning and restores the client's
 * authoritative theme after the final frame. JIP clients run it only when the staged audit mode is
 * THEME-GALLERY.
 *
 * Arguments: None.
 * Return Value: Nothing; asynchronously renders twenty theme previews, three-card queue/stack
 * previews in all six placements and the three player settings screens, then writes capture markers.
 * Current caller: auditInitPlayerLocal.sqf in a ThemeGallery audit launch.
 *
 * Example: [] execVM "runUiThemeGalleryCaptureClient.sqf";
 */
if (!hasInterface) exitWith {};
if (missionNamespace getVariable ["Waldo_QA_UiThemeGalleryCaptureRunning", false]) exitWith {};
missionNamespace setVariable ["Waldo_QA_UiThemeGalleryCaptureRunning", true];

waitUntil {
    uiSleep 0.2;
    !isNull player
    && {!isNil "Waldo_fnc_UiThemeApplyLocal"}
    && {!isNil "Waldo_fnc_ShowUiNotification"}
};

private _originalTheme = missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"];
private _originalOverrides = missionNamespace getVariable ["Waldo_UI_ThemeOverrides", createHashMap];
missionNamespace setVariable ["Waldo_UI_ThemeOverrides", createHashMapFromArray [
    ["accent", [1, 0, 0, 1]], ["accentHex", "#FF0000"],
    ["danger", [0.8, 0, 0, 1]], ["dangerHex", "#CC0000"]
]];
private _redProbe = ["DEFAULT", "STANDARD"] call Waldo_fnc_UiTheme;
private _redProbePassed = !((_redProbe getOrDefault ["accent", []]) isEqualTo [1, 0, 0, 1])
    && {!((_redProbe getOrDefault ["danger", []]) isEqualTo [0.8, 0, 0, 1])}
    && {(_redProbe getOrDefault ["accentHex", ""]) != "#FF0000"}
    && {(_redProbe getOrDefault ["dangerHex", ""]) != "#CC0000"};
missionNamespace setVariable ["Waldo_UI_ThemeOverrides", _originalOverrides];
diag_log format ["WMP UI THEME NO RED PROBE: pass=%1 accent=%2 danger=%3", _redProbePassed, _redProbe getOrDefault ["accentHex", ""], _redProbe getOrDefault ["dangerHex", ""]];
if (!_redProbePassed) exitWith {
    missionNamespace setVariable ["Waldo_QA_UiThemeGalleryCaptureRunning", false];
    diag_log "WMP UI THEME GALLERY ABORTED: no-red resolver probe failed";
};
private _themes = [
    "GRIMDARK", "ATOMIC_AGE", "WASTELAND", "PMC", "RETRO_COMMAND", "DIESELPUNK",
    "MERCENARY", "PROPAGANDA", "DEFAULT", "WW2", "VIETNAM", "SCIFI", "PARCHMENT",
    "MINIMAL", "NAVAL", "DESERT_STORM", "INDUSTRIAL", "EASTERN_BLOC", "INTELLIGENCE",
    "EMERGENCY"
];

diag_log format ["WMP UI THEME GALLERY START: count=%1", count _themes];
{
    private _themeId = _x;
    private _themeIndex = _forEachIndex + 1;
    [_themeId, true] call Waldo_fnc_UiThemeApplyLocal;
    uiSleep 1;
    diag_log format ["WMP UI THEME GALLERY FRAME READY: theme=%1 index=%2 count=%3", _themeId, _themeIndex, count _themes];
    uiSleep 4;
} forEach _themes;

[] call Waldo_fnc_ClearUiPanels;
["GRIMDARK", false] call Waldo_fnc_UiThemeApplyLocal;
{
    private _placement = _x;
    [] call Waldo_fnc_ClearUiPanels;
    {
        _x params ["_title", "_message", "_state", "_suffix"];
        [
            _title,
            _message,
            _state,
            0,
            _placement,
            format ["UI_POSITION_%1_%2", _placement, _suffix],
            "VOXCASTER POSITION TEST",
            "REPLACE"
        ] call Waldo_fnc_ShowUiNotification;
    } forEach [
        ["VOX LINK ESTABLISHED", "Primary transmission received.", "INFO", "A"],
        ["ORDERS ACKNOWLEDGED", "Second channel stacked without overlap.", "SUCCESS", "B"],
        ["PRIORITY TRAFFIC", "Third channel proves the full lane capacity.", "WARNING", "C"]
    ];
    uiSleep 1;
    diag_log format ["WMP UI NOTIFICATION POSITION FRAME READY: placement=%1 count=3 theme=GRIMDARK size=MEDIUM", _placement];
    uiSleep 4;
} forEach ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"];

{
    _x params ["_id", "_function"];
    [] call _function;
    uiSleep 1;
    diag_log format ["WMP UI SETTINGS FRAME READY: screen=%1", _id];
    uiSleep 4;
    private _settingsDisplay = allDisplays select {!(isNull _x) && {_x getVariable ["Waldo_UI_ThemedDisplay", false]}};
    if !(_settingsDisplay isEqualTo []) then {(_settingsDisplay select ((count _settingsDisplay) - 1)) closeDisplay 2;};
    uiSleep 0.25;
} forEach [
    ["NOTIFICATION", Waldo_fnc_UiNotificationSettingsOpenLocal],
    ["HUD", Waldo_fnc_WmpHudSettingsOpenLocal],
    ["ACCESSIBILITY", Waldo_fnc_UiColourVisionOpenLocal]
];

[] call Waldo_fnc_ClearUiPanels;
private _originalMaximumPerPlacement = missionNamespace getVariable ["Waldo_UiNotification_MaximumPerPlacement", 3];
private _originalAllowOverflow = missionNamespace getVariable ["Waldo_UiNotification_AllowPlacementOverflow", true];
private _originalOverflowPlacements = missionNamespace getVariable ["Waldo_UiNotification_OverflowPlacements", ["BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"]];
missionNamespace setVariable ["Waldo_UiNotification_MaximumPerPlacement", 3];
missionNamespace setVariable ["Waldo_UiNotification_AllowPlacementOverflow", true];
missionNamespace setVariable ["Waldo_UiNotification_OverflowPlacements", ["BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"]];
{
    private _placement = _x;
    for "_lane" from 1 to 3 do {
        [
            "QUEUE CAPACITY PROBE",
            format ["%1 lane %2", _placement, _lane],
            "INFO",
            0,
            _placement,
            format ["QA_QUEUE_FILL_%1_%2", _placement, _lane],
            "WMP QUEUE QA",
            "REPLACE"
        ] call Waldo_fnc_ShowUiNotification;
    };
} forEach ["TOP", "BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"];
private _queueResult = [
    "QUEUED PRIORITY TRAFFIC",
    "This channel must wait until a configured lane becomes available.",
    "WARNING",
    0,
    "TOP",
    "QA_QUEUE_DRAIN_TARGET",
    "WMP QUEUE QA",
    "FIFO"
] call Waldo_fnc_ShowUiNotification;
private _queuedBeforeDrain = (uiNamespace getVariable ["Waldo_UiPanelQueue", []]) findIf {
    (_x param [5, ""]) isEqualTo "QA_QUEUE_DRAIN_TARGET"
} >= 0;
["QA_QUEUE_FILL_BOTTOM_RIGHT_1"] call Waldo_fnc_DismissUiNotification;
uiSleep 0.25;
private _drainedIntoRegistry = (uiNamespace getVariable ["Waldo_UiPanelRegistry", []]) findIf {
    (_x param [0, ""]) isEqualTo "QA_QUEUE_DRAIN_TARGET"
    && {(_x param [3, ""]) isEqualTo "BOTTOM_RIGHT"}
} >= 0;
private _queueProbePassed = _queueResult isEqualTo "QUEUED" && {_queuedBeforeDrain} && {_drainedIntoRegistry};
diag_log format [
    "WMP UI NOTIFICATION QUEUE PROBE: pass=%1 result=%2 queuedBeforeDrain=%3 drainedToBottomRight=%4",
    _queueProbePassed,
    _queueResult,
    _queuedBeforeDrain,
    _drainedIntoRegistry
];
[] call Waldo_fnc_ClearUiPanels;
missionNamespace setVariable ["Waldo_UiNotification_MaximumPerPlacement", _originalMaximumPerPlacement];
missionNamespace setVariable ["Waldo_UiNotification_AllowPlacementOverflow", _originalAllowOverflow];
missionNamespace setVariable ["Waldo_UiNotification_OverflowPlacements", _originalOverflowPlacements];
[_originalTheme, false] call Waldo_fnc_UiThemeApplyLocal;
missionNamespace setVariable ["Waldo_QA_UiThemeGalleryCaptureRunning", false];
diag_log format ["WMP UI THEME GALLERY COMPLETE: count=%1 restored=%2", count _themes, _originalTheme];
