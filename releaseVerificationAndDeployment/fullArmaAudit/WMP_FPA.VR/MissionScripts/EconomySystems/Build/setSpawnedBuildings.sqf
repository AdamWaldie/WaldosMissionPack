/*
 * Author: WaldoTheWarfighter
 * Replaces and broadcasts the completed-building registry.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoBuild_setSpawnedBuildings;
 * Locality/Authority: Economy authority only; clients consume public rows.
 * Repeat/JIP Behaviour: Replacement is repeat-safe; JIP receives latest registry.
 * Current Callers: Building placement, deletion and authoritative maintenance.
 * Result: Later building queries use the supplied rows.
 */

        params [["_rows", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_SpawnedBuildings", _rows, true];

