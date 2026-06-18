/*
 * Author: Waldo
 * Set active construction jobs.
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
 * [_rows] call Waldo_fnc_EcoBuild_setActiveConstructionJobs;
 */

        params [["_rows", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_ActiveConstructionJobs", _rows, true];

