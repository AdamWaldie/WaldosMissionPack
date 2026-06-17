/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - removeTreeRootByText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_removeTreeRootByText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_tree", controlNull],
        ["_rootText", ""]
    ];

    if (isNull _tree) exitWith {false};
    if (_rootText isEqualTo "") exitWith {false};

    private _rootIndex = [_tree, _rootText] call Waldo_fnc_EcoCore_findTreeRootIndex;
    if (_rootIndex < 0) exitWith {false};

    _tree tvDelete [_rootIndex];
    true
