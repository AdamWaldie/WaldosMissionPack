/*
 * Author: WaldoTheWarfighter
 * Purpose: Gives a WMP-managed portable object ACE Drag/Carry and a usable ACE
 *   loading size when its class has none. Ordinary crates do not gain ACE cargo
 *   storage space; vehicles retain their own configured capacity.
 * Locality / Authority: Server chooses the object and calls ACE's global setters.
 * Repeat / JIP: Existing object-level ACE size and WMP handling choices win;
 *   SetCargoAttributes and ACE replay the resulting state to joining clients.
 * Arguments: object <OBJECT>; role <STRING> (default "CARGO").
 * Return Value: <BOOL> accepted; false for starters, people and vehicles.
 * Current callers: WMP crate registration, physical cargo, supply transfers and
 *   economy resource-case creation.
 * Example: [myCrate, "SUPPLY"] call Waldo_fnc_CargoAttributesPrepareObject;
 * Result: An eligible portable object gains WMP's drag/carry choices and an ACE loading size
 * only when its class and existing object settings do not already supply one.
 */
params [["_object", objNull, [objNull]], ["_role", "CARGO", [""]]];
if (!isServer || {isNull _object} || {_object getVariable ["Waldo_Logistics_StarterCrate", false]}
    || {_object isKindOf "CAManBase"} || {_object isKindOf "StaticWeapon"}
    || {_object isKindOf "LandVehicle"} || {_object isKindOf "Air"}
    || {_object isKindOf "Ship"}) exitWith {false};

// ACE's per-object value includes a mission maker's explicit -1 (loading off).
// Only classes without a usable size receive a WMP default.
private _explicitSize = _object getVariable ["ace_cargo_size",
    _object getVariable ["Waldo_CargoAttributes_DesiredSize", -999]];
// SQF cannot keep nil in a local variable for later array construction. Use a
// sentinel, then pass a literal nil only when no size change is needed.
private _size = -999;
if (_explicitSize == -999) then {
    private _classSize = getNumber (configFile >> "CfgVehicles" >> typeOf _object >> "ace_cargo_size");
    if (_classSize <= 0) then {
        _size = switch (toUpperANSI _role) do {
            case "SUPPLY";
            case "REARM";
            case "FUELBARREL": {4};
            case "MEDICAL";
            case "EXPLOSIVES";
            case "SPARE": {2};
            default {1};
        };
    };
};
private _choice = _object getVariable ["Waldo_CargoAttributes_Choice", [true, true, false, false]];
private _args = if (_size == -999) then {[_object, nil, nil] + _choice}
    else {[_object, nil, _size] + _choice};
_args call Waldo_fnc_SetCargoAttributes
