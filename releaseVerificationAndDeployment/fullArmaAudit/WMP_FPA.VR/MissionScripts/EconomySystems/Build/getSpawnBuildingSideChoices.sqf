/*
 * Author: WaldoTheWarfighter
 * List the owner-side values offered by the building spawn prompt.
 *
 * Locality / Authority: Pure helper; safe on any machine. The server still validates a
 * submitted owner side before creating a building.
 * Repeat/JIP: Constant list; safe to read for each prompt and joining client.
 * Current Callers: EcoBuild_promptSpawnBuilding and EcoBuild_refreshSpawnBuildingSide.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ARRAY of STRING - NONE, WEST, EAST and GUER.
 * Result: Keeps the prompt's labels aligned with accepted side keys.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getSpawnBuildingSideChoices;
 */

        ["NONE", "WEST", "EAST", "GUER"]

