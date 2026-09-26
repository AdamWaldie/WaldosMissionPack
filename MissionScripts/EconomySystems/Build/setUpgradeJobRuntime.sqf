/*
 * Author: WaldoTheWarfighter
 * Replace transient building-upgrade progress records on this machine.
 *
 * Locality / Authority: Called by Economy authority; records are not broadcast directly.
 * Repeat/JIP: Replaces the private timing list; joining clients observe
 * published building and job state instead of this runtime table.
 * Current Callers: EcoBuild_progressUpgradeJobs,
 * EcoBuild_startBuildingUpgrade and EcoCore_purgeBuildingValues.
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 * Result: Stores the supplied upgrade records locally.
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoBuild_setUpgradeJobRuntime;
 */

        params [["_rows", []]];
        missionNamespace setVariable ["WaldoEcoBuild_UpgradeJobRuntime", _rows];

