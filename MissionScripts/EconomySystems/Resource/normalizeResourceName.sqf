/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - normalizeResourceName
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_normalizeResourceName via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_name", ""]];

    private _safeName = if (_name isEqualType "") then {_name} else {str _name};
    if (_safeName isEqualTo "") exitWith {""};
    _safeName
