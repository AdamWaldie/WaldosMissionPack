/*
 * Author: Waldo
 * Registers a supply hub with optional finite refill stock.
 *
 * Arguments: 0: hub <OBJECT>; 1: side <SIDE>; 2: stock <NUMBER>, -1 unlimited
 * Return Value: Boolean
 */

params [["_hub", objNull, [objNull]], ["_side", sideUnknown, [sideUnknown]], ["_stock", -1, [0]]];
if !(isServer) exitWith {[_hub, _side, _stock] remoteExecCall ["Waldo_fnc_FieldResupplyRegisterHub", 2]; true};
if (isNull _hub) exitWith {false};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {false};
};
_hub setVariable ["Waldo_FieldResupply_Hub", true, true];
_hub setVariable ["Waldo_FieldResupply_Side", _side, true];
_hub setVariable ["Waldo_FieldResupply_Stock", round _stock, true];
private _hubs = missionNamespace getVariable ["Waldo_FieldResupply_Hubs", []];
_hubs pushBackUnique _hub;
missionNamespace setVariable ["Waldo_FieldResupply_Hubs", _hubs, true];
missionNamespace setVariable ["Waldo_FieldResupply_Enable", true, true];
[[["Waldo_FieldResupply_Enable", true]], false] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", -2];
[_hub] remoteExecCall ["Waldo_fnc_FieldResupplySetupHubLocal", -2, format ["Waldo_FieldResupply_Hub_%1", netId _hub]];
[] remoteExecCall ["Waldo_fnc_FieldResupplyInit", -2, "Waldo_FieldResupply_Init"];
true
