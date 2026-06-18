/*
 * Author: Waldo
 * Remove tree selection handler by var.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _tree <ANY> - tree (optional, default: controlNull)
 * 1: _handlerVarName <STRING> - handler var name (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_tree, _handlerVarName] call Waldo_fnc_EcoCore_removeTreeSelectionHandlerByVar;
 */

    params [
        ["_tree", controlNull],
        ["_handlerVarName", ""]
    ];

    if (isNull _tree) exitWith {};
    if (_handlerVarName isEqualTo "") exitWith {};

    private _handlerId = _tree getVariable [_handlerVarName, -1];
    if (_handlerId >= 0) then {
        _tree ctrlRemoveEventHandler ["TreeSelChanged", _handlerId];
        _tree setVariable [_handlerVarName, nil];
    };
