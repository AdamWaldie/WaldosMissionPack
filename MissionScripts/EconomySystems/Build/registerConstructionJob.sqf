/*
 * Author: Waldo
 * Register construction job.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _jobId <STRING> - job id (optional, default: "")
 * 1: _buildName <STRING> - build name (optional, default: "")
 * 2: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_jobId, _buildName, _sideKey] call Waldo_fnc_EcoBuild_registerConstructionJob;
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

