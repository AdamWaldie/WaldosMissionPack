/*
 * Author: WaldoTheWarfighter
 * Read a copy of the current active construction-job list.
 *
 * Locality / Authority: Reads this machine's missionNamespace; authoritative callers
 * should run on Economy authority, not trust a client's stale copy.
 * Repeat/JIP: Read-only and repeat-safe; the helper does not synchronize JIP.
 * Current Callers: EcoBuild_getBuildCountForSide,
 * EcoBuild_registerConstructionJob and EcoBuild_unregisterConstructionJob.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ARRAY - shallow copy of active job records; [] when unset.
 * Result: Callers can edit the outer array without changing the stored list.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getActiveConstructionJobs;
 */

        +(missionNamespace getVariable ["WaldoEcoBuild_ActiveConstructionJobs", []])

