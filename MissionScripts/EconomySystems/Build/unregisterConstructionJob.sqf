/*
 * Author: Waldo
 * Unregister construction job.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _jobId <STRING> - job id (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_jobId] call Waldo_fnc_EcoBuild_unregisterConstructionJob;
 */

        params [["_jobId", ""]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_jobId isEqualTo "") exitWith {};

        private _rows = call Waldo_fnc_EcoBuild_getActiveConstructionJobs;
        _rows = _rows select {(_x param [0, ""]) isNotEqualTo _jobId};
        [_rows] call Waldo_fnc_EcoBuild_setActiveConstructionJobs;

