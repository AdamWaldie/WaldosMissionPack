/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getPubZeusActionJipId
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getPubZeusActionJipId via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_object", objNull],
        ["_flagVar", ""]
    ];

    if (isNull _object) exitWith {""};
    if (_flagVar isEqualTo "") exitWith {""};

    private _jipVar = format ["%1_JIP", _flagVar];
    private _jipId = _object getVariable [_jipVar, ""];
    if (_jipId isEqualTo "") then {
        _jipId = format [
            "WaldoEco_PubZeusAction_%1_%2_%3",
            _flagVar,
            floor (diag_tickTime * 1000),
            floor (random 1000000)
        ];
        _object setVariable [_jipVar, _jipId, true];
    };

    _jipId
