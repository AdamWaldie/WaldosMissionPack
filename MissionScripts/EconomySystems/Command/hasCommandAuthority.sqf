/*
 * Author: Waldo
 * Has command authority.
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
 * [_unit] call Waldo_fnc_EcoCommand_hasCommandAuthority;
 */

    params [["_unit", objNull]];

    if !((call Waldo_fnc_EcoCommand_hasAnyGroundCommand)) exitWith {true};
    if (isNull _unit) exitWith {false};
    [_unit] call Waldo_fnc_EcoCommand_isGroundCommandUnit
