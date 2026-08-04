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
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACRE-2-Long-Range-Radio-Presetting
 */
params [["_reason", "MANUAL", [""]], ["_applyPlan", true, [true]]];
if (!hasInterface || {isNull player}) exitWith {false};
private _token = (missionNamespace getVariable ["Waldo_ACRE2_RefreshToken", 0]) + 1;
missionNamespace setVariable ["Waldo_ACRE2_RefreshToken", _token];
missionNamespace setVariable ["Waldo_ACRE2_RefreshApplyPlan", (missionNamespace getVariable ["Waldo_ACRE2_RefreshApplyPlan", false]) || {_applyPlan}];
[_token, _reason] spawn {
    params ["_token", "_reason"];
    // ACRE documents isInitialized as the point at which carried base radios have become unique
    // IDs. Large modsets and Eden-defined radio attributes can legitimately take longer than the
    // rest of mission init, so this asynchronous waiter allows two minutes without blocking WMP.
    private _deadline = diag_tickTime + 120;
    waitUntil {
        uiSleep 0.1;
        private _plan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
        (missionNamespace getVariable ["Waldo_ACRE2_RefreshToken", -1]) != _token
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
    if ((missionNamespace getVariable ["Waldo_ACRE2_RefreshToken", -1]) != _token) exitWith {};
    private _plan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
    if (diag_tickTime >= _deadline || {count _plan < 4} || {!([] call acre_api_fnc_isInitialized)}) exitWith {
        missionNamespace setVariable ["Waldo_ACRE2_RefreshApplyPlan", false];
        private _acreReady = !isNil "acre_api_fnc_isInitialized" && {[] call acre_api_fnc_isInitialized};
        private _currentRadios = if (isNil "acre_api_fnc_getCurrentRadioList") then {[]} else {[] call acre_api_fnc_getCurrentRadioList};
        private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
        private _profiles = [_config] call Waldo_fnc_ACRE2GetRadioProfiles;
        private _profileClasses = _profiles apply {toUpperANSI (_x select 0)};
        private _inventoryRadios = (items player + assignedItems player) select {
            private _item = toUpperANSI _x;
            (_profileClasses findIf {_item == _x || {_item find (_x + "_ID_") == 0}}) >= 0
        };
        private _detail = if (!_acreReady && {!(_inventoryRadios isEqualTo [])}) then {
            format ["ACRE did not finish converting carried radios to unique IDs within 120 seconds. Carried radio classes: %1.", _inventoryRadios]
        } else {
            if (count _plan < 4) then {"The server ACRE plan did not arrive."} else {format ["ACRE reported ready but returned no usable carried radios: %1.", _currentRadios]}
        };
        missionNamespace setVariable ["Waldo_ACRE2_LastReadinessFailure", [_reason, _acreReady, _inventoryRadios, _currentRadios, _detail]];
        diag_log format ["[WMP ACRE] %1 refresh timed out: %2 Mission startup continues.", _reason, _detail];
        if (_config getOrDefault ["notifyAssignmentProblems", true]) then {
            ["ACRE2 SETUP", _detail + " Run WMP Diagnostics and check the ACRE radio configuration.", "WARNING", "ACRE2_READINESS"] call Waldo_fnc_FeatureNotifyLocal;
        };
        // Initial setup owns the baseline and must not be silently abandoned. This asynchronous
        // retry does not block mission startup and coalesces through the refresh token.
        if (_reason in ["INITIAL", "INITIAL_LATE"]) then {
            ["INITIAL_LATE", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        };
    };
    private _applyPlan = missionNamespace getVariable ["Waldo_ACRE2_RefreshApplyPlan", false];
    missionNamespace setVariable ["Waldo_ACRE2_RefreshApplyPlan", false];
    private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
    if !(missionNamespace getVariable ["Waldo_ACRE2_PresetNamesReady", false]) then {[_config] call Waldo_fnc_ACRE2ApplyPresetNames};
    private _planApplied = true;
    if (_applyPlan) then {_planApplied = [true, _reason] call Waldo_fnc_ACRE2ApplyPlayerPlan};
    [] call Waldo_fnc_ACRE2ApplyBabel;
    [] call Waldo_fnc_ACRE2BuildCEOI;
    if (_planApplied && {_reason in ["INITIAL", "INITIAL_LATE", "PERSISTENCE_BASELINE", "PERSISTENCE_RESTORE_FALLBACK"]}) then {
        [false] call Waldo_fnc_SaveLoadout;
    };
    if (!_planApplied && {_reason in ["INITIAL", "INITIAL_LATE"]}) then {
        diag_log "[WMP ACRE] Initial radio plan failed; the respawn baseline was not saved.";
        ["ACRE2 SETUP", "The initial radio plan was not applied, so WMP did not save a channel-1 respawn baseline. Run WMP Diagnostics for the exact radio/net mismatch.", "WARNING", "ACRE2_INITIAL_FAILED"] call Waldo_fnc_FeatureNotifyLocal;
    };
};
true
