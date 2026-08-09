/*
 * Author: WaldoTheWarfighter
 * Sends one Dynamic AA transition message to connected players on the system's operational side.
 *
 * Locality and authority:
 * Server-only and event-driven; it sends no message when that side currently has no human players.
 * State itself is carried by the Dynamic AA snapshot, so a JIP player does not receive stale historic
 * notifications. Safe to call on every real detected/clear transition.
 *
 * Arguments:
 * 0: system id <STRING> - stable registry key supplied at Dynamic AA creation
 * 1: detected <BOOLEAN> - true announces detection; false announces that the system is clear
 *
 * Return Value: Nothing
 * Current caller: Waldo_fnc_DynamicAADetectorLoop after a detected-state transition.
 *
 * Example:
 * ["north_sector", true] call Waldo_fnc_DynamicAANotifyState;
 * Result: current same-side players receive one card; an empty audience produces no remote call.
 */

params ["_id", "_detected"];
if !(isServer) exitWith {};
private _registry = missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap];
private _state = _registry getOrDefault [_id, createHashMap];
if (_state isEqualTo createHashMap) exitWith {};
private _side = (_state get "config") getOrDefault ["side", east];
private _recipients = allPlayers select {side group _x == _side};
if (_recipients isEqualTo []) exitWith {};
[
    "AIR DEFENCE",
    format ["System %1: hostile aircraft %2.", _id, ["clear", "detected"] select _detected],
    ["SUCCESS", "WARNING"] select _detected,
    "DYNAMIC_AA"
] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _recipients];
