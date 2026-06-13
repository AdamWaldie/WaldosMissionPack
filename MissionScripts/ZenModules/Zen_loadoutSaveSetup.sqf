/*
 * Author: Waldo
 * Adds the "Save Respawn Loadout" addAction to the given object on the local machine.
 * Called via remoteExec (including JIP) from Waldo_fnc_ZenLoadoutSaveModule.
 *
 * Arguments:
 * 0: target <OBJECT> - Object to receive the action
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [someBox] call Waldo_fnc_ZenAddLoadoutSaveAction;
 */

params ["_target"];

if (isNull _target) exitWith {};
if !(hasInterface) exitWith {};

// Prevent duplicate actions if the module is placed on the same object more than once.
// This variable is intentionally local — each machine tracks its own state.
if (_target getVariable ["Waldo_LoadoutSaveActionAdded", false]) exitWith {};
_target setVariable ["Waldo_LoadoutSaveActionAdded", true];

_target addAction [
    "<t color='#00FF00'>Save Respawn Loadout</t>",
    Waldo_fnc_SaveLoadout,
    nil,
    1.5,
    true,
    true,
    "",
    "true"
];
