/*
 * Author: WaldoTheWarfighter (Waldos Economy Systems)
 * Designates an existing, editor-placed object as a Research Center, so a mission maker
 * can build the economy in Eden instead of spawning everything live in Zeus.
 *
 * Place a "Land_Research_HQ_F" object in Eden and put this in its init field:
 *     [this] call Waldo_fnc_EcoResearch_registerCenter;
 *
 * The economy suite must be enabled in MissionConfig (or by an Economy composition).
 * JIP-safe: the tag is broadcast and the per-machine action loop maintains the interaction
 * for joining/rejoining players. Must be a Land_Research_HQ_F (the class the loop tracks).
 *
 * Arguments:
 * 0: _object - OBJECT - the placed research-center object (this)
 *
 * Return Value:
 * Nothing
 * Locality/Authority: Object init may run on each machine. Economy authority broadcasts the
 * centre tag; interface clients install their own actions.
 * Repeat/JIP Behaviour: Runtime registration and local action installation are repeat-safe;
 * the public centre tag lets joining clients discover the object.
 * Current Callers: Eden object init fields and Economy composition setup.
 * Example: [this] call Waldo_fnc_EcoResearch_registerCenter;
 * Result: The placed Land_Research_HQ_F becomes a usable Research Center.
 */

params ["_object"];
if (isNull _object) exitWith {};

if ([] call Waldo_fnc_EcoCore_canRunAuthority) then {
    _object setVariable ["WaldoEcoResearch_IsResearchCenter", true, true];
    [_object, "RESEARCH_CENTERS"] call Waldo_fnc_EcoCore_registerRuntimeObject;
    [_object, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;
};

if (hasInterface) then {
    [_object] call Waldo_fnc_EcoResearch_ensureResearchCenterActionsLocal;
};
