/*
 * Author: Waldo
 * Announces one Dynamic AA detection transition outside the recurring detector body.
 * Arguments: 0: id <STRING>; 1: detected <BOOLEAN>
 * Return Value: Nothing
 */

params ["_id", "_detected"];
if !(isServer) exitWith {};
[format ["[WMP] AA system %1: hostile aircraft %2.", _id, ["clear", "detected"] select _detected]] remoteExecCall ["systemChat", 0];
