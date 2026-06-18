/*
 * Author: Waldo
 * Clear pub zeus object action.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _object <OBJECT> - object (optional, default: objNull)
 * 1: _flagVar <STRING> - flag var (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_object, _flagVar] call Waldo_fnc_EcoCore_clearPubZeusObjectAction;
 */

    params [
        ["_object", objNull],
        ["_flagVar", ""]
    ];

    if (isNull _object) exitWith {};
    if (_flagVar isEqualTo "") exitWith {};

    private _jipVar = format ["%1_JIP", _flagVar];
    private _jipId = _object getVariable [_jipVar, ""];
    if !(_jipId isEqualTo "") then {
        remoteExec ["", _jipId];
        _object setVariable [_jipVar, nil, true];
    };

    _object setVariable [format ["%1_Published", _flagVar], nil, true];
