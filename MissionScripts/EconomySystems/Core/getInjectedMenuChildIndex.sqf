/*
 * Author: Waldo
 * Get injected menu child index.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _childId <STRING> - child id (optional, default: "")
 * 1: _childIndexes <ARRAY> - child indexes (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_childId, _childIndexes] call Waldo_fnc_EcoCore_getInjectedMenuChildIndex;
 */

    params [
        ["_childId", ""],
        ["_childIndexes", []]
    ];

    if (_childId isEqualTo "") exitWith {-1};
    if !(_childIndexes isEqualType []) exitWith {-1};

    private _pairIndex = _childIndexes findIf {((_x param [0, ""]) isEqualTo _childId)};
    if (_pairIndex < 0) exitWith {-1};

    (_childIndexes select _pairIndex) param [1, -1]
