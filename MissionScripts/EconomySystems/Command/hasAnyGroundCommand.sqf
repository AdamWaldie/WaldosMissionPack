/*
 * Author: Waldo
 * Has any ground command.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_hasAnyGroundCommand;
 */

    (count (call Waldo_fnc_EcoCommand_getGroundCommandUIDs)) > 0
