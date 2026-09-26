/*
 * Author: WaldoTheWarfighter
 * Replace transient construction-progress records on this machine.
 *
 * Locality / Authority: Called by Economy authority; unlike the active-job list, this
 * missionNamespace value is not broadcast to clients.
 * Repeat/JIP: Replaces the entire runtime list; JIP progress is represented
 * through published job/building state, not this private timing table.
 * Current Callers: EcoBuild_progressConstructionJobs,
 * EcoBuild_startPlacedConstruction, EcoBuild_startVehicleConstruction
 * and EcoCore_purgeBuildingValues.
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 * Result: Stores the supplied timing and site-object records locally.
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoBuild_setConstructionJobRuntime;
 */

        params [["_rows", []]];
        missionNamespace setVariable ["WaldoEcoBuild_ConstructionJobRuntime", _rows];

