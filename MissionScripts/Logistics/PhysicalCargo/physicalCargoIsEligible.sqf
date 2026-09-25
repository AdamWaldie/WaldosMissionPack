/*
 * Author: WaldoTheWarfighter
 * Purpose: Single eligibility rule for physical cargo, shared by the carry hook, the server mount
 *   check and the ZEN Physical Cargo - Eligibility module so they can never disagree.
 * Locality / Authority: Read-only; safe on any machine. The flag it reads is public.
 * Repeat / JIP: Pure function with no side effects.
 *
 * Any carryable prop is eligible by default: crates, ACE spare wheels and tracks, fuel barrels,
 * jerrycans and mission props. People, static weapons, vehicles, aircraft and boats never are.
 * An explicit Waldo_PhysicalCargo_Eligible = false (ZEN "Disallow physical mounting") opts an
 * object out and leaves it on native ACE Carry and Cargo.
 *
 * Arguments:
 * 0: object <OBJECT>
 *
 * Return Value: <BOOL> - true when a carried release onto a vehicle should mount it physically.
 * Current callers: Waldo_fnc_PhysicalCargoInitLocal, Waldo_fnc_PhysicalCargoAttachServer,
 *   Waldo_fnc_ZenServiceLogisticsModule and Waldo_fnc_ZenServiceLogisticsServer.
 * Example: [cursorObject] call Waldo_fnc_PhysicalCargoIsEligible;
 */
params [["_object", objNull, [objNull]]];
if (isNull _object) exitWith {false};
if (_object isKindOf "CAManBase" || {_object isKindOf "StaticWeapon"} || {_object isKindOf "LandVehicle"}
    || {_object isKindOf "Air"} || {_object isKindOf "Ship"}) exitWith {false};
_object getVariable ["Waldo_PhysicalCargo_Eligible", true]
