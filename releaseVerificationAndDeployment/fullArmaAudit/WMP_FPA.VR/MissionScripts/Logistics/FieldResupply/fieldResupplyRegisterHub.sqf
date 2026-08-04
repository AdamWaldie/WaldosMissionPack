/*
 * Author: WaldoTheWarfighter
 * Registers an object as a server-authoritative Field Resupply refill hub.
 *
 * Hub identity, serviced side and remaining portable-crate stock are public state. The server keeps
 * a registry for diagnostics and publishes object-keyed local action setup so every current client
 * and JIP client receives exactly one ACE interaction or vanilla fallback. Registration also enables
 * the feature and replays that state to clients. Remote setup requests require an assigned curator.
 *
 * Arguments:
 * 0: hub <OBJECT> - world object used as the refill point.
 * 1: serviced side <SIDE> - sideUnknown permits every side (default sideUnknown).
 * 2: stock <NUMBER> - portable crates the hub may issue; -1 is unlimited (default -1).
 *
 * Return Value:
 * Boolean - true when forwarded or registered; otherwise false.
 *
 * Example:
 * [this, west, -1] call Waldo_fnc_FieldResupplyRegisterHub;
 *
 * Current callers: Field Resupply ZEN hub module, audit hub setup and mission-maker object setup.
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
[_hub] remoteExecCall ["Waldo_fnc_FieldResupplySetupHubLocal", 0, format ["Waldo_FieldResupply_Hub_%1", netId _hub]];
[] remoteExecCall ["Waldo_fnc_FieldResupplyInit", 0, "Waldo_FieldResupply_Init"];
true
