/*
 * Author: WaldoTheWarfighter
 * Runtime on/off switch for the headless-client system's extended debug output
 * (Waldo_Headless_Debug / Waldo_fnc_HeadlessDebugLog), so a mission maker or curator can turn HC
 * diagnostics on to investigate a live connection/migration problem without restarting the mission
 * to edit MissionConfig\headlessConfig.sqf. Directly descended from the legacy
 * MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf's own in-mission "Toggle WHK Debug" action
 * (WHKDEBUGHC) - this is the same "flip debug live, get instant confirmation" intent, carried into
 * WMP's own broadcast-variable/notification-card conventions instead of that script's dedicated
 * WHKDEBUGGER/hint plumbing, and extended to be curator-triggerable from the Zeus menu (see
 * Waldo_fnc_ZenHeadlessDebugToggle / the "Headless Client - Toggle Debug" module) rather than the
 * legacy single-admin `serverCommandAvailable "#kick"` addAction on the player object.
 *
 * Server-authoritative; self-forwards to the server when called from a client, matching
 * Waldo_fnc_Jammer and the other public registration-style APIs, so it is safe to call directly with
 * no isServer wrapper. HC capability itself is fixed at mission start: this function refuses to
 * enable debug when Waldo_Headless_Enable is false and clears any impossible stale debug state.
 * Locality and authority: the server alone changes and broadcasts debug state. Interface callers
 * forward their request to the server; clients only install/remove their own presentation overlay.
 *
 * Arguments:
 * 0: state <BOOLEAN> (optional) - true/false to set explicitly; omitted (or any non-boolean) flips
 *    the current value instead.
 *
 * Return Value:
 * Boolean - the new Waldo_Headless_Debug state after this call.
 *
 * Example:
 * [] call Waldo_fnc_HeadlessDebugToggle;      // flip
 * [true] call Waldo_fnc_HeadlessDebugToggle;  // force on
 * Result: debug starts only for a mission that enabled HC support at startup; otherwise it remains
 * false and the requesting curator receives a warning.
 *
 * Current callers: Waldo_fnc_ZenHeadlessDebugToggle (the "Headless Client - Toggle Debug" ZEN
 * module), mission scripts.
 */

params [["_state", "__FLIP__", [false, "__FLIP__"]]];
if !(isServer) exitWith {[_state] remoteExecCall ["Waldo_fnc_HeadlessDebugToggle", 2]; false};

if !(missionNamespace getVariable ["Waldo_Headless_Enable", false]) exitWith {
    missionNamespace setVariable ["Waldo_Headless_Debug", false, true];
    [] call Waldo_fnc_HeadlessPublishDebugSnapshot;
    [false] remoteExecCall ["Waldo_fnc_HeadlessDebugDisplayLocal", -2];
    if (hasInterface) then {[false] call Waldo_fnc_HeadlessDebugDisplayLocal;};
    private _disabledCurators = (allCurators apply {getAssignedCuratorUnit _x}) select {!isNull _x};
    [createHashMapFromArray [
        ["title", "HEADLESS CLIENT DEBUG"],
        ["message", "Headless Client Support was disabled when this mission started. Debug cannot be enabled mid-mission."],
        ["state", "WARNING"], ["duration", 8], ["placement", "TOP"],
        ["channel", "HEADLESS_DEBUG"], ["source", "ZEUS"], ["audience", "UNITS"],
        ["units", _disabledCurators]
    ]] call Waldo_fnc_NotificationBroadcast;
    ["DEBUG_TOGGLE", "Refused: Waldo_Headless_Enable was false at mission start."] call Waldo_fnc_DiagnosticLog;
    false
};

private _current = missionNamespace getVariable ["Waldo_Headless_Debug", false];
private _new = if (_state isEqualType true) then {_state} else {!_current};
missionNamespace setVariable ["Waldo_Headless_Debug", _new, true];
// The publisher starts only for ON and cancels/clears its generation immediately for OFF.
[] call Waldo_fnc_HeadlessPublishDebugSnapshot;

private _curatorUnits = (allCurators apply {getAssignedCuratorUnit _x}) select {!isNull _x};
// Send to every interface client. The display function remains dormant until that local player is
// assigned a curator, which also covers assignment occurring after this state change.
[_new] remoteExecCall ["Waldo_fnc_HeadlessDebugDisplayLocal", -2];
if (hasInterface) then {[_new] call Waldo_fnc_HeadlessDebugDisplayLocal;};

private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
private _mismatches = _managed select {
    private _group = _x param [0, grpNull];
    private _expected = _x param [1, -1];
    !isNull _group && {_expected > 0} && {groupOwner _group != _expected}
};

["DEBUG_TOGGLE", format ["Waldo_Headless_Debug set to %1", _new]] call Waldo_fnc_DiagnosticLog;
[createHashMapFromArray [
    ["title", "HEADLESS CLIENT DEBUG"],
    ["message", format ["Diagnostics %1. Connected HCs: %2 | managed groups: %3 | ownership mismatches: %4.", (["OFF", "ON"] select _new), count _clients, count _managed, count _mismatches]],
    ["state", "INFO"], ["duration", 8], ["placement", "TOP"], ["channel", "HEADLESS_DEBUG"],
    ["source", "ZEUS"], ["audience", "UNITS"],
    ["units", _curatorUnits]
]] call Waldo_fnc_NotificationBroadcast;

_new
