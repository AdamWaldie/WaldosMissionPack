/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - ensureLocalObjectAction
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_ensureLocalObjectAction via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_object", objNull],
        ["_flagVar", ""],
        ["_actionArgs", []]
    ];

    if (!hasInterface) exitWith {-1};
    if (isNull _object) exitWith {-1};
    if (_flagVar isEqualTo "") exitWith {-1};
    if !(_actionArgs isEqualType []) exitWith {-1};
    if (_object getVariable [_flagVar, false]) exitWith {
        _object getVariable [format ["%1_Id", _flagVar], -1]
    };

    private _actionId = _object addAction _actionArgs;
    _object setVariable [_flagVar, true];
    _object setVariable [format ["%1_Id", _flagVar], _actionId];
    _actionId
