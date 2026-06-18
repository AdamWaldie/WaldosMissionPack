/*
 * Author: Waldo
 * Set commitment mode enabled.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _enabled <BOOL> - enabled (optional, default: false)
 * 1: _notify <BOOL> - notify (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_enabled, _notify] call Waldo_fnc_EcoCore_setCommitmentModeEnabled;
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
