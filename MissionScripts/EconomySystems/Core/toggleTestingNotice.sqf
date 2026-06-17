/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - toggleTestingNotice
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_toggleTestingNotice via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    [!([] call Waldo_fnc_EcoCore_isTestingNoticeEnabled)] call Waldo_fnc_EcoCore_setTestingNoticeEnabled
