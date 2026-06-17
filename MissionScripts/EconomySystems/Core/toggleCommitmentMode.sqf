/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - toggleCommitmentMode
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_toggleCommitmentMode via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    [!([] call Waldo_fnc_EcoCore_isCommitmentModeEnabled)] call Waldo_fnc_EcoCore_setCommitmentModeEnabled
