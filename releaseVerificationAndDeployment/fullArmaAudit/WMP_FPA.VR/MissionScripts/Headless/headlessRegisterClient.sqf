/*
 * Author: WaldoTheWarfighter
 * Server-authoritative headless-client registration. Adds a newly detected headless client to
 * Waldo_Headless_Clients (or refreshes its label if already known) and triggers a rebalance pass so
 * eligible AI groups are distributed to it.
 *
 * Locality and authority:
 * Server-only. The registering machine's identity is taken from the engine-verified
 * remoteExecutedOwner, never from a caller-supplied id, so a compromised client cannot register a
 * spoofed headless client for itself. A caller whose owner id already belongs to a connected player
 * is rejected outright - a real headless client never has a player object. Rejects outright while
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
 * Current caller: Waldo_fnc_HeadlessDetectLocal, once per connected headless client.
 */

params [["_label", "", [""]]];
if !(isServer) exitWith {false};
if !(missionNamespace getVariable ["Waldo_Headless_Enable", false]) exitWith {false};

private _owner = remoteExecutedOwner;
if (_owner <= 0) exitWith {false};
if ((allPlayers findIf {owner _x == _owner}) >= 0) exitWith {
    diag_log format ["[WMP HEADLESS] Rejected registration from owner=%1: it is a connected player, not a headless client.", _owner];
    false
};

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

[] call Waldo_fnc_HeadlessRebalance;
true
