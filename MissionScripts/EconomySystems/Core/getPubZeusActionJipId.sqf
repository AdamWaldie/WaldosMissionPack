/*
 * Author: Waldo
 * Get pub zeus action jip id.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _object <OBJECT> - object (optional, default: objNull)
 * 1: _flagVar <STRING> - flag var (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_object, _flagVar] call Waldo_fnc_EcoCore_getPubZeusActionJipId;
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
