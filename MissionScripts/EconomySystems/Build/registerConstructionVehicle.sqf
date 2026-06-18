/*
 * Author: Waldo (Waldos Economy Systems)
 * Designates an existing, editor-placed vehicle as a Construction Vehicle (Build system), so a
 * mission maker can set up the economy in Eden instead of spawning everything live in Zeus.
 *
 * Place any vehicle in Eden and put this in its init field:
 *     [this] call Waldo_fnc_EcoBuild_registerConstructionVehicle;
 *
 * The economy suite must be enabled (see init.sqf / a Waldos Economy Systems composition).
 * JIP-safe: the tag is broadcast and the per-machine action loop maintains the interaction
 * for joining/rejoining players. Works for any vehicle class (the loop tracks by tag).
 *
 * Arguments:
 * 0: _object - OBJECT - the placed construction vehicle (this)
 *
 * Return Value:
 * Nothing
 */

params ["_object"];
if (isNull _object) exitWith {};

if ([] call Waldo_fnc_EcoCore_canRunAuthority) then {
    _object setVariable ["WaldoEcoBuild_IsConstructionVehicle", true, true];
    [_object, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;
};

if (hasInterface) then {
    [_object] call Waldo_fnc_EcoBuild_ensureConstructionVehicleActionLocal;
};
