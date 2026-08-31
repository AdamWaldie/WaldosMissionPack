/*
 * Author: WaldoTheWarfighter
 * Registers an object as a server-owned Tactical Display access point.
 *
 * Configuration is stored publicly on the object and local `addAction` setup is published with a
 * named JIP call bound to the object's lifetime. The action opens a client-only map; this function does not create a texture
 * on the object. Eden object init fields run everywhere, so non-server copies are ignored. ZEN
 * sends live requests through the validated server runtime bridge. Re-registering does not duplicate actions.
 *
 * Locality and authority:
 * The server validates/publishes display policy. Each interface owns its action and map UI; Eden
 * client copies exit and lifetime-bound replay restores the action for JIP clients.
 *
 * Arguments:
 * 0: display object <OBJECT> - whiteboard, map board or suitable terminal.
 * 1: represented side <SIDE or STRING> - use "VIEWER" to follow each viewer's side, or
 *    west/east/independent/civilian for a fixed side (default "VIEWER"). `sideUnknown` remains
 *    accepted internally for ZEN compatibility.
 * 2: map radius <NUMBER> - world radius shown/tracked, clamped to at least 100 m (default 2000).
 * 3: show known enemies <BOOLEAN> - permits contacts known to the viewer's group (default true).
 * 4: interaction options <ARRAY or HASHMAP> - optional `enabled`, `challengeId`, and `difficulty`.
 *      The semantic default is command authentication at standard difficulty.
 *
 * Return Value:
 * Boolean - true when registered (or when a duplicate non-server Eden copy was ignored); otherwise false.
 *
 * Example:
 * [mapBoard, west, 2000, true] call Waldo_fnc_TacticalDisplayRegister;
 * Result: the map board opens a 2000 m WEST tactical view for players in interaction range.
 *
 * Current callers: Tactical Display ZEN module, audit station and mission-maker setup.
 */

params [["_object", objNull, [objNull]], ["_side", "VIEWER", [sideUnknown, ""]], ["_radius", 2000, [0]], ["_knownEnemies", true, [false]], ["_interactionOptions", [], [[], createHashMap]]];
if !(isServer) exitWith {true};
if (isNull _object) exitWith {false};
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
_object setVariable ["Waldo_TacticalDisplay_Registered", true, true];
_object setVariable ["Waldo_TacticalDisplay_Side", _side, true];
_object setVariable ["Waldo_TacticalDisplay_Radius", _radius max 100, true];
_object setVariable ["Waldo_TacticalDisplay_ShowKnownEnemies", _knownEnemies, true];
private _pairs = [];
if (typeName _interactionOptions == "HASHMAP") then {{_pairs pushBack [_x, _interactionOptions get _x]} forEach keys _interactionOptions} else {_pairs = _interactionOptions};
private _getOption = {params ["_key", "_default"]; private _value = _default; {if ((_x param [0, ""]) == _key) exitWith {_value = _x param [1, _default]}} forEach _pairs; _value};
private _interactionEnabled = ["enabled", false] call _getOption;
private _challengeId = ["challengeId", "commandinput"] call _getOption;
private _difficulty = ["difficulty", "standard"] call _getOption;
_object setVariable ["Waldo_TacticalDisplay_InteractionEnabled", _interactionEnabled, true];
_object setVariable ["Waldo_TacticalDisplay_Unlocked", !_interactionEnabled, true];
if (_interactionEnabled && {!isNil "Waldo_fnc_MiniGameInteractionReset"} && {!isNil {_object getVariable "Waldo_MG_InteractionState"}}) then {
    [_object, true, false] call Waldo_fnc_MiniGameInteractionReset;
};
if (!_interactionEnabled && {!isNil {_object getVariable "Waldo_MG_Int_Active"}}) then {
    _object setVariable ["Waldo_MG_Int_Active", false, true];
};
// Target every machine rather than "clients except server": a hosted server also owns an interface.
// TacticalDisplaySetupLocal self-gates on hasInterface, so dedicated servers remain a harmless no-op.
private _displayJipId = format ["Waldo_TacticalDisplay_%1", netId _object];
[_object] remoteExecCall ["Waldo_fnc_TacticalDisplaySetupLocal", 0, _displayJipId];
[_object, _displayJipId] call Waldo_fnc_JipBindToObjectServer;
if (_interactionEnabled) then {
    [_object, [_challengeId, _difficulty]] remoteExecCall ["Waldo_fnc_TacticalDisplayInteractionSetup", 0, _object];
};
true
