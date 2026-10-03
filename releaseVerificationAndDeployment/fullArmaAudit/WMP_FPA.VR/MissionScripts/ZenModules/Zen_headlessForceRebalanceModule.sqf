/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: runs one headless-client rebalance pass immediately. No dialog - acts right
 * away, same pattern as Waldo_fnc_ZenJammerToggle. Forwards to the server-authoritative
 * Waldo_fnc_HeadlessForceRebalance, which itself still applies the normal eligibility rules; this
 * only skips waiting for the next automatic trigger.
 * Locality and authority: Curator interface forwards one request to the server; the server
 * selects eligible groups and applies locality changes through the headless service.
 * Repeat/JIP: Each placement requests one new pass. It installs no persistent local handler or
 * replayed action.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module (unused).
 * 1: objectPos <OBJECT> - object the module was dropped on (unused).
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenHeadlessForceRebalance;
 * Return Value: Nothing useful; the server request is asynchronous.
 * Current caller: ZEN Headless Client Force Rebalance module registration.
 * Result: An immediate eligibility-checked rebalance pass is requested.
 *
 * Public: No
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params [["_modulePos", []], ["_objectPos", objNull]];
diag_log format ["[WMP ZEN] invoked module=Headless Client Force Rebalance curator=%1", name player];
[] remoteExecCall ["Waldo_fnc_HeadlessForceRebalance", 2];
