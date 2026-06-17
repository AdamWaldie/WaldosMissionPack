/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getMarkerClassForIconPath
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getMarkerClassForIconPath via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_icon", ""]];

    private _fallbackClass = call Waldo_fnc_EcoResource_getFallbackResourceMarkerClass;
    if (_icon isEqualTo "") exitWith {_fallbackClass};

    private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
    private _index = _choices findIf {
        ((_x param [1, ""]) isEqualTo _icon)
    };

    if (_index < 0) exitWith {_fallbackClass};

    private _markerClass = (_choices select _index) param [0, _fallbackClass];
    if ((toLower _markerClass) isEqualTo "empty") exitWith {_fallbackClass};
    _markerClass
