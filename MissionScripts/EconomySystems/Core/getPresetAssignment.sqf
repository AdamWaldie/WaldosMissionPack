/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getPresetAssignment
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getPresetAssignment via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_sideKey", ""]];

    private _varName = [_sideKey] call Waldo_fnc_EcoCore_getPresetAssignmentVar;
    if (_varName isEqualTo "") exitWith {[]};
    +(missionNamespace getVariable [_varName, []])
