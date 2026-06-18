/*
 * Author: Waldo (Waldos Economy Systems)
 * Designates an existing, editor-placed object as a Research Center, so a mission maker
 * can build the economy in Eden instead of spawning everything live in Zeus.
 *
 * Place a "Land_Research_HQ_F" object in Eden and put this in its init field:
 *     [this] call Waldo_fnc_EcoResearch_registerCenter;
 *
 * The economy suite must be enabled (see init.sqf / a Waldos Economy Systems composition).
 * JIP-safe: the tag is broadcast and the per-machine action loop maintains the interaction
 * for joining/rejoining players. Must be a Land_Research_HQ_F (the class the loop tracks).
 *
 * Arguments:
 * 0: _object - OBJECT - the placed research-center object (this)
 *
 * Return Value:
 * Nothing
 */

params ["_object"];
if (isNull _object) exitWith {};

if ([] call Waldo_fnc_EcoCore_canRunAuthority) then {
    _object setVariable ["WaldoEcoResearch_IsResearchCenter", true, true];
    [_object, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;
};

if (hasInterface) then {
    [_object] call Waldo_fnc_EcoResearch_ensureResearchCenterActionsLocal;
};
