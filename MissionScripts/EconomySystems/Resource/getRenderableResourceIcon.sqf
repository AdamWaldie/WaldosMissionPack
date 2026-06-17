/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getRenderableResourceIcon
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getRenderableResourceIcon via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_icon", ""]];

    private _markerClass = [_icon] call Waldo_fnc_EcoResource_getMarkerClassForIconPath;
    if (_markerClass isEqualTo (call Waldo_fnc_EcoResource_getFallbackResourceMarkerClass)) exitWith {
        call Waldo_fnc_EcoResource_getFallbackResourceIcon
    };

    _icon
