/*
 * Author: Waldo
 * Backward-compatible entry point for the parameterised, repeat-safe AI rebalance system.
 *
 * Arguments:
 * 0: mode <STRING> - DAY or NIGHT (default: DAY)
 * 1: profile <STRING> - LEGACY, PUBLIC, STANDARD, VETERAN, or a custom profile key (default: LEGACY)
 *
 * Return Value:
 * Boolean - true when initialisation was accepted
 *
 * Example:
 * ["DAY", "STANDARD"] call Waldo_fnc_AITweak;
 */

params [
    ["_mode", "DAY", [""]],
    ["_profile", missionNamespace getVariable ["Waldo_AI_Profile", "LEGACY"], [""]]
];
[_mode, _profile] call Waldo_fnc_AIRebalanceInit
