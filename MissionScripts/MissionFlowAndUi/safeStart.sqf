/*
 * Author: Waldo
 * Server-authoritative master toggle for the Safestart freeze. Enabling broadcasts the
 * active state and applies the local freeze (weapons-safe, no damage dealt/received,
 * safe-zone confinement, on-screen banner) to every machine. Disabling is the admin
 * "go live" overrule: it cancels any running go-live countdown and lifts the freeze for
 * everyone immediately. JIP and respawning players re-apply the current state themselves
 * (see initPlayerLocal.sqf).
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
 */

params [["_enable", true]];

// Keep state changes server-authoritative for correct JIP behaviour.
if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_SafeStart", 2];
};

missionNamespace setVariable ["Waldo_SafeStart_Active", _enable, true];

// Going live cancels any pending auto-lift countdown.
if (!_enable) then {
    missionNamespace setVariable ["Waldo_SafeStart_EndTime", 0, true];
};

[_enable] remoteExec ["Waldo_fnc_SafeStartApply", 0];
