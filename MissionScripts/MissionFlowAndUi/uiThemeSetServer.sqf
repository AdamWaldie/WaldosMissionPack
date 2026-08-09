/*
 * Author: WaldoTheWarfighter
 * Validates and broadcasts a live WMP UI theme change. Remote requests are accepted only from an
 * assigned curator. The server publishes durable current state for JIP, while connected clients
 * receive an ordered apply call; only the requesting curator receives the optional preview cards.
 *
 * Arguments:
 * 0: theme id <STRING>
 * 1: preview for requesting curator <BOOL> (default true)
 *
 * Return Value: BOOL - true when the global state changed.
 *
 * Example: ["WW2", true] remoteExecCall ["Waldo_fnc_UiThemeSetServer", 2];
 * Current caller: the ZEN UI QA theme module.
 */

params [["_themeId", "DEFAULT", [""]], ["_preview", true, [true]]];
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_UiThemeSetServer", 2]; false};
private _requestOwner = remoteExecutedOwner;
if (_requestOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == _requestOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    if (isNull _caller || {isNull getAssignedCuratorLogic _caller}) exitWith {false};
};
_themeId = toUpperANSI _themeId;
private _resolved = [_themeId] call Waldo_fnc_UiTheme;
if ((_resolved getOrDefault ["id", "DEFAULT"]) != _themeId) exitWith {false};
private _revision = (missionNamespace getVariable ["Waldo_UI_ThemeRevision", 0]) + 1;
missionNamespace setVariable ["Waldo_UI_Theme", _themeId, true];
missionNamespace setVariable ["Waldo_UI_ThemeRevision", _revision, true];
// Use the same ordered runtime-state receiver as JIP instead of a separate best-effort presentation
// call. This keeps the authoritative value and its application in one payload on every machine.
[
    [["Waldo_UI_Theme", _themeId], ["Waldo_UI_ThemeRevision", _revision]],
    false
] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", 0];
if (_preview && {_requestOwner > 0}) then {[_themeId, true] remoteExecCall ["Waldo_fnc_UiThemeApplyLocal", _requestOwner];};
diag_log format ["[WMP UI] Global visual theme changed to %1 revision=%2 by owner=%3", _themeId, _revision, _requestOwner];
true
