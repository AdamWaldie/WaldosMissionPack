/*
 * Author: WaldoTheWarfighter
 * Purpose: Opens independent ACE service-role selectors on the exact Zeus-selected vehicle.
 * Locality / Authority: Curator interface only. Named settings go to an authenticated server bridge.
 * Repeat / JIP: Transient dialog; defaults keep existing roles and stocks. ACE owns gameplay actions.
 * Arguments: 0: module position <ARRAY> ([]), unused; 1: selected vehicle <OBJECT> (objNull).
 * Return Value: <BOOL> dialog opened, false for an invalid selection.
 * Current caller: WMP Logistics / ACE Vehicle Services - Configure in Zen_initModules.sqf.
 * Example: [getPosATL truck, truck] call Waldo_fnc_ZenVehicleServicesModule;
 */
params [["_position", [], [[]]], ["_vehicle", objNull, [objNull]]];
if (!hasInterface) exitWith {false};
if (isNull _vehicle || {!alive _vehicle} || {_vehicle isKindOf "StaticWeapon"}
    || {!(_vehicle isKindOf "LandVehicle" || {_vehicle isKindOf "Air"} || {_vehicle isKindOf "Ship"})}) exitWith {
    ["ACE VEHICLE SERVICES", "Place this module directly on a live land vehicle, aircraft or boat.",
        "ERROR", "VEHICLE_SERVICES", 7] call Waldo_fnc_FeatureNotifyLocal;
    false
};
private _choices = [["KEEP", "ENABLE", "DISABLE"], ["Keep current", "Enable", "Disable"], 0];
["ACE Vehicle Services", [
    ["COMBO", ["Ammunition supply / rearm", "ACE vehicle/static-weapon ammunition source. Uses the mission's ACE rearm mode, not inventory magazines or Quartermaster issues."], _choices],
    ["COMBO", ["Fuel supply", "ACE hose/nozzle source. Service stock is separate from this vehicle's engine fuel."], _choices],
    ["COMBO", ["Repair vehicle", "Counts as an ACE repair vehicle. Engineer, tool and repair-location requirements still apply."], _choices],
    ["COMBO", ["Medical vehicle", "Counts as an ACE medical vehicle. Treatment permissions, supplies and patient-location rules still apply; this does not auto-heal."], _choices],
    ["SLIDER", ["Ammunition supply points", "Initial stock when newly enabled, or replacement stock when Refill ammunition is selected. Ignored for an already active service otherwise."], [0, 1000000, 1000, 0]],
    ["CHECKBOX", ["Refill ammunition now", "Explicitly replace current ammunition supply with the selected amount. Leave off to preserve consumed stock."], false],
    ["COMBO", ["Fuel stock mode", "Used on a new enable or explicit refill. Does not change an already active source on its own."], [["FINITE", "UNLIMITED"], ["Finite litres", "Unlimited"], 0]],
    ["SLIDER", ["Fuel supply litres", "Initial or replacement service stock, not the vehicle's own fuel tank. Used with Finite litres."], [0, 1000000, 1000, 0]],
    ["CHECKBOX", ["Refill fuel now", "Explicitly replace the source stock using the selected mode and litres. Leave off to preserve consumed stock."], false]
], {
    params ["_values", "_args"];
    _args params ["_vehicle"];
    _values params ["_rearm", "_refuel", "_repair", "_medical", "_rearmSupply", "_refillRearm", "_fuelMode", "_fuelLitres", "_refillFuel"];
    private _pairs = [];
    {
        _x params ["_key", "_choice"];
        if (_choice != "KEEP") then {_pairs pushBack [_key, _choice == "ENABLE"]};
    } forEach [["rearm", _rearm], ["refuel", _refuel], ["repair", _repair], ["medical", _medical]];
    if (_rearm == "ENABLE" || {_refillRearm}) then {
        _pairs append [["rearmSupply", round _rearmSupply], ["refillRearm", _refillRearm]];
    };
    if (_refuel == "ENABLE" || {_refillFuel}) then {
        _pairs append [["fuelLitres", if (_fuelMode == "UNLIMITED") then {-10} else {round _fuelLitres}], ["refillFuel", _refillFuel]];
    };
    [_vehicle, _pairs, player] remoteExecCall ["Waldo_fnc_ZenVehicleServicesServer", 2];
}, {}, [_vehicle]] call zen_dialog_fnc_create;
true
