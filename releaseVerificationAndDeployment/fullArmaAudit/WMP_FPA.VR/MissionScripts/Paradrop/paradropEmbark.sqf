/*
 * Author: WaldoTheWarfighter
 * Server-authoritative ZEN boarding service for a registered dynamic paradrop operation. It can
 * move selected players/groups directly into cargo, create a terrain-snapped boarding point with
 * a repeat-safe blue addAction, or do both. Requests are curator-authenticated; only active player
 * units are transferred and available cargo capacity is checked again on each owning client.
 *
 * Arguments:
 * 0: operation ID <STRING>
 * 1: mode <STRING> - SELECTION, POLE or BOTH
 * 2: selected units <ARRAY> - curator selection expanded client-side; non-players are ignored
 * 3: boarding-point position <ARRAY>
 * 4: boarding-point class <STRING>
 * 5: boarding-point label <STRING>
 * 6: requester <OBJECT> - curator player used to authorise remote requests
 *
 * Return Value:
 * Boolean - true when at least one requested boarding surface was created or dispatched.
 *
 * Called by:
 * Paradrop - Embark Players ZEN module through Waldo_fnc_ParadropDropZoneZen.
 *
 * Example:
 * ["DZ_ALPHA", "BOTH", units group player, getPosATL player, "Land_InfoStand_V1_F",
 *  "Board DZ ALPHA", player] remoteExecCall ["Waldo_fnc_ParadropEmbark", 2];
 */

params [
    ["_id", "", [""]],
    ["_mode", "SELECTION", [""]],
    ["_selectedUnits", [], [[]]],
    ["_position", [], [[]]],
    ["_pointClass", "Land_InfoStand_V1_F", [""]],
    ["_label", "Board Paradrop Aircraft", [""]],
    ["_requester", objNull, [objNull]]
];

if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_ParadropEmbark", 2]; true};
if (remoteExecutedOwner > 0) then {
    if (isNull _requester || {owner _requester != remoteExecutedOwner} || {isNull getAssignedCuratorLogic _requester}) exitWith {false};
};

private _notify = {
    params ["_message", ["_state", "INFO"]];
    if (!isNull _requester) then {
        ["PARADROP EMBARK", _message, _state, "PARADROP_EMBARK", 7]
            remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
    };
};

private _registry = missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap];
if !(_id in keys _registry) exitWith {["The selected paradrop operation no longer exists.", "ERROR"] call _notify; false};
private _state = _registry get _id;
private _aircraft = _state getOrDefault ["aircraft", objNull];
private _name = _state getOrDefault ["name", _id];
if (isNull _aircraft || {!alive _aircraft}) exitWith {["The selected paradrop aircraft is unavailable.", "ERROR"] call _notify; false};

_mode = toUpperANSI _mode;
if !(_mode in ["SELECTION", "POLE", "BOTH"]) then {_mode = "SELECTION"};
private _didWork = false;

if (_mode in ["SELECTION", "BOTH"]) then {
    private _players = _selectedUnits select {!isNull _x && {_x in allPlayers}};
    _players = _players arrayIntersect _players;
    if (count _players == 0) then {
        ["No selected player units were available for direct cargo transfer.", "WARNING"] call _notify;
    } else {
        private _available = _aircraft emptyPositions "cargo";
        private _accepted = _players select [0, _available max 0];
        {
            [_x, _aircraft, _name] remoteExecCall ["Waldo_fnc_ParadropEmbarkLocal", owner _x];
        } forEach _accepted;
        _didWork = count _accepted > 0;
        [format ["Sent %1 of %2 selected player(s) to available cargo seats.", count _accepted, count _players], if (count _accepted == count _players) then {"SUCCESS"} else {"WARNING"}]
            call _notify;
    };
};

if (_mode in ["POLE", "BOTH"]) then {
    if (count _position < 2 || {!(isClass (configFile >> "CfgVehicles" >> _pointClass))}) then {
        ["The boarding-point position or class is invalid.", "ERROR"] call _notify;
    } else {
        private _pointPosition = [_position select 0, _position select 1, 0];
        private _point = createVehicle [_pointClass, _pointPosition, [], 0, "CAN_COLLIDE"];
        _point setPosATL _pointPosition;
        _point setVectorUp (surfaceNormal _pointPosition);
        _point allowDamage false;
        _point setVariable ["Waldo_Paradrop_BoardingOperation", _id, true];
        [_point, _aircraft, _label] remoteExec ["Waldo_fnc_MoveInCargoPlane", 0, _point];
        private _points = +(_state getOrDefault ["boardingPoints", []]);
        _points pushBack _point;
        _state set ["boardingPoints", _points];
        _registry set [_id, _state];
        missionNamespace setVariable ["Waldo_Paradrop_DropZones", _registry];
        { _x addCuratorEditableObjects [[_point], false] } forEach allCurators;
        _didWork = true;
        [format ["Boarding point created for %1.", _name], "SUCCESS"] call _notify;
    };
};

_didWork
