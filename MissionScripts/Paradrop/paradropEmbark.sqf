/*
 * Author: WaldoTheWarfighter
 * Server-authoritative boarding service for a dynamic paradrop operation OR a mission maker's own
 * placed-and-crewed aircraft set up with Waldo_fnc_ParadropQuickFlightSetup. It can move selected
 * players directly into cargo or create a terrain-snapped boarding object with a repeat-safe blue
 * addAction. Flag carriers receive the standard blue flag texture. Boarding objects have simulation
 * disabled and are explicitly added to every curator so they remain safe to reposition in Zeus.
 * Requests are curator-authenticated; only active player units are transferred and available cargo
 * capacity is checked again on each owning client. The operation ID is looked up in the
 * Waldo_fnc_ParadropCreateDropZone registry first; if not found there, it falls back to
 * Waldo_Paradrop_PublicAircraft (also fed by Waldo_fnc_ParadropQuickFlightSetup), so this works for
 * editor-placed aircraft that were never registered as a managed drop zone operation. A boarding
 * point created against a non-registered aircraft is not tracked for later cleanup, since there is
 * no Waldo_fnc_ParadropRemoveDropZone call for it - it is left on the map like any other placed object.
 *
 * Arguments:
 * 0: operation ID <STRING> - a Waldo_fnc_ParadropCreateDropZone id, or a
 *    Waldo_Paradrop_PublicAircraft id (e.g. a Waldo_fnc_ParadropQuickFlightSetup aircraft's
 *    "QUICK_<netId>" id).
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
    ["_pointClass", "FlagPole_F", [""]],
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
private _isRegistered = _id in keys _registry;
private _state = if (_isRegistered) then {_registry get _id} else {createHashMap};
private _aircraft = objNull;
private _name = _id;
if (_isRegistered) then {
    _aircraft = _state getOrDefault ["aircraft", objNull];
    _name = _state getOrDefault ["name", _id];
} else {
    // Falls back to Waldo_Paradrop_PublicAircraft - fed by Waldo_fnc_ParadropQuickFlightSetup as well
    // as the registry above - so a curator can also embark players onto a mission maker's own
    // placed-and-crewed aircraft (no Waldo_fnc_ParadropCreateDropZone registry entry at all), not just
    // registry-backed Dynamic Drop Zone operations. Only SELECTION/POLE cargo transfer makes sense
    // here - there is no jumper/registry state to update, so boarding points created this way are not
    // tracked for later cleanup (there is no matching Waldo_fnc_ParadropRemoveDropZone call for them).
    private _publicAircraft = missionNamespace getVariable ["Waldo_Paradrop_PublicAircraft", []];
    private _entry = _publicAircraft findIf {(_x select 0) == _id};
    if (_entry >= 0) then {
        (_publicAircraft select _entry) params ["", "_entryName", "_entryAircraft"];
        _aircraft = _entryAircraft;
        _name = _entryName;
    };
};
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
        if (_point isKindOf "FlagCarrierCore") then {_point setFlagTexture "\A3\Data_F\Flags\Flag_blue_CO.paa";};
        _point setVariable ["Waldo_Paradrop_BoardingOperation", _id, true];
        [_point, _aircraft, _label] remoteExec ["Waldo_fnc_MoveInCargoPlane", 0, _point];
        if (_isRegistered) then {
            private _points = +(_state getOrDefault ["boardingPoints", []]);
            _points pushBack _point;
            _state set ["boardingPoints", _points];
            _registry set [_id, _state];
            missionNamespace setVariable ["Waldo_Paradrop_DropZones", _registry];
        };
        [_point, owner _requester, false, false] call Waldo_fnc_ZenAssignObjectOwnerServer;
        _didWork = true;
        [format ["Boarding point created for %1.", _name], "SUCCESS"] call _notify;
    };
};

_didWork
