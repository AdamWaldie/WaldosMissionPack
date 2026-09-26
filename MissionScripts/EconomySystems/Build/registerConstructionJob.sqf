/*
 * Author: WaldoTheWarfighter
 * Add a new named construction job to the published active-job list.
 *
 * Locality / Authority: Economy authority only; the list setter broadcasts it.
 * Repeat/JIP: An existing job ID is ignored, preventing duplicate entries;
 * JIP clients receive the published list.
 * Current Callers: EcoBuild_startPlacedConstruction and
 * EcoBuild_startVehicleConstruction.
 *
 * Arguments:
 * 0: _jobId <STRING> - job id (optional, default: "")
 * 1: _buildName <STRING> - build name (optional, default: "")
 * 2: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Nothing
 * Result: Adds [job ID, definition name, side key] when both IDs are valid.
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

