/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - collectResourceConfigFormData
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_collectResourceConfigFormData via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_disp"];

    if (isNull _disp) exitWith {[]};

    private _nameCtrl = _disp getVariable ["WaldoEcoResource_ConfigNameEdit", controlNull];
    private _colorCtrl = _disp getVariable ["WaldoEcoResource_ConfigColorEdit", controlNull];
    private _baseStorageCtrl = _disp getVariable ["WaldoEcoResource_ConfigBaseStorageEdit", controlNull];
    if (isNull _nameCtrl || isNull _colorCtrl || isNull _baseStorageCtrl) exitWith {[]};

    private _name = [ctrlText _nameCtrl] call Waldo_fnc_EcoResource_normalizeResourceName;
    if (_name isEqualTo "") exitWith {[]};

    private _color = [ctrlText _colorCtrl] call Waldo_fnc_EcoResource_normalizeResourceColor;
    private _baseStorage = [ctrlText _baseStorageCtrl] call Waldo_fnc_EcoResource_normalizeResourceBaseStorage;

    private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
    private _iconIndex = _disp getVariable ["WaldoEcoResource_ConfigIconIndex", 0];
    if (_iconIndex < 0) then {_iconIndex = 0;};
    if (_iconIndex >= count _choices) then {_iconIndex = 0;};
    private _icon = (_choices select _iconIndex) param [1, ""];

    [_name, _color, _icon, _baseStorage]
