/*
 * Author: Waldo
 * Inject zeus menu.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _tree <ANY> - tree (optional, default: controlNull)
 * 1: _spec <ARRAY> - spec (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_tree, _spec] call Waldo_fnc_EcoCore_injectZeusMenu;
 */

    params [
        ["_tree", controlNull],
        ["_spec", []]
    ];

    if (isNull _tree) exitWith {[-1, []]};
    if !(_spec isEqualType []) exitWith {[-1, []]};

    private _rootText = _spec param [0, ""];
    private _rootTooltip = _spec param [1, ""];
    private _defaultChildData = _spec param [2, ""];
    private _childSpecs = _spec param [3, []];

    if (_rootText isEqualTo "") exitWith {[-1, []]};

    private _rootIndex = [_tree, _rootText] call Waldo_fnc_EcoCore_getOrAddTreeRootIndex;
    if !(_rootTooltip isEqualTo "") then {
        _tree tvSetTooltip [[_rootIndex], _rootTooltip];
    };

    private _childIndexes = [];

    {
        private _childId = _x param [0, ""];
        private _childText = _x param [1, ""];
        private _childTooltip = _x param [2, ""];
        private _childData = _x param [3, _defaultChildData];

        if (_childId isEqualTo "") then {continue;};
        if (_childText isEqualTo "") then {continue;};

        private _childIndex = [_tree, _rootIndex, _childText] call Waldo_fnc_EcoCore_getOrAddTreeChildIndex;
        _tree tvSetText [[_rootIndex, _childIndex], _childText];

        if !(_childData isEqualTo "") then {
            _tree tvSetData [[_rootIndex, _childIndex], _childData];
        };

        if !(_childTooltip isEqualTo "") then {
            _tree tvSetTooltip [[_rootIndex, _childIndex], _childTooltip];
        };

        _childIndexes pushBack [_childId, _childIndex];
    } forEach _childSpecs;

    [_rootIndex, _childIndexes]
