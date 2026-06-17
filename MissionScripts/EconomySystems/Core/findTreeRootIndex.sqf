/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - findTreeRootIndex
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_findTreeRootIndex via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_tree", controlNull], ["_rootText", ""]];
    if (isNull _tree) exitWith {-1};
    if (_rootText isEqualTo "") exitWith {-1};

    private _rootIndex = -1;
    for "_i" from 0 to ((_tree tvCount []) - 1) do {
        if ((_tree tvText [_i]) isEqualTo _rootText) exitWith {
            _rootIndex = _i;
        };
    };

    _rootIndex
