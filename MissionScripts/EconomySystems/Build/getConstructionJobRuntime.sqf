/*
 * Author: WaldoTheWarfighter
 * Read a copy of the transient construction-job runtime records.
 *
 * Locality / Authority: Reads local missionNamespace; construction authority owns the
 * canonical runtime list.
 * Repeat/JIP: Read-only and repeat-safe. Runtime progress is not replayed
 * by this helper; the owning job system handles later clients.
 * Current Callers: EcoBuild_progressConstructionJobs,
 * EcoBuild_startPlacedConstruction, EcoBuild_startVehicleConstruction
 * and EcoCore_purgeBuildingValues.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ARRAY - shallow copy of runtime job records; [] when unset.
 * Result: Returns job timing and world-object references without mutating them.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getConstructionJobRuntime;
 */

        +(missionNamespace getVariable ["WaldoEcoBuild_ConstructionJobRuntime", []])

