/*
 * Author: WaldoTheWarfighter
 * Detects whether this machine is a connected headless client and, if so, registers it with the
 * server-authoritative headless-client registry.
 *
 * A headless client is identified by the standard, version-stable Bohemia-documented test
 * (!isDedicated && !hasInterface) - it has no rendered interface and is not the dedicated server
 * itself. This avoids admin-permission heuristics that can also match a listen-server host or another
 * admin-capable connection. Self-forwards to the server exactly like Waldo_fnc_Jammer, so it is
 * safe to call unconditionally on every machine (server and every player are simply ignored).
 * A headless client retries its authenticated registration for up to 30 seconds. This closes the
 * dedicated-server startup race where the request can arrive before its HeadlessClient_F entity is
 * visible to the server; the server registry remains repeat-safe, so retries cannot duplicate it.
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
 *
 * Master switch: Waldo_Headless_Enable (MissionConfig\headlessConfig.sqf) defaults false. The
 * dedicated lifecycle is verified, but migration remains opt-in because each mission's AI mods and
 * locality-sensitive scripts require their own test. Connecting a headless client to a mission that
 * has not turned this on has no effect. Detection itself still runs either way (harmless, and useful
 * for diagnostics); only the actual registration request is gated.
 */

if (missionNamespace getVariable ["Waldo_Headless_DetectRan", false]) exitWith {
    missionNamespace getVariable ["Waldo_Headless_IsThisMachine", false]
};
missionNamespace setVariable ["Waldo_Headless_DetectRan", true];

private _isHeadless = !isDedicated && {!hasInterface};
missionNamespace setVariable ["Waldo_Headless_IsThisMachine", _isHeadless];
if !(_isHeadless) exitWith {false};
if !(missionNamespace getVariable ["Waldo_Headless_Enable", false]) exitWith {
    diag_log "[WMP HEADLESS] This machine detected itself as a headless client, but Waldo_Headless_Enable is false; not registering.";
    false
};

private _label = if (profileName != "") then {profileName} else {format ["HC-%1", clientOwner]};
diag_log format ["[WMP HEADLESS] This machine detected itself as a headless client (label=%1); starting bounded registration.", _label];
[_label] spawn {
    params ["_label"];
    private _attempt = 0;
    waitUntil {
        _attempt = _attempt + 1;
        private _registered = (missionNamespace getVariable ["Waldo_Headless_Clients", []]) findIf {
            _x param [0, -1] == clientOwner
        } >= 0;
        if (!_registered) then {
            diag_log format ["[WMP HEADLESS] Registration attempt %1/15 owner=%2 label=%3.", _attempt, clientOwner, _label];
            [_label] remoteExecCall ["Waldo_fnc_HeadlessRegisterClient", 2];
        };
        if (!_registered && {_attempt < 15}) then {uiSleep 2};
        _registered || {_attempt >= 15}
    };
    private _registered = (missionNamespace getVariable ["Waldo_Headless_Clients", []]) findIf {
        _x param [0, -1] == clientOwner
    } >= 0;
    diag_log format ["[WMP HEADLESS] Bounded registration finished owner=%1 registered=%2 attempts=%3.", clientOwner, _registered, _attempt];
};
true
