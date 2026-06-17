/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - unregisterConstructionJob
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_unregisterConstructionJob via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_jobId", ""]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_jobId isEqualTo "") exitWith {};

        private _rows = call Waldo_fnc_EcoBuild_getActiveConstructionJobs;
        _rows = _rows select {(_x param [0, ""]) isNotEqualTo _jobId};
        [_rows] call Waldo_fnc_EcoBuild_setActiveConstructionJobs;

