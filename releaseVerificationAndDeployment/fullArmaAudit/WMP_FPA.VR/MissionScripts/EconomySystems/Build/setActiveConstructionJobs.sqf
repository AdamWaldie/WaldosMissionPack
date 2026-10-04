/*
 * Author: WaldoTheWarfighter
 * Publish the authoritative list of active construction jobs.
 *
 * Locality / Authority: Economy authority only; broadcasts the missionNamespace variable.
 * Repeat/JIP: Replaces the list on each update; joining clients receive the
 * latest published snapshot, not a series of historical changes.
 * Current Callers: EcoBuild_registerConstructionJob,
 * EcoBuild_unregisterConstructionJob and EcoCore_purgeBuildingValues.
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 * Result: Stores and publishes the supplied rows when authority permits.
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoBuild_setActiveConstructionJobs;
 */

        params [["_rows", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_ActiveConstructionJobs", _rows, true];

