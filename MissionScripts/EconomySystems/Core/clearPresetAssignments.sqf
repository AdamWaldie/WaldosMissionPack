/*
 * Author: Waldo
 * Clear preset assignments.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_clearPresetAssignments;
 */

    {
        private _varName = [_x] call Waldo_fnc_EcoCore_getPresetAssignmentVar;
        if (_varName isEqualTo "") then {continue;};
        missionNamespace setVariable [_varName, [], true];
    } forEach ["WEST", "EAST", "GUER"];

    missionNamespace setVariable ["WaldoEcoCore_PresetGenericComplexity", "", true];
