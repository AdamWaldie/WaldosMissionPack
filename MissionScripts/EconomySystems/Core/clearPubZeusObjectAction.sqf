/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - clearPubZeusObjectAction
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_clearPubZeusObjectAction via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
