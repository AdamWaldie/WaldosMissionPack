/*
 * Author: Waldo
 * Get or add tree root index.
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
 * [_tree, _rootText] call Waldo_fnc_EcoCore_getOrAddTreeRootIndex;
 */

    params [["_tree", controlNull], ["_rootText", ""]];
    if (isNull _tree) exitWith {-1};
    if (_rootText isEqualTo "") exitWith {-1};

    private _rootIndex = [_tree, _rootText] call Waldo_fnc_EcoCore_findTreeRootIndex;
    if (_rootIndex < 0) then {
        _rootIndex = _tree tvAdd [[], _rootText];
    };

    _rootIndex
