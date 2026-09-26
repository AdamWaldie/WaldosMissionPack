/*
 * Author: WaldoTheWarfighter
 * Remove a completed or cancelled construction job from the published list.
 *
 * Locality / Authority: Economy authority only; the list setter broadcasts the result.
 * Repeat/JIP: Removing an already-absent ID leaves the list unchanged;
 * joining clients receive the current list.
 * Current Callers: EcoBuild_progressConstructionJobs.
 *
 * Arguments:
 * 0: _jobId <STRING> - job id (optional, default: "")
 *
 * Return Value:
 * Nothing.
 * Result: Stores the active-job list without the given job ID.
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

