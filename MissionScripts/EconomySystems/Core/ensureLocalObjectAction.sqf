/*
 * Author: Waldo
 * Ensure local object action.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _object <OBJECT> - object (optional, default: objNull)
 * 1: _flagVar <STRING> - flag var (optional, default: "")
 * 2: _actionArgs <ARRAY> - action args (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_object, _flagVar, _actionArgs] call Waldo_fnc_EcoCore_ensureLocalObjectAction;
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
