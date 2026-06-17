/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getOrAddTreeChildIndex
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getOrAddTreeChildIndex via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
