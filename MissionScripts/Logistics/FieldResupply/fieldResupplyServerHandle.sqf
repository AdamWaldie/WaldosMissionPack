/*
 * Author: WaldoTheWarfighter
 * Validates and executes every Field Resupply operation on the server.
 *
 * The handler is the sole writer for hub stock, carrier stock, deployed-crate charges and logical
 * ammunition rows. Deployed crates deliberately keep empty physical inventory so Gear access
 * cannot bypass charge consumption. Remote callers may act only through the unit they own. Carrier operations
 * require a configured carrier and the same backpack/on-foot conditions shown by local actions.
 * Deployed crates derive logical supply rows from the carrier's actual magazine types, excluding
 * single-round ordnance by default. Capacity-based issue amounts preserve useful weapon-category
 * quantities and remain configurable. Empty placement, incompatible supply and salvage edge cases
 * fail safely.
 *
 * Arguments:
 * 0: unit <OBJECT> - requesting player unit.
 * 1: operation <STRING> - REFILL, DEPLOY, TAKE or SALVAGE.
 * 2: arguments <ARRAY> - REFILL expects hub at index 0; TAKE/SALVAGE expect crate at index 0.
 *
 * Return Value:
 * Boolean - true when the requested state change completed; otherwise false.
 *
 * Example:
 * [player, "DEPLOY", []] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2];
 *
 * Current callers: carrier self-actions, registered hub actions and deployed-crate actions.
 */

params [["_unit", objNull, [objNull]], ["_operation", "", [""]], ["_arguments", [], [[]]]];
if !(isServer) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FieldResupply_Enable", false]) exitWith {false};
if (isNull _unit || {!alive _unit} || {remoteExecutedOwner > 0 && {owner _unit != remoteExecutedOwner}}) exitWith {false};

private _notify = {
    params ["_text", ["_state", "INFO"]];
    ["FIELD RESUPPLY", _text, _state, "FIELD_RESUPPLY"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _unit];
};
private _isCarrier = {_unit getVariable ["Waldo_FieldResupply_MaxCrates", 0] > 0};
private _hasPack = {backpack _unit != ""};
private _getMagazineRows = {
    params ["_sourceUnit"];
    private _allowed = missionNamespace getVariable ["Waldo_FieldResupply_AllowedMagazines", []];
    private _blocked = missionNamespace getVariable ["Waldo_FieldResupply_BlockedMagazines", []];
    private _minimumRounds = (round (missionNamespace getVariable ["Waldo_FieldResupply_MinimumMagazineRounds", 2])) max 1;
    private _classes = [];
    {
        private _class = _x param [0, "", [""]];
        if (_class != "") then {_classes pushBackUnique _class};
    } forEach (magazinesAmmoFull _sourceUnit);
    _classes = _classes select {
        !(_x in _blocked)
        && {(count _allowed == 0 || {_x in _allowed})}
        && {getNumber (configFile >> "CfgMagazines" >> _x >> "count") >= _minimumRounds}
    };
    private _useCapacity = missionNamespace getVariable ["Waldo_FieldResupply_UseCapacityBasedAmounts", true];
    private _fixedAmount = (round (missionNamespace getVariable ["Waldo_FieldResupply_MagazinesPerType", 1])) max 1;
    private _amounts = +(missionNamespace getVariable ["Waldo_FieldResupply_CapacityAmounts", [4, 3, 8, 3, 2]]);
    _amounts resize 5;
    {
        if (isNil {_x} || {!(_x isEqualType 0)}) then {_amounts set [_forEachIndex, [4, 3, 8, 3, 2] select _forEachIndex]};
        _amounts set [_forEachIndex, (round (_amounts select _forEachIndex)) max 1];
    } forEach _amounts;
    _classes apply {
        private _capacity = getNumber (configFile >> "CfgMagazines" >> _x >> "count");
        private _amount = if !(_useCapacity) then {_fixedAmount} else {
            switch (true) do {
                case (_capacity <= 4): {_amounts select 0};
                case (_capacity <= 10): {_amounts select 1};
                case (_capacity <= 40): {_amounts select 2};
                case (_capacity <= 70): {_amounts select 3};
                default {_amounts select 4};
            }
        };
        [_x, _amount]
    }
};

