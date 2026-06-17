/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - setPresetAssignment
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_setPresetAssignment via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_sideKey", ""],
        ["_complexityKey", ""],
        ["_catalogKey", ""]
    ];

    private _varName = [_sideKey] call Waldo_fnc_EcoCore_getPresetAssignmentVar;
    if (_varName isEqualTo "") exitWith {};

    missionNamespace setVariable [_varName, [_complexityKey, _catalogKey], true];
