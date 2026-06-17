/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - setCommitmentModeEnabled
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_setCommitmentModeEnabled via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_enabled", false], ["_notify", true]];

    missionNamespace setVariable ["WaldoEcoCore_CommitmentModeEnabled", _enabled, true];
    [] call Waldo_fnc_EcoCore_refreshSaveCommitmentMenuState;

    if (_notify && {hasInterface}) then {
        hintSilent format [
            "Commitment Mode %1\n\nResearch, construction, and purchase menus will %2 full config refreshes while this stays %1.",
            ["OFF", "ON"] select _enabled,
            ["resume", "pause"] select _enabled
        ];
    };

    _enabled
