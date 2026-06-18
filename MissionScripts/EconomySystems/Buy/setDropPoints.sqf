/*
 * Author: Waldo
 * Set drop points.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoBuy_setDropPoints;
 */

        params [["_rows", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuy_DropPoints", _rows, true];

