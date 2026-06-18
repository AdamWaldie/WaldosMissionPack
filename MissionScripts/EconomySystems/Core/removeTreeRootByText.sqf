/*
 * Author: Waldo
 * Remove tree root by text.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _tree <ANY> - tree (optional, default: controlNull)
 * 1: _rootText <STRING> - root text (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_tree, _rootText] call Waldo_fnc_EcoCore_removeTreeRootByText;
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
