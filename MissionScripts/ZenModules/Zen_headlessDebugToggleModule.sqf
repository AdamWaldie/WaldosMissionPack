/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: flips the headless-client system's extended debug output
 * (Waldo_Headless_Debug) on/off. No dialog - acts immediately, same pattern as
 * Waldo_fnc_ZenJammerToggle. The curator-authenticated bridge forwards to the server-authoritative
 * Waldo_fnc_HeadlessDebugToggle.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module (unused).
 * 1: objectPos <OBJECT> - object the module was dropped on (unused).
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenHeadlessDebugToggle;
 *
 * Public: No
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params [["_modulePos", []], ["_objectPos", objNull]];
diag_log format ["[WMP ZEN] invoked module=Headless Client Toggle Debug curator=%1", name player];
[] remoteExecCall ["Waldo_fnc_HeadlessDebugToggle", 2];
