/*
 * Author: WaldoTheWarfighter
 * Checks whether a Ground Command identity has been assigned.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <BOOL> true when at least one command key exists.
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_hasAnyGroundCommand;
 * Locality/Authority: Any machine; read-only command-list check.
 * Repeat/JIP Behaviour: Repeat-safe and reflects the latest published list for JIP clients.
 * Current Callers: EcoCommand_hasCommandAuthority and Economy command gating.
 * Result: Returns false when the list is empty.
 */

    (count (call Waldo_fnc_EcoCommand_getGroundCommandUIDs)) > 0
