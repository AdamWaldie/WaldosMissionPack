/*
 * Author: WaldoTheWarfighter
 * Starts (or extends) a go-live countdown for Safestart. Ensures safestart is active,
 * publishes the auto-lift time so every client's banner can show a live clock, then
 * waits server-side until the timer expires and calls go-live automatically. An admin
 * can overrule at any point with [false] call Waldo_fnc_SafeStart, which clears the
 * end time and makes this loop stand down. Calling again restarts/extends the timer.
 *
 * Arguments:
 * 0: Seconds <NUMBER> (Optional, default: 300) - countdown length before auto go-live
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [300] call Waldo_fnc_SafeStartTimer;  // go live in 5 minutes
 */

params [["_seconds", 300]];

if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_SafeStartTimer", 2];
};

if (_seconds <= 0) exitWith { [false] call Waldo_fnc_SafeStart; };
_seconds = _seconds max 1;

// Publish the deadline before enabling SafeStart so the first client HUD frame
// already contains the requested countdown.
private _endTime = serverTime + _seconds;
missionNamespace setVariable ["Waldo_SafeStart_EndTime", _endTime, true];

// Token guards against multiple concurrent countdown loops; a newer call invalidates older loops.
private _token = (missionNamespace getVariable ["Waldo_SafeStart_TimerToken", 0]) + 1;
missionNamespace setVariable ["Waldo_SafeStart_TimerToken", _token];
if !(missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
    [true, "TIMER"] call Waldo_fnc_SafeStart;
} else {
    // Re-assert the local service loop/HUD for clients when a timer is added to an already-active
    // SafeStart. The local function is repeat-safe and will not duplicate handlers.
    [true, "TIMER"] remoteExecCall ["Waldo_fnc_SafeStartApply", 0];
};
// Do not create a second transient timer panel. The persistent SafeStart HUD
// reads this replicated deadline once per second and updates in place.
diag_log format ["[WMP SAFESTART] countdown armed for %1 seconds; deadline=%2 token=%3", _seconds, _endTime, _token];

[_endTime, _token] spawn {
    params ["_endTime", "_token"];
    waitUntil {
        sleep 1;
        // Stand down if cancelled (EndTime cleared / changed) or superseded by a newer timer.
        !(missionNamespace getVariable ["Waldo_SafeStart_Active", false])
        || {(missionNamespace getVariable ["Waldo_SafeStart_EndTime", 0]) != _endTime}
        || {(missionNamespace getVariable ["Waldo_SafeStart_TimerToken", 0]) != _token}
        || {serverTime >= _endTime}
    };

    // Only auto go-live if this timer is still the authoritative one and reached zero.
    if (
        (missionNamespace getVariable ["Waldo_SafeStart_Active", false])
        && {(missionNamespace getVariable ["Waldo_SafeStart_EndTime", 0]) == _endTime}
        && {(missionNamespace getVariable ["Waldo_SafeStart_TimerToken", 0]) == _token}
        && {serverTime >= _endTime}
    ) then {
        diag_log format ["[WMP SAFESTART] countdown completed deadline=%1 token=%2; automatically going live", _endTime, _token];
        [false, "TIMER"] call Waldo_fnc_SafeStart;
    } else {
        diag_log format ["[WMP SAFESTART] countdown stopped before completion deadline=%1 token=%2 active=%3 currentDeadline=%4 currentToken=%5", _endTime, _token, missionNamespace getVariable ["Waldo_SafeStart_Active", false], missionNamespace getVariable ["Waldo_SafeStart_EndTime", 0], missionNamespace getVariable ["Waldo_SafeStart_TimerToken", 0]];
    };
};
