/*
 * Author: WaldoTheWarfighter
 * Purpose: Validates and applies a named ACE service-role patch without refilling untouched stocks.
 * Locality / Authority: Server-local, unscheduled worker only; direct remote calls are rejected.
 * Repeat / JIP: Repeated enabled roles preserve consumption. ACE publishes actions and stock;
 *   repair/medical flags and the diagnostic role snapshot are public. Disabled sources retain
 *   their ACE action installation with hidden conditions, avoiding duplicate actions on re-enable.
 * Arguments: 0: vehicle <OBJECT> (objNull); 1: named options <ARRAY> ([]), as VehicleServicesConfigure.
 * Return Value: <ARRAY> [success BOOL, operator message STRING]. Validates the whole patch before writes.
 * Current caller: Waldo_fnc_VehicleServicesConfigure after ACE settings and mission startup.
 * Example: [myTruck, [["medical",true]]] call Waldo_fnc_VehicleServicesApplyServer;
 */
params [["_vehicle", objNull, [objNull]], ["_pairs", [], [[]]]];
if (!isServer || {isRemoteExecuted}) exitWith {[false, "Use the server-local vehicle service API."]};
if (isNull _vehicle || {!alive _vehicle} || {_vehicle isKindOf "StaticWeapon"}
    || {!(_vehicle isKindOf "LandVehicle" || {_vehicle isKindOf "Air"} || {_vehicle isKindOf "Ship"})}) exitWith {
    [false, "Select a live land vehicle, aircraft or boat."]
};
if !(missionNamespace getVariable ["ace_common_settingsInitFinished", false]) exitWith {[false, "ACE settings are not ready."]};
private _booleanKeys = ["rearm", "refuel", "repair", "medical", "refillFuel", "refillRearm"];
private _known = _booleanKeys + ["fuelLitres", "rearmSupply"];
private _keys = [];
private _valid = true;
{
    if (isNil "_x" || {!(_x isEqualType [] && {count _x == 2})}) exitWith {_valid = false};
    private _key = _x param [0, objNull];
    private _value = _x param [1, objNull];
    if (!(_key isEqualType "") || {!(_key in _known)} || {_key in _keys}) exitWith {_valid = false};
    _keys pushBack _key;
    if (_key in _booleanKeys) then {
        if !(_value isEqualType true) then {_valid = false};
    } else {
        if !(_value isEqualType 0) then {_valid = false} else {
            if (!finite _value || {_value != round _value} || {_value > 1000000}
                || {_value < 0 && {!(_key == "fuelLitres" && {_value == -10})}}) then {_valid = false};
        };
    };
    if (!_valid) exitWith {};
} forEach _pairs;
if (!_valid) exitWith {[false, "Invalid service options: use unique named keys, Booleans and whole-number stock amounts from 0 to 1000000 (-10 for unlimited fuel)."]};
private _settings = createHashMapFromArray _pairs;
private _refillFuel = _settings getOrDefault ["refillFuel", false];
private _refillRearm = _settings getOrDefault ["refillRearm", false];
private _fuelRequested = "refuel" in _keys || {_refillFuel};
private _rearmRequested = "rearm" in _keys || {_refillRearm};
// Reject unavailable selected services before changing any of the other roles.
private _missing = [];
if (_fuelRequested && {isNil "ace_refuel_fnc_makeSource" || {isNil "ace_refuel_fnc_getFuelCargo"}
    || {isNil "ace_refuel_fnc_setFuel"}}) then {_missing pushBack "ACE Refuel"};
if (_rearmRequested && {isNil "ace_rearm_fnc_makeSource" || {isNil "ace_rearm_fnc_isSource"}}) then {_missing pushBack "ACE Rearm"};
if ("repair" in _keys && {isNil "ace_repair_fnc_isRepairVehicle"}) then {_missing pushBack "ACE Repair"};
if ("medical" in _keys && {isNil "ace_medical_treatment_fnc_isMedicalVehicle"}) then {_missing pushBack "ACE Medical Treatment"};
if (_missing isNotEqualTo []) exitWith {[false, format ["Required components missing: %1.", _missing joinString ", "]]};
// Read the same config default as ACE without invoking getCapacity: that getter initializes stock.
private _fuelCapacity = _vehicle getVariable ["ace_refuel_capacity", if (isNil "ace_refuel_fnc_getFuelCargo") then {-1}
    else {[_vehicle] call ace_refuel_fnc_getFuelCargo}];
private _fuelWas = _fuelCapacity != -1;
private _rearmWas = if (isNil "ace_rearm_fnc_isSource") then {false}
    else {[_vehicle] call ace_rearm_fnc_isSource};
