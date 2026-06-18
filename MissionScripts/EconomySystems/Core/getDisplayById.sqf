/*
 * Author: Waldo
 * Get display by id.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _idd <SCALAR> - idd (optional, default: -1)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_idd] call Waldo_fnc_EcoCore_getDisplayById;
 */

    params [["_idd", -1]];
    if (_idd < 0) exitWith {displayNull};
    findDisplay _idd
