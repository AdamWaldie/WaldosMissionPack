/*
 * Author: Waldo
 * Refresh marker icon selector.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 * 1: _indexVarName <STRING> - index var name (optional, default: "")
 * 2: _valueCtrlVarName <STRING> - value ctrl var name (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _indexVarName, _valueCtrlVarName] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;
 */

    params [
        ["_disp", displayNull],
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
    if (_index < 0) then {_index = _count - 1;};
    if (_index >= _count) then {_index = 0;};
    _disp setVariable [_indexVarName, _index];

    private _choice = _choices select _index;
    private _valueCtrl = _disp getVariable [_valueCtrlVarName, controlNull];
    if (!isNull _valueCtrl) then {
        _valueCtrl ctrlSetStructuredText parseText format [
            "<img image='%1' size='1'/> %2",
            _choice param [1, ""],
            _choice param [0, ""]
        ];
        _valueCtrl ctrlCommit 0;
    };
