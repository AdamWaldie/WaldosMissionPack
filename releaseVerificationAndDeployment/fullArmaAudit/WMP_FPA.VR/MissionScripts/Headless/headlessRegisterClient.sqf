/*
 * Author: WaldoTheWarfighter
 * Server-authoritative headless-client registration. Adds a newly detected headless client to
 * Waldo_Headless_Clients (or refreshes its label if already known). WMP performs its own automatic
 * rebalance only when ACE Headless is absent. When ACE Headless is loaded, ACE remains the single
 * automatic scheduler and WMP uses its adoption event to apply locality-sensitive AI settings;
 * running two independent balancers against the same groups would create ownership races.
 *
 * Locality and authority:
 * Server-only. The registering machine's identity is taken from the engine-verified
 * remoteExecutedOwner, never from a caller-supplied id, so a compromised client cannot register a
 * spoofed headless client for itself. The caller must own an engine HeadlessClient_F virtual entity;
 * using allPlayers for this check is invalid because Arma includes headless clients in allPlayers.
 * Rejects outright while
 * Waldo_Headless_Enable is false - a defense-in-depth check independent of
 * Waldo_fnc_HeadlessDetectLocal's own client-side gate, since this function is the actual authority
 * boundary.
 *
 * Arguments:
 * 0: label <STRING> - the reporting machine's profileName (or a fallback), for RPT/diagnostics only.
 *
 * Return Value:
 * Boolean - true when the client was registered (or already was, with its label refreshed).
 *
 * Example:
 * ["HC-1"] remoteExec ["Waldo_fnc_HeadlessRegisterClient", 2];
 * Result: the calling machine's network owner id is added to Waldo_Headless_Clients and a
 * rebalance pass runs.
 *
 * Current caller: Waldo_fnc_HeadlessDetectLocal, with bounded repeat-safe startup retries.
 */

params [["_label", "", [""]]];
if !(isServer) exitWith {false};
if !(missionNamespace getVariable ["Waldo_Headless_Enable", false]) exitWith {false};

private _owner = remoteExecutedOwner;
if (_owner <= 2) exitWith {false};
private _headlessEntities = entities "HeadlessClient_F";
private _headlessIndex = _headlessEntities findIf {owner _x == _owner};
if (_headlessIndex < 0) exitWith {
    diag_log format ["[WMP HEADLESS] Rejected registration from owner=%1: that owner does not control a HeadlessClient_F virtual entity.", _owner];
    false
};
private _headlessEntity = _headlessEntities select _headlessIndex;

private _registry = missionNamespace getVariable ["Waldo_Headless_Clients", []];
private _idx = _registry findIf {(_x select 0) == _owner};
if (_idx >= 0) then {
    (_registry select _idx) set [1, _label];
    diag_log format ["[WMP HEADLESS] Refreshed headless client owner=%1 label=%2.", _owner, _label];
} else {
    _registry pushBack [_owner, _label, serverTime];
    diag_log format ["[WMP HEADLESS] Registered headless client owner=%1 label=%2.", _owner, _label];
};
missionNamespace setVariable ["Waldo_Headless_Clients", _registry, true];
["REGISTER", format ["owner=%1 label=%2 connectedClients=%3", _owner, _label, count _registry]] call Waldo_fnc_HeadlessDebugLog;

private _aceHeadless = isClass (configFile >> "CfgPatches" >> "ace_headless");
missionNamespace setVariable ["Waldo_Headless_ExternalScheduler", _aceHeadless, true];
if (_aceHeadless) then {
    diag_log format ["[WMP HEADLESS] Registered owner=%1; ACE Headless owns automatic distribution, WMP adoption hooks remain active.", _owner];
} else {
    [] call Waldo_fnc_HeadlessRebalance;
};
true
