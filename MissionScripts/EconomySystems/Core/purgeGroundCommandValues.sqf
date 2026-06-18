/*
 * Author: Waldo
 * Purge ground command values.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_purgeGroundCommandValues;
 */

    if (!isNil "Waldo_fnc_EcoCommand_setGroundCommandUIDs") then {
        [[]] call Waldo_fnc_EcoCommand_setGroundCommandUIDs;
    };
