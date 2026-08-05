/*
 * Author: WaldoTheWarfighter
 * Announces one Dynamic AA detection transition outside the recurring detector body.
 * Arguments: 0: id <STRING>; 1: detected <BOOLEAN>
 * Return Value: Nothing
 */

params ["_id", "_detected"];
if !(isServer) exitWith {};
private _registry = missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap];
private _state = _registry getOrDefault [_id, createHashMap];
if (_state isEqualTo createHashMap) exitWith {};
private _side = (_state get "config") getOrDefault ["side", east];
private _recipients = allPlayers select {side group _x == _side};
[
    "AIR DEFENCE",
    format ["System %1: hostile aircraft %2.", _id, ["clear", "detected"] select _detected],
    ["SUCCESS", "WARNING"] select _detected,
    "DYNAMIC_AA"
] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _recipients];
