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
 * no isServer wrapper.
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
 *
 * Current callers: Waldo_fnc_ZenHeadlessDebugToggle (the "Headless Client - Toggle Debug" ZEN
 * module), mission scripts.
 */

params [["_state", "__FLIP__", [false, "__FLIP__"]]];
if !(isServer) exitWith {[_state] remoteExecCall ["Waldo_fnc_HeadlessDebugToggle", 2]; false};

private _current = missionNamespace getVariable ["Waldo_Headless_Debug", false];
private _new = if (_state isEqualType true) then {_state} else {!_current};
missionNamespace setVariable ["Waldo_Headless_Debug", _new, true];

["DEBUG_TOGGLE", format ["Waldo_Headless_Debug set to %1", _new]] call Waldo_fnc_DiagnosticLog;
[createHashMapFromArray [
    ["title", "HEADLESS CLIENT DEBUG"],
    ["message", format ["Extended headless-client diagnostics are now %1.", (["OFF", "ON"] select _new)]],
    ["state", "INFO"], ["duration", 8], ["placement", "TOP"], ["channel", "HEADLESS_DEBUG"],
    ["source", "ZEUS"], ["audience", "UNITS"],
    ["units", (allCurators apply {getAssignedCuratorUnit _x}) select {!isNull _x}]
]] call Waldo_fnc_NotificationBroadcast;

_new
