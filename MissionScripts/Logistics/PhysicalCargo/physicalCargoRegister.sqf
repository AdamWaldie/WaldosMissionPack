/*
 * Author: WaldoTheWarfighter
 * Let players ACE Carry a placed prop and attach it visibly to a vehicle. WMP crates
 * already qualify; use this call for another prop that players should be able to mount.
 * Enable Waldo_PhysicalCargo_Enable in MissionConfig/logisticsConfig.sqf first.
 *
 * Locality and authority: The server marks the object and publishes ACE carryability.
 * An Eden Init also runs on clients, but their copies of this call do nothing.
 * Repeat and JIP: Repeating the call does not create another mount. The eligibility
 * flag is public, so joining clients receive it.
 *
 * Arguments:
 * 0: object <OBJECT> - an existing non-weapon prop or crate. Static weapons,
 * vehicles, aircraft and boats cannot be registered as carried cargo.
 * Return Value: <BOOL> - true when eligible or queued until settings are ready;
 * false when disabled, off-server or given an unsupported object.
 * Example: In that object's Eden Init field:
 * [this] call Waldo_fnc_PhysicalCargoRegister;
 * Result: ACE Carry can pick up the object; a normal release onto a nearby vehicle
 * attempts a visible mount. ACE Cargo remains available through its menu.
 * Current callers: Eden object Init, WMP quartermaster and ZEN eligibility module.
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
