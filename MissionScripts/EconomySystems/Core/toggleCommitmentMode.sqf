/*
 * Author: Waldo
 * Toggle commitment mode.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_toggleCommitmentMode;
 */

    [!([] call Waldo_fnc_EcoCore_isCommitmentModeEnabled)] call Waldo_fnc_EcoCore_setCommitmentModeEnabled
