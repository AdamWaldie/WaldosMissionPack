/*
 * Author: Waldo
 * Adds the player-facing ACE interaction on a jammer emitter so an EW team can deal with a jammer
 * in the field without Zeus: a "Toggle Radio Jammer" action (anyone) that switches it on/off, and
 * a "Disable Radio Jammer" action (engineers, if ACE) that destroys the emitter - which, with
 * destructible jammers on, auto-deregisters it. Broadcast to every client from Waldo_fnc_Jammer
 * when a jammer is created, and re-run for JIP. Silently does nothing without ACE interaction.
 *
 * Arguments:
 * 0: Object <OBJECT> - the jammer emitter to add the actions to
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [myJammer] call Waldo_fnc_JammerInteraction;
 */

params [["_object", objNull]];

if !(hasInterface) exitWith {};
if (isNull _object) exitWith {};
if !(isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {};
if (_object getVariable ["Waldo_Jamming_AceAdded", false]) exitWith {};
_object setVariable ["Waldo_Jamming_AceAdded", true];

// Toggle on/off - available to anyone who can reach the emitter.
private _toggle = [
    "Waldo_Jammer_Toggle",
    "Toggle Radio Jammer",
    "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa",
    {
        params ["_target", "_player"];
        [_target] call Waldo_fnc_JammerToggle;
    },
    {
        params ["_target"];
        (_target getVariable ["Waldo_Jamming_Id", -1]) >= 0
    }
] call ace_interact_menu_fnc_createAction;
[_object, 0, ["ACE_MainActions"], _toggle] call ace_interact_menu_fnc_addActionToObject;

// Disable/destroy - engineers only (if ACE common is present to test for it).
private _disable = [
    "Waldo_Jammer_Disable",
    "Disable Radio Jammer",
    "\a3\ui_f\data\igui\cfg\simpletasks\types\danger_ca.paa",
    {
        params ["_target", "_player"];
        // Destroying the emitter triggers its Killed handler, which deregisters the jammer.
        [_target, 1] remoteExec ["setDamage", _target];
        [_target] call Waldo_fnc_JammerRemove;
    },
    {
        params ["_target", "_player"];
        private _isEng = true;
        if (isClass (configFile >> "CfgPatches" >> "ace_common")) then {
            _isEng = [_player] call ace_common_fnc_isEngineer;
        };
        _isEng && {(_target getVariable ["Waldo_Jamming_Id", -1]) >= 0}
    }
] call ace_interact_menu_fnc_createAction;
[_object, 0, ["ACE_MainActions"], _disable] call ace_interact_menu_fnc_addActionToObject;
