/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getMarkerIconChoices
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getMarkerIconChoices via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    private _cached = missionNamespace getVariable ["WaldoEcoResource_MarkerIconChoices", []];
    if ((count _cached) > 0) exitWith {+_cached};

    private _choices = [];

    {
        private _cfg = _x;
        private _icon = getText (_cfg >> "icon");
        if (_icon isNotEqualTo "") then {
            _choices pushBack [configName _cfg, _icon];
        };
    } forEach ("true" configClasses (configFile >> "CfgMarkers"));

    if ((count _choices) isEqualTo 0) then {
        _choices pushBack ["mil_dot", "\A3\ui_f\data\map\markers\military\dot_CA.paa"];
    };

    missionNamespace setVariable ["WaldoEcoResource_MarkerIconChoices", _choices];
    +_choices
