/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getResourceMarkerClass
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getResourceMarkerClass via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_resourceType"];

    private _def = [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
    private _icon = if ((count _def) > 2) then {_def param [2, ""]} else {""};
    [_icon] call Waldo_fnc_EcoResource_getMarkerClassForIconPath
