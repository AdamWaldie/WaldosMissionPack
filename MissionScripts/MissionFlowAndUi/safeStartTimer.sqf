/*
 * Author: Waldo
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

// Make sure the freeze is on, then publish the auto-lift moment.
if !(missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
    [true] call Waldo_fnc_SafeStart;
};

private _endTime = serverTime + _seconds;
missionNamespace setVariable ["Waldo_SafeStart_EndTime", _endTime, true];

// Token guards against multiple concurrent countdown loops; a newer call invalidates older loops.
private _token = diag_tickTime;
missionNamespace setVariable ["Waldo_SafeStart_TimerToken", _token];

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
        [false] call Waldo_fnc_SafeStart;
    };
};
