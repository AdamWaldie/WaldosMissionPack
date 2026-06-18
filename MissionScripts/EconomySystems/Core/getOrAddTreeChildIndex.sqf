/*
 * Author: Waldo
 * Get or add tree child index.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _tree <ANY> - tree (optional, default: controlNull)
 * 1: _rootIndex <SCALAR> - root index (optional, default: -1)
 * 2: _matchTexts <ARRAY> - match texts (optional, default: [])
 * 3: _addText <STRING> - add text (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_tree, _rootIndex, _matchTexts, _addText] call Waldo_fnc_EcoCore_getOrAddTreeChildIndex;
 */

    params [
        ["_tree", controlNull],
        ["_rootIndex", -1],
        ["_matchTexts", []],
        ["_addText", ""]
    ];
    if (isNull _tree) exitWith {-1};
    if (_rootIndex < 0) exitWith {-1};

    private _safeTexts = _matchTexts;
    if !(_safeTexts isEqualType []) then {
        _safeTexts = [_safeTexts];
    };
    if (_addText isEqualTo "" && {(count _safeTexts) > 0}) then {
        _addText = _safeTexts select 0;
    };
    if (_addText isEqualTo "") exitWith {-1};

    private _childIndex = [_tree, _rootIndex, _safeTexts] call Waldo_fnc_EcoCore_findTreeChildIndex;
    if (_childIndex < 0) then {
        _childIndex = _tree tvAdd [[_rootIndex], _addText];
    };

    _childIndex
