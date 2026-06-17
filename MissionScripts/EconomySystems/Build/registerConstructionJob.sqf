/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - registerConstructionJob
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_registerConstructionJob via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [
            ["_jobId", ""],
            ["_buildName", ""],
            ["_sideKey", "NONE"]
        ];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_jobId isEqualTo "" || {_buildName isEqualTo ""}) exitWith {};

        private _rows = call Waldo_fnc_EcoBuild_getActiveConstructionJobs;
        if ((_rows findIf {(_x param [0, ""]) isEqualTo _jobId}) >= 0) exitWith {};
        _rows pushBack [_jobId, _buildName, _sideKey];
        [_rows] call Waldo_fnc_EcoBuild_setActiveConstructionJobs;

