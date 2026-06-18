/*
 * Author: Waldo
 * Toggle testing notice.
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
 * [] call Waldo_fnc_EcoCore_toggleTestingNotice;
 */

    [!([] call Waldo_fnc_EcoCore_isTestingNoticeEnabled)] call Waldo_fnc_EcoCore_setTestingNoticeEnabled
