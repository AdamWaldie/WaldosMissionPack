/*
 * Author: Waldo
 * Ensure zeus header root.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _tree <ANY> - tree (optional, default: controlNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_tree] call Waldo_fnc_EcoCore_ensureZeusHeaderRoot;
 */

    params [["_tree", controlNull]];

    if (isNull _tree) exitWith {-1};

    private _headerIndex = [_tree, WaldoEcoCore_ZeusHeaderRootText] call Waldo_fnc_EcoCore_getOrAddTreeRootIndex;
    _tree tvSetTooltip [[_headerIndex], WaldoEcoCore_ZeusHeaderRootTooltip];
    _tree tvSetColor [[_headerIndex], WaldoEcoCore_ZeusHeaderRootColor];

    _headerIndex
