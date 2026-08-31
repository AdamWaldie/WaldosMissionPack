/*
 * Author: WaldoTheWarfighter
 * Registers an object as a server-authoritative Field Resupply refill hub.
 *
 * Hub identity, serviced side and remaining portable-crate stock are public state. The server keeps
 * a registry for diagnostics and publishes lifetime-bound local action setup so every current client
 * and JIP client receives exactly one ACE interaction or vanilla fallback. Eden object init fields
 * run everywhere, so non-server copies are ignored. ZEN sends its request through the validated
 * server runtime bridge; registration also enables the feature and replays that state to clients.
 *
 * Locality and authority:
 * The server owns stock and registry state. Eden client copies exit; each interface installs its
 * local action from named JIP replay bound to the hub's deletion and requests stock mutations from the server.
 *
 * Arguments:
 * 0: hub <OBJECT> - world object used as the refill point.
 * 1: serviced side <SIDE or STRING> - use "ALL" for every side, or west/east/independent/civilian
 *    for one side (default "ALL"). `sideUnknown` remains accepted internally for ZEN compatibility.
 * 2: stock <NUMBER> - portable crates the hub may issue; -1 is unlimited (default -1).
 *
 * Return Value:
 * Boolean - true when registered (or when a duplicate non-server Eden copy was ignored); otherwise false.
 *
 * Example:
 * [this, "ALL", -1] call Waldo_fnc_FieldResupplyRegisterHub;
 * Result: this object becomes an unlimited refill hub usable by every side.
 *
 * Current callers: Field Resupply ZEN hub module, audit hub setup and mission-maker object setup.
 */

params [["_hub", objNull, [objNull]], ["_side", "ALL", [sideUnknown, ""]], ["_stock", -1, [0]]];
if !(isServer) exitWith {true};
if (isNull _hub) exitWith {false};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {false};
};
if (_side isEqualType "") then {
    _side = switch (toUpperANSI _side) do {
        case "WEST": {west};
        case "BLUFOR": {west};
        case "EAST": {east};
        case "OPFOR": {east};
        case "INDEPENDENT": {independent};
        case "GUER": {independent};
        case "CIVILIAN": {civilian};
        default {sideUnknown};
    };
};
_hub setVariable ["Waldo_FieldResupply_Hub", true, true];
_hub setVariable ["Waldo_FieldResupply_Side", _side, true];
_hub setVariable ["Waldo_FieldResupply_Stock", round _stock, true];
private _hubs = missionNamespace getVariable ["Waldo_FieldResupply_Hubs", []];
_hubs pushBackUnique _hub;
missionNamespace setVariable ["Waldo_FieldResupply_Hubs", _hubs, true];
if (isNil {_hub getVariable "Waldo_FieldResupply_DeletedEH"}) then {
    private _deletedHandler = _hub addEventHandler ["Deleted", {
        params ["_deletedHub"];
        private _registeredHubs = missionNamespace getVariable ["Waldo_FieldResupply_Hubs", []];
        private _index = _registeredHubs find _deletedHub;
        if (_index >= 0) then {
            _registeredHubs deleteAt _index;
            missionNamespace setVariable ["Waldo_FieldResupply_Hubs", _registeredHubs, true];
        };
    }];
    _hub setVariable ["Waldo_FieldResupply_DeletedEH", _deletedHandler];
};
missionNamespace setVariable ["Waldo_FieldResupply_Enable", true, true];
[[["Waldo_FieldResupply_Enable", true]], false] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", -2];
private _hubJipId = format ["Waldo_FieldResupply_Hub_%1", netId _hub];
[_hub] remoteExecCall ["Waldo_fnc_FieldResupplySetupHubLocal", 0, _hubJipId];
[_hub, _hubJipId] call Waldo_fnc_JipBindToObjectServer;
[] remoteExecCall ["Waldo_fnc_FieldResupplyInit", 0, "Waldo_FieldResupply_Init"];
true
