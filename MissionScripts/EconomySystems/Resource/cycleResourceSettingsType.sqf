/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - cycleResourceSettingsType
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_cycleResourceSettingsType via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_disp", ["_delta", 0]];

    if (isNull _disp) exitWith {};

    private _types = call Waldo_fnc_EcoResource_getResourceTypes;
    private _count = count _types;
    if (_count <= 0) exitWith {};

    private _index = _disp getVariable ["WaldoEcoResource_SettingsTypeIndex", 0];
    _index = _index + _delta;

    if (_index < 0) then {
        _index = _count - 1;
    };
    if (_index >= _count) then {
        _index = 0;
    };

    _disp setVariable ["WaldoEcoResource_SettingsTypeIndex", _index];
    [_disp] call Waldo_fnc_EcoResource_refreshResourceSettings;
