/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - removeTreeSelectionHandlerByVar
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_removeTreeSelectionHandlerByVar via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
