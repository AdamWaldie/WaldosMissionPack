/*
 * Author: WaldoTheWarfighter
 * Detects whether this machine is a connected headless client and, if so, registers it with the
 * server-authoritative headless-client registry.
 *
 * A headless client is identified by the standard, version-stable Bohemia-documented test
 * (!isDedicated && !hasInterface) - it has no rendered interface and is not the dedicated server
 * itself. This replaces the legacy MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf's
 * serverCommandAvailable "#kick" heuristic, which can also true on a listen-server host or any
 * admin-capable connection. Self-forwards to the server exactly like Waldo_fnc_Jammer, so it is
 * safe to call unconditionally on every machine (server and every player are simply ignored).
 *
 * Locality and authority:
 * Detection runs locally on every machine. Registration is server-authoritative
 * (Waldo_fnc_HeadlessRegisterClient); this function only decides whether to ask for it, and it
 * verifies the caller's identity server-side via the engine-supplied remoteExecutedOwner rather
 * than trusting anything this function sends.
 *
 * Arguments: None.
 *
 * Return Value:
 * Boolean - true when this machine is a headless client (registration requested); false otherwise.
 *
 * Example:
 * [] call Waldo_fnc_HeadlessDetectLocal;
 * Result: on a headless client, requests registration with the server; a no-op everywhere else.
 *
 * Current caller: init.sqf, gated behind the ordered feature-runtime snapshot handshake so a
 * joining headless client never registers before it has a consistent runtime picture.
 */

if (missionNamespace getVariable ["Waldo_Headless_DetectRan", false]) exitWith {
    missionNamespace getVariable ["Waldo_Headless_IsThisMachine", false]
};
missionNamespace setVariable ["Waldo_Headless_DetectRan", true];

private _isHeadless = !isDedicated && {!hasInterface};
missionNamespace setVariable ["Waldo_Headless_IsThisMachine", _isHeadless];
if !(_isHeadless) exitWith {false};

private _label = if (profileName != "") then {profileName} else {format ["HC-%1", clientOwner]};
diag_log format ["[WMP HEADLESS] This machine detected itself as a headless client (label=%1); requesting registration.", _label];
[_label] remoteExec ["Waldo_fnc_HeadlessRegisterClient", 2];
true
