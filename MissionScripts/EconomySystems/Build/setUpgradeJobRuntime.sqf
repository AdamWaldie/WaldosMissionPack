/*
 * Author: Waldo
 * Set upgrade job runtime.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoBuild_setUpgradeJobRuntime;
 */

        params [["_rows", []]];
        missionNamespace setVariable ["WaldoEcoBuild_UpgradeJobRuntime", _rows];

