/*
 * Author: WaldoTheWarfighter
 * Reads a copy of registered completed Economy buildings.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY> registered building rows.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getSpawnedBuildings;
 * Locality/Authority: Any machine; read-only published registry lookup.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP receives current rows.
 * Current Callers: Build export, marker and building-maintenance helpers.
 * Result: Returns a copy of the registry.
 */

        +(missionNamespace getVariable ["WaldoEcoBuild_SpawnedBuildings", []])

