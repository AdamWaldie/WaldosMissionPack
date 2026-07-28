/*
 * Author: Waldo
 * Validates all carrier, hub and deployed-crate field-resupply operations on the server.
 *
 * Arguments: 0: unit <OBJECT>; 1: operation <STRING>; 2: arguments <ARRAY>
 * Return Value: Boolean
 */

params [["_unit", objNull, [objNull]], ["_operation", "", [""]], ["_arguments", [], [[]]]];
if !(isServer) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FieldResupply_Enable", false]) exitWith {false};
if (isNull _unit || {!alive _unit} || {remoteExecutedOwner > 0 && {owner _unit != remoteExecutedOwner}}) exitWith {false};
private _notify = {params ["_text"]; [_text] remoteExecCall ["systemChat", owner _unit]};

switch (toUpperANSI _operation) do {
    case "REFILL": {
        private _hub = _arguments param [0, objNull];
        if (isNull _hub || {!(_hub getVariable ["Waldo_FieldResupply_Hub", false])} || {_unit distance _hub > 5}) exitWith {false};
        private _hubSide = _hub getVariable ["Waldo_FieldResupply_Side", sideUnknown];
        if (_hubSide != sideUnknown && {_hubSide getFriend (side group _unit) < 0.6}) exitWith {"[WMP] This supply hub will not service your side." call _notify; false};
        private _stock = _hub getVariable ["Waldo_FieldResupply_Stock", -1];
        if (_stock == 0) exitWith {"[WMP] This supply hub is empty." call _notify; false};
        private _maximum = _unit getVariable ["Waldo_FieldResupply_MaxCrates", missionNamespace getVariable ["Waldo_FieldResupply_DefaultCarrierCapacity", 2]];
        private _needed = (_maximum - (_unit getVariable ["Waldo_FieldResupply_Crates", 0])) max 0;
        private _issued = if (_stock < 0) then {_needed} else {_needed min _stock};
        _unit setVariable ["Waldo_FieldResupply_Crates", (_unit getVariable ["Waldo_FieldResupply_Crates", 0]) + _issued, true];
        if (_stock >= 0) then {_hub setVariable ["Waldo_FieldResupply_Stock", _stock - _issued, true]};
        format ["[WMP] Carrier refilled with %1 crate(s).", _issued] call _notify;
        true
    };
    case "DEPLOY": {
        private _carried = _unit getVariable ["Waldo_FieldResupply_Crates", 0];
        if (_carried <= 0 || {vehicle _unit != _unit}) exitWith {false};
        private _class = missionNamespace getVariable ["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"];
        if !(isClass (configFile >> "CfgVehicles" >> _class)) exitWith {false};
        private _position = _unit modelToWorld [0, 1.8, 0];
        private _clearPosition = _position findEmptyPosition [0, 4, _class];
        if (count _clearPosition > 0) then {_position = _clearPosition};
        private _crate = createVehicle [_class, _position, [], 0, "CAN_COLLIDE"];
        clearWeaponCargoGlobal _crate; clearMagazineCargoGlobal _crate; clearItemCargoGlobal _crate; clearBackpackCargoGlobal _crate;
        _crate setVariable ["Waldo_FieldResupply_Deployed", true, true];
        _crate setVariable ["Waldo_FieldResupply_Charges", missionNamespace getVariable ["Waldo_FieldResupply_ChargesPerCrate", 5], true];
        _unit setVariable ["Waldo_FieldResupply_Crates", _carried - 1, true];
        [_crate] remoteExecCall ["Waldo_fnc_FieldResupplySetupCrateLocal", -2, format ["Waldo_FieldResupply_Crate_%1", netId _crate]];
        true
    };
    case "TAKE": {
        private _crate = _arguments param [0, objNull];
        if (isNull _crate || {!(_crate getVariable ["Waldo_FieldResupply_Deployed", false])} || {_unit distance _crate > 5}) exitWith {false};
        private _charges = _crate getVariable ["Waldo_FieldResupply_Charges", 0];
        if (_charges <= 0) exitWith {false};
        private _allowed = missionNamespace getVariable ["Waldo_FieldResupply_AllowedMagazines", []];
        private _blocked = missionNamespace getVariable ["Waldo_FieldResupply_BlockedMagazines", []];
        private _minimumRounds = missionNamespace getVariable ["Waldo_FieldResupply_MinimumMagazineRounds", 2];
        private _classes = (magazines _unit) arrayIntersect (magazines _unit);
        _classes = _classes select {
            _x notIn _blocked && {(count _allowed == 0 || {_x in _allowed})} && {getNumber (configFile >> "CfgMagazines" >> _x >> "count") >= _minimumRounds}
        };
        if (count _classes == 0) exitWith {"[WMP] No compatible carried magazine types were found." call _notify; false};
        _crate setVariable ["Waldo_FieldResupply_Charges", _charges - 1, true];
        [_classes, missionNamespace getVariable ["Waldo_FieldResupply_MagazinesPerType", 1]] remoteExecCall ["Waldo_fnc_FieldResupplyReceiveAmmo", owner _unit];
        true
    };
    case "SALVAGE": {
        private _crate = _arguments param [0, objNull];
        if (isNull _crate || {!(_crate getVariable ["Waldo_FieldResupply_Deployed", false])} || {_unit distance _crate > 5}) exitWith {false};
        private _maximum = _unit getVariable ["Waldo_FieldResupply_MaxCrates", 0];
        private _carried = _unit getVariable ["Waldo_FieldResupply_Crates", 0];
        if (_maximum <= _carried) exitWith {"[WMP] Carrier capacity is full." call _notify; false};
        _unit setVariable ["Waldo_FieldResupply_Crates", _carried + 1, true];
        [] remoteExecCall ["", format ["Waldo_FieldResupply_Crate_%1", netId _crate]];
        deleteVehicle _crate;
        true
    };
    default {false};
}
