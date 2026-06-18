/*
 * Author: Waldo
 * Cycle resource settings type.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 * 1: _delta <SCALAR> - delta (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoResource_cycleResourceSettingsType;
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
