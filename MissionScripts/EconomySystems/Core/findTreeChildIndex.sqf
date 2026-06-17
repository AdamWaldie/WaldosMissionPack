/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - findTreeChildIndex
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_findTreeChildIndex via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
