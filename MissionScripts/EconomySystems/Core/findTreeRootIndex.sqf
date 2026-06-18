/*
 * Author: Waldo
 * Find tree root index.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _tree <ANY> - tree (optional, default: controlNull)
 * 1: _rootText <STRING> - root text (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_tree, _rootText] call Waldo_fnc_EcoCore_findTreeRootIndex;
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
