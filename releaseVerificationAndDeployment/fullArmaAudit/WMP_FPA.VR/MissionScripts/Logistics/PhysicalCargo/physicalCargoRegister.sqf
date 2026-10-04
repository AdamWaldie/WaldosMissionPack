/*
 * Author: WaldoTheWarfighter
 * Let players ACE Drag or Carry a placed prop and attach it visibly to a vehicle. WMP crates
 * already qualify; use this call for another prop that players should be able to mount.
 * Enable Waldo_PhysicalCargo_Enable in MissionConfig/logisticsConfig.sqf first.
 *
 * Locality and authority: The server publishes ACE drag/carry through WMP's
 * cargo-attribute helper, then marks the object eligible for physical mounting.
 * An Eden Init also runs on clients, but their copies of this call do nothing.
 * Repeat and JIP: Repeating the call does not create another mount or ACE event.
 * ACE replays drag/carry actions to joining clients; the eligibility flag is public.
 *
 * Arguments:
 * 0: object <OBJECT> - an existing non-weapon prop or crate. Static weapons,
 * vehicles, aircraft and boats cannot be registered as carried cargo.
 * Return Value: <BOOL> - true when eligible or queued until settings are ready;
 * false when disabled, off-server or given an unsupported object.
 * Example: In that object's Eden Init field:
 * [this] call Waldo_fnc_PhysicalCargoRegister;
 * Result: ACE Drag and Carry can move the object; a normal carried release onto a nearby vehicle
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
if (_object getVariable ["Waldo_Logistics_StarterCrate", false]) exitWith {false};
// Static weapons can flip carriers during attach. Vehicles/aircraft/boats are carriers,
// not carryable props. Never publish ACE carryability for these selected ZEN targets.
if (_object isKindOf "CAManBase" || {_object isKindOf "StaticWeapon"} || {_object isKindOf "LandVehicle"}
    || {_object isKindOf "Air"} || {_object isKindOf "Ship"}) exitWith {
    _object setVariable ["Waldo_PhysicalCargo_Eligible", false, true];
    false
};
if !([_object] call Waldo_fnc_CargoAttributesPrepareObject) exitWith {false};
_object setVariable ["Waldo_PhysicalCargo_Eligible", true, true];
true
