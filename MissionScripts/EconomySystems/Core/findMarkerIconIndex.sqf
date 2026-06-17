/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - findMarkerIconIndex
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_findMarkerIconIndex via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_icon", ""]];

    private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
    private _index = _choices findIf {((_x param [1, ""]) isEqualTo _icon)};
    if (_index < 0) then {_index = 0;};
    _index
