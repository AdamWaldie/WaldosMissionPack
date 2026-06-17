/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - cycleMarkerIconSelector
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_cycleMarkerIconSelector via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_disp", displayNull],
        ["_delta", 0],
        ["_indexVarName", ""],
        ["_valueCtrlVarName", ""]
    ];

    if (isNull _disp) exitWith {};
    if (_indexVarName isEqualTo "") exitWith {};
    if (_valueCtrlVarName isEqualTo "") exitWith {};

    private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
    private _count = count _choices;
    if (_count <= 0) exitWith {};

    private _index = _disp getVariable [_indexVarName, 0];
    _index = _index + _delta;
    if (_index < 0) then {_index = _count - 1;};
    if (_index >= _count) then {_index = 0;};

    _disp setVariable [_indexVarName, _index];
    [_disp, _indexVarName, _valueCtrlVarName] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;
