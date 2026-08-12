/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: runs one headless-client rebalance pass immediately. No dialog - acts right
 * away, same pattern as Waldo_fnc_ZenJammerToggle. Forwards to the server-authoritative
 * Waldo_fnc_HeadlessForceRebalance, which itself still applies the normal eligibility rules; this
 * only skips waiting for the next automatic trigger.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module (unused).
 * 1: objectPos <OBJECT> - object the module was dropped on (unused).
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenHeadlessForceRebalance;
 *
 * Public: No
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params [["_modulePos", []], ["_objectPos", objNull]];
diag_log format ["[WMP ZEN] invoked module=Headless Client Force Rebalance curator=%1", name player];
[] remoteExecCall ["Waldo_fnc_HeadlessForceRebalance", 2];
