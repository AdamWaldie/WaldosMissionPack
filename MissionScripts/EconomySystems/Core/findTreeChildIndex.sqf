/*
 * Author: Waldo
 * Find tree child index.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _tree <ANY> - tree (optional, default: controlNull)
 * 1: _rootIndex <SCALAR> - root index (optional, default: -1)
 * 2: _matchTexts <ARRAY> - match texts (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_tree, _rootIndex, _matchTexts] call Waldo_fnc_EcoCore_findTreeChildIndex;
 */

    params [["_tree", controlNull], ["_rootIndex", -1], ["_matchTexts", []]];
    if (isNull _tree) exitWith {-1};
    if (_rootIndex < 0) exitWith {-1};

    private _safeTexts = _matchTexts;
    if !(_safeTexts isEqualType []) then {
        _safeTexts = [_safeTexts];
    };
    if ((count _safeTexts) <= 0) exitWith {-1};

    private _childIndex = -1;
    for "_j" from 0 to ((_tree tvCount [_rootIndex]) - 1) do {
        private _text = _tree tvText [_rootIndex, _j];
        if (_text in _safeTexts) exitWith {
            _childIndex = _j;
        };
    };

    _childIndex
