/*
 * Author: WaldoTheWarfighter
 * Purpose: Legacy local timed hint for existing calls. New feature feedback should use WMP
 * notifications so concurrent systems share placement, themes and queue handling.
 * Locality/authority: client interface only; no server state. Call remotely on the target client
 * when the originating script runs elsewhere. The internal sleep requires scheduled execution.
 * Repeat/JIP: each call replaces the local clear token, so an old timer cannot clear a newer hint.
 * A past hint is not replayed to JIP.
 * Arguments:
 * 0: message <STRING> (required) - text in the local Arma hint display.
 * 1: duration <NUMBER> (default 10) - seconds before this hint clears.
 * 2: owner <STRING> (default empty) - internal owner label used by older WMP callers.
 * Return value: Nothing useful; the script completes after the timer.
 * Current callers: EMP/tracker compatibility feedback and mission-maker scripts.
 * Example: ["Rendezvous respawn activated", 10] spawn Waldo_fnc_TimedHint;
 * Result: the local hint appears for up to 10 seconds, then clears unless replaced earlier.
 */
params ["_hintContents", ["_hintTimer", 10], ["_owner", "", [""]]];

private _token = format ["%1_%2", diag_tickTime, random 1e9];
uiNamespace setVariable ["Waldo_TimedHintToken", _token];
uiNamespace setVariable ["Waldo_TimedHintOwner", toUpper _owner];
hint _hintContents;
sleep _hintTimer;
// An older hint must never clear a newer or more important notification.
if ((uiNamespace getVariable ["Waldo_TimedHintToken", ""]) isEqualTo _token) then {
    hint "";
    uiNamespace setVariable ["Waldo_TimedHintToken", nil];
    uiNamespace setVariable ["Waldo_TimedHintOwner", nil];
};
