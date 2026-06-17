/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getOrAddTreeRootIndex
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getOrAddTreeRootIndex via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_tree", controlNull], ["_rootText", ""]];
    if (isNull _tree) exitWith {-1};
    if (_rootText isEqualTo "") exitWith {-1};

    private _rootIndex = [_tree, _rootText] call Waldo_fnc_EcoCore_findTreeRootIndex;
    if (_rootIndex < 0) then {
        _rootIndex = _tree tvAdd [[], _rootText];
    };

    _rootIndex