switch (toUpperANSI _operation) do {
    case "REFILL": {
        private _hub = _arguments param [0, objNull, [objNull]];
        if (isNull _hub || {!(_hub getVariable ["Waldo_FieldResupply_Hub", false])} || {_unit distance _hub > 5}) exitWith {
            ["No registered supply hub is within reach.", "WARNING"] call _notify;
            false
        };
        if !(call _isCarrier) exitWith {["You are not assigned as a Field Resupply carrier.", "WARNING"] call _notify; false};
        if !(call _hasPack) exitWith {["A backpack is required to carry field-resupply crates.", "WARNING"] call _notify; false};
        private _hubSide = _hub getVariable ["Waldo_FieldResupply_Side", sideUnknown];
        if (_hubSide != sideUnknown && {_hubSide getFriend (side group _unit) < 0.6}) exitWith {
            ["This supply hub will not service your side.", "WARNING"] call _notify;
            false
        };
        private _stock = _hub getVariable ["Waldo_FieldResupply_Stock", -1];
        if (_stock == 0) exitWith {["This supply hub is empty.", "WARNING"] call _notify; false};
        private _maximum = _unit getVariable ["Waldo_FieldResupply_MaxCrates", 0];
        private _current = _unit getVariable ["Waldo_FieldResupply_Crates", 0];
        private _needed = (_maximum - _current) max 0;
        if (_needed <= 0) exitWith {["Your Field Resupply carrier is already full.", "INFO"] call _notify; false};
        private _issued = if (_stock < 0) then {_needed} else {_needed min _stock};
        if (_issued <= 0) exitWith {["This supply hub cannot issue another crate.", "WARNING"] call _notify; false};
        _unit setVariable ["Waldo_FieldResupply_Crates", _current + _issued, true];
        if (_stock >= 0) then {_hub setVariable ["Waldo_FieldResupply_Stock", _stock - _issued, true]};
        [format ["Carrier refilled with %1 crate(s); now carrying %2 of %3.", _issued, _current + _issued, _maximum], "SUCCESS"] call _notify;
        true
    };

    case "DEPLOY": {
        if !(call _isCarrier) exitWith {["You are not assigned as a Field Resupply carrier.", "WARNING"] call _notify; false};
        if !(call _hasPack) exitWith {["A backpack is required to deploy field resupply.", "WARNING"] call _notify; false};
        if (vehicle _unit != _unit) exitWith {["Leave the vehicle before deploying field resupply.", "WARNING"] call _notify; false};
        private _carried = _unit getVariable ["Waldo_FieldResupply_Crates", 0];
        if (_carried <= 0) exitWith {["No field-resupply crates remain in your carrier.", "WARNING"] call _notify; false};
        private _class = missionNamespace getVariable ["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"];
        if !(isClass (configFile >> "CfgVehicles" >> _class)) exitWith {
            [format ["Configured crate class %1 is unavailable.", _class], "ERROR"] call _notify;
            false
        };
        private _origin = _unit modelToWorld [0, 1.8, 0];
        private _position = _origin findEmptyPosition [0.5, 5, _class];
        if (count _position == 0) exitWith {
            ["There is no clear space in front of you for the resupply crate.", "WARNING"] call _notify;
            false
        };
        private _rows = [_unit] call _getMagazineRows;
        if (count _rows == 0) exitWith {
            ["You carry no compatible multi-round magazines to package.", "WARNING"] call _notify;
            false
        };
        private _charges = (round (missionNamespace getVariable ["Waldo_FieldResupply_ChargesPerCrate", 5])) max 1;
        private _crate = createVehicle [_class, _position, [], 0, "NONE"];
        if (isNull _crate) exitWith {["The resupply crate could not be created.", "ERROR"] call _notify; false};
        _crate setDir (getDir _unit);
        _crate setPosATL _position;
        _crate allowDamage false;
        clearWeaponCargoGlobal _crate;
        clearMagazineCargoGlobal _crate;
        clearItemCargoGlobal _crate;
        clearBackpackCargoGlobal _crate;
        _crate setVariable ["Waldo_FieldResupply_Deployed", true, true];
        _crate setVariable ["Waldo_FieldResupply_Charges", _charges, true];
        _crate setVariable ["Waldo_FieldResupply_InitialCharges", _charges, true];
        _crate setVariable ["Waldo_FieldResupply_CargoRows", _rows, true];
        _unit setVariable ["Waldo_FieldResupply_Crates", _carried - 1, true];
        if !(isNil "ace_dragging_fnc_setDraggable") then {[_crate, false, [0, 0, 0], 0] call ace_dragging_fnc_setDraggable};
        if !(isNil "ace_dragging_fnc_setCarryable") then {[_crate, true, [0, 2, 1], 0] call ace_dragging_fnc_setCarryable};
        [_crate] remoteExecCall ["Waldo_fnc_FieldResupplySetupCrateLocal", -2, format ["Waldo_FieldResupply_Crate_%1", netId _crate]];
        [format ["Field resupply deployed with %1 uses; %2 portable crate(s) remain.", _charges, _carried - 1], "SUCCESS"] call _notify;
        true
    };

    case "TAKE": {
        private _crate = _arguments param [0, objNull, [objNull]];
        if (isNull _crate || {!(_crate getVariable ["Waldo_FieldResupply_Deployed", false])} || {_unit distance _crate > 5}) exitWith {
            ["No deployed Field Resupply crate is within reach.", "WARNING"] call _notify;
            false
        };
        private _charges = _crate getVariable ["Waldo_FieldResupply_Charges", 0];
        if (_charges <= 0) exitWith {["This Field Resupply crate is exhausted.", "WARNING"] call _notify; false};
        private _compatibleClasses = ([_unit] call _getMagazineRows) apply {_x select 0};
        private _storedRows = _crate getVariable ["Waldo_FieldResupply_CargoRows", []];
        private _grantRows = _storedRows select {(_x param [0, "", [""]]) in _compatibleClasses};
        if (count _grantRows == 0) exitWith {
            ["No compatible ammunition remains in this crate.", "WARNING"] call _notify;
            false
        };
        _crate setVariable ["Waldo_FieldResupply_Charges", _charges - 1, true];
        [_grantRows] remoteExecCall ["Waldo_fnc_FieldResupplyReceiveAmmo", owner _unit];
        if (_charges - 1 <= 0) then {
            ["This Field Resupply crate is now exhausted.", "INFO"] call _notify;
        };
        true
    };

    case "SALVAGE": {
        private _crate = _arguments param [0, objNull, [objNull]];
        if (isNull _crate || {!(_crate getVariable ["Waldo_FieldResupply_Deployed", false])} || {_unit distance _crate > 5}) exitWith {
            ["No deployed Field Resupply crate is within reach.", "WARNING"] call _notify;
            false
        };
        if !(call _isCarrier) exitWith {["Only an assigned Field Resupply carrier can salvage this crate.", "WARNING"] call _notify; false};
        if !(call _hasPack) exitWith {["A backpack is required to salvage a field-resupply crate.", "WARNING"] call _notify; false};
        private _charges = _crate getVariable ["Waldo_FieldResupply_Charges", 0];
        private _initialCharges = _crate getVariable ["Waldo_FieldResupply_InitialCharges", missionNamespace getVariable ["Waldo_FieldResupply_ChargesPerCrate", 5]];
        private _recoverable = _charges >= _initialCharges;
        private _maximum = _unit getVariable ["Waldo_FieldResupply_MaxCrates", 0];
        private _carried = _unit getVariable ["Waldo_FieldResupply_Crates", 0];
        if (_recoverable && {_carried >= _maximum}) exitWith {["Carrier capacity is full.", "WARNING"] call _notify; false};
        [] remoteExecCall ["", format ["Waldo_FieldResupply_Crate_%1", netId _crate]];
        deleteVehicle _crate;
        if (_recoverable) then {
            _unit setVariable ["Waldo_FieldResupply_Crates", _carried + 1, true];
            [format ["Unused crate salvaged; now carrying %1 of %2.", _carried + 1, _maximum], "SUCCESS"] call _notify;
        } else {
            ["Partly used crate removed; no portable crate was recovered.", "INFO"] call _notify;
        };
        true
    };

    default {false};
}
