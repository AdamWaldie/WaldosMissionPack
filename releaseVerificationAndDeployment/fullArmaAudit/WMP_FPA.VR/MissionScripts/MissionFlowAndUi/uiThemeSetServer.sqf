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
missionNamespace setVariable ["Waldo_UI_Theme", _themeId, true];
[_themeId, false] remoteExecCall ["Waldo_fnc_UiThemeApplyLocal", 0];
if (_preview && {_requestOwner > 0}) then {[_themeId, true] remoteExecCall ["Waldo_fnc_UiThemeApplyLocal", _requestOwner];};
diag_log format ["[WMP UI] Global visual theme changed to %1 by owner=%2", _themeId, _requestOwner];
true
