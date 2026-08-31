/*
 * Author: WaldoTheWarfighter
 * Clears one published Economy object-action replay and permits a later repeat-safe publication.
 * Locality/authority: server-owned JIP cleanup; object-local action removal is handled by Economy's
 * existing client cleanup/reconciliation path.
 * Repeat/JIP behaviour: repeat-safe. The named id is also detached from deletion cleanup.
 *
 * Arguments:
 * 0: _object <OBJECT> - object (optional, default: objNull)
 * 1: _flagVar <STRING> - flag var (optional, default: "")
 *
 * Return Value: Nothing.
 *
 * Example:
 * [_object, _flagVar] call Waldo_fnc_EcoCore_clearZeusObjectAction;
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
        [_object, _jipId] call Waldo_fnc_JipRemoveBoundServer;
        _object setVariable [_jipVar, nil, true];
    };

    _object setVariable [format ["%1_Published", _flagVar], nil, true];
