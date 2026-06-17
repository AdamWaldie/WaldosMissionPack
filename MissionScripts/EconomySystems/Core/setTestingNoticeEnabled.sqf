/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - setTestingNoticeEnabled
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_setTestingNoticeEnabled via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_enabled", false], ["_notify", true]];

    private _wasEnabled = [] call Waldo_fnc_EcoCore_isTestingNoticeEnabled;
    missionNamespace setVariable ["WaldoEcoCore_TestingNoticeEnabled", _enabled, true];
    if (_enabled && {!_wasEnabled}) then {
        private _oldToken = missionNamespace getVariable ["WaldoEcoCore_TestingNoticeToken", 0];
        missionNamespace setVariable ["WaldoEcoCore_TestingNoticeToken", _oldToken + 1, true];
    };
    [] call Waldo_fnc_EcoCore_refreshSaveTestingNoticeMenuState;

    if (_notify && {hasInterface}) then {
        hintSilent format [
            "Testing Notice %1\n\nPlayers will %2 receive the one-time testing popup.",
            ["OFF", "ON"] select _enabled,
            ["not", "now"] select _enabled
        ];
    };

    _enabled
