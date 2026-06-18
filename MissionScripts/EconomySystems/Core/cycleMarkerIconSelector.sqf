/*
 * Author: Waldo
 * Cycle marker icon selector.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 * 1: _delta <SCALAR> - delta (optional, default: 0)
 * 2: _indexVarName <STRING> - index var name (optional, default: "")
 * 3: _valueCtrlVarName <STRING> - value ctrl var name (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta, _indexVarName, _valueCtrlVarName] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;
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
