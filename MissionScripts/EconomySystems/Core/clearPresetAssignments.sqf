/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - clearPresetAssignments
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_clearPresetAssignments via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    {
        private _varName = [_x] call Waldo_fnc_EcoCore_getPresetAssignmentVar;
        if (_varName isEqualTo "") then {continue;};
        missionNamespace setVariable [_varName, [], true];
    } forEach ["WEST", "EAST", "GUER"];

    missionNamespace setVariable ["WaldoEcoCore_PresetGenericComplexity", "", true];
