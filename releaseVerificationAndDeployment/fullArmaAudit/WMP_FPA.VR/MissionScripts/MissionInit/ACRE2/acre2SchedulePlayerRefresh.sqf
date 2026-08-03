/*
 * Author: WaldoTheWarfighter
 * Debounces join, respawn, player-object and group events into one bounded, readiness-aware local
 * ACRE refresh. A newer request cancels an older waiter. Persistence may hold the refresh while it
 * restores a filtered loadout and newly generated unique radio IDs.
 * Locality and authority: call on the player's interface client. It coalesces only that client's
 * lifecycle events and consumes the complete server-published plan when requested.
 *
 * Arguments:
 * 0: reason <STRING> (default MANUAL)
 * 1: apply mission radio plan <BOOL> (default true)
 *
 * Return Value: BOOL - true when a refresh was scheduled on an interface client.
 *
 * Example: ["RESPAWN", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
 * Result: one bounded local refresh applies Babel/CEOI and, when permitted, the radio baseline.
 * Current callers: ACRE initialisation, respawn, player-unit and group lifecycle handlers.
 */
params [["_reason", "MANUAL", [""]], ["_applyPlan", true, [true]]];
if (!hasInterface || {isNull player}) exitWith {false};
private _token = (uiNamespace getVariable ["Waldo_ACRE2_RefreshToken", 0]) + 1;
uiNamespace setVariable ["Waldo_ACRE2_RefreshToken", _token];
uiNamespace setVariable ["Waldo_ACRE2_RefreshApplyPlan", (uiNamespace getVariable ["Waldo_ACRE2_RefreshApplyPlan", false]) || {_applyPlan}];
[_token, _reason] spawn {
    params ["_token", "_reason"];
    private _deadline = diag_tickTime + 30;
    waitUntil {
        uiSleep 0.1;
        private _plan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
        (uiNamespace getVariable ["Waldo_ACRE2_RefreshToken", -1]) != _token
            || {diag_tickTime >= _deadline}
            || {
                !isNull player
                && {!isNil "acre_api_fnc_isInitialized"}
                && {[] call acre_api_fnc_isInitialized}
                && {count _plan >= 4}
                && {(_plan select 0) == 3}
                && {!(missionNamespace getVariable ["Waldo_ACRE2_RadioRestoreInProgress", false])}
            }
    };
    if ((uiNamespace getVariable ["Waldo_ACRE2_RefreshToken", -1]) != _token) exitWith {};
    private _plan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
    if (diag_tickTime >= _deadline || {count _plan < 4} || {!([] call acre_api_fnc_isInitialized)}) exitWith {
        uiNamespace setVariable ["Waldo_ACRE2_RefreshApplyPlan", false];
        diag_log format ["[WMP ACRE] %1 refresh timed out; mission startup continues.", _reason];
    };
    private _applyPlan = uiNamespace getVariable ["Waldo_ACRE2_RefreshApplyPlan", false];
    uiNamespace setVariable ["Waldo_ACRE2_RefreshApplyPlan", false];
    private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
    if !(missionNamespace getVariable ["Waldo_ACRE2_PresetNamesReady", false]) then {[_config] call Waldo_fnc_ACRE2ApplyPresetNames};
    if (_applyPlan) then {[true, _reason] call Waldo_fnc_ACRE2ApplyPlayerPlan};
    [] call Waldo_fnc_ACRE2ApplyBabel;
    [] call Waldo_fnc_ACRE2BuildCEOI;
    if (_reason in ["INITIAL", "PERSISTENCE_BASELINE", "PERSISTENCE_RESTORE_FALLBACK"]) then {
        [false] call Waldo_fnc_SaveLoadout;
    };
};
true
