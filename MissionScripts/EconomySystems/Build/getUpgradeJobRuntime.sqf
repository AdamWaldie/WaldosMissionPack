/*
 * Author: WaldoTheWarfighter
 * Read a copy of transient building-upgrade job records.
 *
 * Locality / Authority: Reads local missionNamespace; Economy authority owns the
 * canonical progress records.
 * Repeat/JIP: Read-only and repeat-safe; this helper does not replay JIP state.
 * Current Callers: EcoBuild_progressUpgradeJobs,
 * EcoBuild_startBuildingUpgrade and EcoCore_purgeBuildingValues.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ARRAY - shallow copy of upgrade runtime records; [] when unset.
 * Result: Callers can change the outer list without mutating stored state.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getUpgradeJobRuntime;
 */

        +(missionNamespace getVariable ["WaldoEcoBuild_UpgradeJobRuntime", []])