private _fuel = _settings getOrDefault ["refuel", _fuelWas];
private _rearm = _settings getOrDefault ["rearm", _rearmWas];
if ((_refillFuel && {!_fuel}) || {_refillRearm && {!_rearm}}) exitWith {[false, "Enable the matching service before requesting its refill."]};
if (_fuelRequested && {_fuel} && {!(missionNamespace getVariable ["ace_refuel_enabled", false])}) exitWith {[false, "ACE Refuel is disabled in the mission settings."]};
if (_rearmRequested && {_rearm} && {!(missionNamespace getVariable ["ace_rearm_enabled", false])}) exitWith {[false, "ACE Rearm is disabled in the mission settings."]};
if (_rearmRequested && {_rearm} && {!((missionNamespace getVariable ["ace_rearm_supply", 0]) in [0, 1])}) exitWith {
    [false, "This source setup supports ACE unlimited or supply-point rearm mode. Magazine-based mode is not supported."]
};
if (_fuelRequested && {(!_fuel || {_refillFuel})}
    && {_vehicle getVariable ["ace_refuel_isConnected", false]}) exitWith {
    [false, "Return the fuel nozzle before disabling or refilling this source."]
};
if (_fuelRequested) then {
    if (_fuel) then {
        if (!_fuelWas || {_refillFuel}) then {
            private _amount = _settings getOrDefault ["fuelLitres", _vehicle getVariable ["Waldo_VehicleServices_SavedFuel", 1000]];
            if (_vehicle getVariable ["Waldo_VehicleServices_FuelInitialized", false]) then {
                // Keep ACE's lifetime-bound action replay when disabling. Re-enable only the source state.
                private _capacity = if (_amount == -10) then {-10} else {
                    _amount max (_vehicle getVariable ["Waldo_VehicleServices_FuelCapacity", _amount])
                };
                _vehicle setVariable ["ace_refuel_capacity", _capacity, true];
                [_vehicle, _amount] call ace_refuel_fnc_setFuel;
            } else {
                [_vehicle, _amount] call ace_refuel_fnc_makeSource;
                _vehicle setVariable ["Waldo_VehicleServices_FuelInitialized", true];
            };
            _vehicle setVariable ["Waldo_VehicleServices_FuelCapacity", _vehicle getVariable ["ace_refuel_capacity", _amount]];
        };
    } else {
        if (_fuelWas) then {
            _vehicle setVariable ["Waldo_VehicleServices_SavedFuel", if (_fuelCapacity == -10) then {-10} else {_vehicle getVariable ["ace_refuel_currentFuelCargo", _fuelCapacity]}];
            _vehicle setVariable ["Waldo_VehicleServices_FuelCapacity", _fuelCapacity];
        };
        // ACE Refuel's -1 capacity disables the source on current clients and JIP without
        // removing its action JIP event. A subsequent enable must not install duplicate actions.
        _vehicle setVariable ["ace_refuel_capacity", -1, true];
    };
};
if (_rearmRequested) then {
    if (_rearm) then {
        if (!_rearmWas || {_refillRearm}) then {
            private _amount = _settings getOrDefault ["rearmSupply", _vehicle getVariable ["Waldo_VehicleServices_SavedRearm", 1000]];
            [_vehicle, _amount, false] call ace_rearm_fnc_makeSource;
            if (!_rearmWas) then {
                // A client that joined while a custom source was disabled skipped ACE's action
                // setup. Replay to current clients on enable; ACE deduplicates installed actions.
                ["ace_rearm_initSupplyVehicle", [_vehicle]] call CBA_fnc_globalEvent;
            };
        };
    } else {
        if (_rearmWas) then {_vehicle setVariable ["Waldo_VehicleServices_SavedRearm", _vehicle getVariable ["ace_rearm_currentSupply", (getNumber (configOf _vehicle >> "ace_rearm_defaultSupply")) max (getNumber (configOf _vehicle >> "transportAmmo"))]]};
        // A false isSupplyVehicle flag alone cannot disable a class with transportAmmo.
        // ACE's source and take/store-ammo checks reject a negative currentSupply.
        _vehicle setVariable ["ace_rearm_currentSupply", -1, true];
        _vehicle setVariable ["ace_rearm_isSupplyVehicle", false, true];
    };
};
if ("repair" in _keys) then {_vehicle setVariable ["ACE_isRepairVehicle", _settings get "repair", true]};
if ("medical" in _keys) then {_vehicle setVariable ["ace_medical_isMedicalVehicle", _settings get "medical", true]};
private _repair = _vehicle getVariable ["ACE_isRepairVehicle", getNumber (configOf _vehicle >> "ace_repair_canRepair") > 0
    || {getNumber (configOf _vehicle >> "transportRepair") > 0}];
private _medical = _vehicle getVariable ["ace_medical_isMedicalVehicle", getNumber (configOf _vehicle >> "attendant") > 0];
private _revision = ((_vehicle getVariable ["Waldo_VehicleServices_State", [0]]) select 0) + 1;
_vehicle setVariable ["Waldo_VehicleServices_State", [_revision, _rearm, _fuel, _repair in [true, 1], _medical], true];
[true, "Vehicle services applied. ACE mission rules still control treatment, repair and rearm requirements."]
