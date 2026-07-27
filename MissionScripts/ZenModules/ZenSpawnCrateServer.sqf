/*
 * Creates and populates a ZEN logistics crate on the server.
 * The ZEN dialog remains local to the curator; all world and cargo mutation is
 * performed here so dedicated clients cannot create divergent crate state.
 *
 * Arguments:
 * 0: kind <STRING> - "SUPPLY" or "MEDICAL"
 * 1: position <ARRAY>
 * 2: settings <ARRAY>
 * 3: actor <OBJECT>
 *
 * Return Value:
 * Created crate <OBJECT>, or objNull
 */

params [
    ["_kind", "", [""]],
    ["_position", [], [[]]],
    ["_settings", [], [[]]],
    ["_actor", objNull, [objNull]]
];

if (!isServer) exitWith {
    [_kind, _position, _settings, player] remoteExecCall ["Waldo_fnc_ZenSpawnCrateServer", 2];
    objNull
};

private _requestOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
if (isRemoteExecuted && {
    isNull _actor
    || {_requestOwner != owner _actor}
    || {isNull (getAssignedCuratorLogic _actor)}
}) exitWith {
    diag_log format ["[WMP ZEN] rejected crate request kind=%1 owner=%2 actor=%3", _kind, _requestOwner, _actor];
    objNull
};
if ((count _position) < 2 || {!(_kind in ["SUPPLY", "MEDICAL"])}) exitWith {objNull};

// Use the Zeus module's horizontal placement and seat the crate on the first
// physical surface below it. This supports roofs, decks and placed platforms;
// terrain at ATL zero remains the safe fallback when no geometry is found.
private _placeCrate = {
    params ["_crateClass"];
    private _x = _position select 0;
    private _y = _position select 1;
    private _z = _position param [2, 0];
    private _startASL = ATLToASL [_x, _y, _z + 5];
    private _endASL = ATLToASL [_x, _y, -50];
    private _hits = lineIntersectsSurfaces [_startASL, _endASL, objNull, objNull, true, 1, "GEOM", "NONE"];
    private _crate = createVehicle [_crateClass, [_x, _y, 0], [], 0, "CAN_COLLIDE"];
    if (_hits isEqualTo []) then {
        _crate setPosATL [_x, _y, 0];
    } else {
        (_hits select 0) params ["_surfaceASL", "_surfaceNormal"];
        private _bounds = boundingBoxReal _crate;
        private _bottom = ((_bounds select 0) select 2) min 0;
        private _lift = (-_bottom) + 0.01;
        _crate setVectorUp _surfaceNormal;
        _crate setPosASL (_surfaceASL vectorAdd (_surfaceNormal vectorMultiply _lift));
    };
    _crate
};

private _crate = objNull;
switch (_kind) do {
    case "SUPPLY": {
        _settings params [
            ["_size", 0.5, [0]],
            ["_side", west, [west]],
            ["_includeEquipment", true, [true]],
            ["_includeLaunchers", true, [true]]
        ];
        private _crateClass = missionNamespace getVariable ["Logi_SupplyBoxClass", "B_CargoNet_01_ammo_F"];
        if !(isClass (configFile >> "CfgVehicles" >> _crateClass)) then {_crateClass = "B_CargoNet_01_ammo_F";};
        _crate = [_crateClass] call _placeCrate;
        [_crate, _size, _side, _includeEquipment, _includeLaunchers] call Waldo_fnc_SupplyCratePopulate;
        [_crate, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;
    };
    case "MEDICAL": {
        _settings params [
            ["_size", 0.5, [0]],
            ["_fieldHospital", true, [true]]
        ];
        private _crateClass = missionNamespace getVariable ["Logi_MedicalBoxClass", "C_IDAP_supplyCrate_F"];
        if !(isClass (configFile >> "CfgVehicles" >> _crateClass)) then {_crateClass = "C_IDAP_supplyCrate_F";};
        _crate = [_crateClass] call _placeCrate;
        [_crate, _fieldHospital, _size] call Waldo_fnc_MedicalCratePopulate;
        [_crate, 1] call ace_cargo_fnc_setSize;
        [_crate, true] call ace_dragging_fnc_setDraggable;
        [_crate, true] call ace_dragging_fnc_setCarryable;
    };
};

if (!isNull _crate) then {
    { _x addCuratorEditableObjects [[_crate], true]; } forEach allCurators;
    diag_log format ["[WMP ZEN] crate created kind=%1 crate=%2 actor=%3 owner=%4", _kind, netId _crate, if (isNull _actor) then {"<server>"} else {name _actor}, _requestOwner];
};
_crate
