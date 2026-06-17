/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getInjectedMenuChildIndex
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getInjectedMenuChildIndex via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
