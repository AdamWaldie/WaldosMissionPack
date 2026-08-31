/*
 * Author: WaldoTheWarfighter
 * Server-authoritative master toggle for the Safestart freeze. Enabling broadcasts the
 * active state and applies the local freeze (weapons-safe, no damage dealt/received,
 * safe-zone confinement, on-screen banner) to every machine. Disabling is the admin
 * "go live" overrule: it cancels any running go-live countdown and lifts the freeze for
 * everyone immediately. JIP and respawning players re-apply the current state themselves
 * (see initPlayerLocal.sqf). The pack starts live by default; this function remains available to
 * Zeus and scripts throughout the mission, and the server's published state is authoritative.
 *
 * Arguments:
 * 0: Enable <BOOL> (Optional, default: true) - true = activate safestart, false = go live
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [true] call Waldo_fnc_SafeStart;   // activate
 * [false] call Waldo_fnc_SafeStart;  // go live (admin overrule)
 * Current callers: initServer.sqf only when AutoStart=true, SafeStart ZEN controls and timers.
 */

params [["_enable", true], ["_reason", "MANUAL"]];

// Keep state changes server-authoritative for correct JIP behaviour.
if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_SafeStart", 2];
};

missionNamespace setVariable ["Waldo_SafeStart_Active", _enable, true];
missionNamespace setVariable ["Waldo_SafeStart_LastReason", toUpper _reason, true];
missionNamespace setVariable ["Waldo_SafeStart_LastChange", serverTime, true];
private _revision = (missionNamespace getVariable ["Waldo_SafeStart_Revision", 0]) + 1;
missionNamespace setVariable ["Waldo_SafeStart_Revision", _revision, true];

// Going live cancels any pending auto-lift countdown.
if (!_enable) then {
    missionNamespace setVariable ["Waldo_SafeStart_EndTime", 0, true];
};

[_enable, toUpper _reason, _revision] remoteExecCall ["Waldo_fnc_SafeStartApply", 0];
diag_log format ["[WMP SAFESTART] state=%1 reason=%2 revision=%3 changedAt=%4 timerEnd=%5", if (_enable) then {"ACTIVE"} else {"LIVE"}, toUpper _reason, _revision, serverTime, missionNamespace getVariable ["Waldo_SafeStart_EndTime", 0]];
