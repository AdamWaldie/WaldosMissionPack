/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - refreshResourceSettings
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_refreshResourceSettings via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_disp"];

    if (isNull _disp) exitWith {};

    private _types = call Waldo_fnc_EcoResource_getResourceTypes;
    private _count = count _types;
    if (_count <= 0) exitWith {};

    private _typeIndex = _disp getVariable ["WaldoEcoResource_SettingsTypeIndex", 0];
    if (_typeIndex < 0) then {_typeIndex = _count - 1;};
    if (_typeIndex >= _count) then {_typeIndex = 0;};
    _disp setVariable ["WaldoEcoResource_SettingsTypeIndex", _typeIndex];

    private _typeName = _types select _typeIndex;
    private _typeCtrl = _disp getVariable ["WaldoEcoResource_SettingsTypeValue", controlNull];
    if (!isNull _typeCtrl) then {
        _typeCtrl ctrlSetStructuredText parseText ([_typeName, false] call Waldo_fnc_EcoResource_getResourceStructuredLabel);
        _typeCtrl ctrlCommit 0;
    };

    private _sideKey = _disp getVariable ["WaldoEcoResource_SettingsSelectedSide", "WEST"];
    private _amount = [_sideKey, _typeName] call Waldo_fnc_EcoResource_getSideResourceAmount;
    private _capacity = [_sideKey, _typeName] call Waldo_fnc_EcoResource_getSideResourceStorageCapacity;
    private _currentCtrl = _disp getVariable ["WaldoEcoResource_SettingsCurrentValue", controlNull];
    if (!isNull _currentCtrl) then {
        private _text = if (_capacity >= 0) then {
            format ["Current: %1 / %2", _amount, _capacity]
        } else {
            format ["Current: %1", _amount]
        };
        _currentCtrl ctrlSetText _text;
        _currentCtrl ctrlCommit 0;
    };
    private _edit = _disp getVariable ["WaldoEcoResource_SettingsAmountEdit", controlNull];
    if (!isNull _edit) then {
        _edit ctrlSetText str _amount;
        _edit ctrlCommit 0;
    };
