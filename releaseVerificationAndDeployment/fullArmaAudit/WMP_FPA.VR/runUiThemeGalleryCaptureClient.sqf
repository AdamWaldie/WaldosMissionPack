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
 * Return Value: Nothing; asynchronously renders twelve preview frames and writes capture markers.
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
private _themes = [
    "DEFAULT", "WW2", "VIETNAM", "SCIFI", "PARCHMENT", "MINIMAL",
    "NAVAL", "DESERT_STORM", "INDUSTRIAL", "EASTERN_BLOC", "INTELLIGENCE", "EMERGENCY"
];

diag_log format ["WMP UI THEME GALLERY START: count=%1", count _themes];
{
    [_x, true] call Waldo_fnc_UiThemeApplyLocal;
    uiSleep 1;
    diag_log format ["WMP UI THEME GALLERY FRAME READY: theme=%1 index=%2 count=%3", _x, _forEachIndex + 1, count _themes];
    uiSleep 4;
} forEach _themes;

[_originalTheme, false] call Waldo_fnc_UiThemeApplyLocal;
missionNamespace setVariable ["Waldo_QA_UiThemeGalleryCaptureRunning", false];
diag_log format ["WMP UI THEME GALLERY COMPLETE: count=%1 restored=%2", count _themes, _originalTheme];
