/*
 * Author: WaldoTheWarfighter
 * Purpose: Makes a non-weapon object eligible for physical ACE carry mounting.
 * Locality / Authority: Server registration; ACE publishes carryability globally.
 * Repeat / JIP: Idempotent object flag; no placement state is created until a player mounts it.
 * Arguments: object <OBJECT>. Return Value: <BOOL> eligible.
 * Current callers: mission-maker initServer/object init; WMP quartermaster may register issued gear.
 * Example: [this] call Waldo_fnc_PhysicalCargoRegister;
 */
params [["_object", objNull, [objNull]]];
if (!isServer || {isRemoteExecuted} || {isNull _object}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]) exitWith {
    [_object] spawn {
        params ["_object"];
        waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false] || {isNull _object}};
        if (!isNull _object) then {[_object] call Waldo_fnc_PhysicalCargoRegister};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_PhysicalCargo_Enable", false]) exitWith {false};
// Static weapons can flip carriers during attach. Vehicles/aircraft/boats are carriers,
// not carryable props. Never publish ACE carryability for these selected ZEN targets.
if (_object isKindOf "StaticWeapon" || {_object isKindOf "LandVehicle"}
    || {_object isKindOf "Air"} || {_object isKindOf "Ship"}) exitWith {
    _object setVariable ["Waldo_PhysicalCargo_Eligible", false, true];
    false
};
_object setVariable ["Waldo_PhysicalCargo_Eligible", true, true];
if (!(_object getVariable ["Waldo_CargoAttributes_CarryablePublished", false])
    && {!isNil "ace_dragging_fnc_setCarryable"}) then {
    [_object, true, _object getVariable ["ace_dragging_carryPosition", [0, 1, 1]],
        _object getVariable ["ace_dragging_carryDirection", 0], false, true]
        call ace_dragging_fnc_setCarryable;
    _object setVariable ["Waldo_CargoAttributes_CarryablePublished", true];
};
true
