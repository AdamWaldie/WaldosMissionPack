/*
 * Author: WaldoTheWarfighter
 * Registers an object as a server-owned Tactical Display access point.
 *
 * Configuration is stored publicly on the object and local `addAction` setup is published with an
 * object-keyed JIP call. The action opens a client-only map; this function does not create a texture
 * on the object. Remote registration requires an assigned curator, while direct server calls support
 * pre-planned mission setup. Re-registering updates configuration without duplicating local actions.
 *
 * Arguments:
 * 0: display object <OBJECT> - whiteboard, map board or suitable terminal.
 * 1: represented side <SIDE> - sideUnknown follows the viewer's side (default sideUnknown).
 * 2: map radius <NUMBER> - world radius shown/tracked, clamped to at least 100 m (default 2000).
 * 3: show known enemies <BOOLEAN> - permits contacts known to the viewer's group (default true).
 * 4: interaction options <ARRAY or HASHMAP> - optional `enabled`, `challengeId`, and `difficulty`.
 *      The semantic default is command authentication at standard difficulty.
 *
 * Return Value:
 * Boolean - true when forwarded or registered; otherwise false.
 *
 * Example:
 * [mapBoard, west, 2000, true] call Waldo_fnc_TacticalDisplayRegister;
 *
 * Current callers: Tactical Display ZEN module, audit station and mission-maker setup.
 */

params [["_object", objNull, [objNull]], ["_side", sideUnknown, [sideUnknown]], ["_radius", 2000, [0]], ["_knownEnemies", true, [false]], ["_interactionOptions", [], [[], createHashMap]]];
if !(isServer) exitWith {
    private _forward = _interactionOptions;
    if (typeName _forward == "HASHMAP") then {private _pairs = []; {_pairs pushBack [_x, _forward get _x]} forEach keys _forward; _forward = _pairs};
    [_object, _side, _radius, _knownEnemies, _forward] remoteExecCall ["Waldo_fnc_TacticalDisplayRegister", 2];
    true
};
if (isNull _object) exitWith {false};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {false};
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
[_object] remoteExecCall ["Waldo_fnc_TacticalDisplaySetupLocal", 0, format ["Waldo_TacticalDisplay_%1", netId _object]];
if (_interactionEnabled) then {
    [_object, [_challengeId, _difficulty]] remoteExecCall ["Waldo_fnc_TacticalDisplayInteractionSetup", 0, _object];
};
true
