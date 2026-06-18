/*
 * Author: Waldo
 * Is ground command unit.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _unit <OBJECT> - unit (optional, default: objNull)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_unit] call Waldo_fnc_EcoCommand_isGroundCommandUnit;
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {false};

    private _unitKey = [_unit] call Waldo_fnc_EcoCommand_getGroundCommandKey;
    if (_unitKey isEqualTo "") exitWith {false};

    ((call Waldo_fnc_EcoCommand_getGroundCommandUIDs) find _unitKey) >= 0
