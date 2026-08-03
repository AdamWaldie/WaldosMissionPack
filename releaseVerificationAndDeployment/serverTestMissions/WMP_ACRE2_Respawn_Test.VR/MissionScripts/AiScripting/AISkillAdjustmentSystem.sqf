/*
 * Author: WaldoTheWarfighter
 * Backward-compatible entry point for the parameterised, repeat-safe AI rebalance system.
 *
 * Arguments:
 * 0: mode <STRING> - DAY or NIGHT (default: DAY)
 * 1: profile <STRING> - LEGACY, MILITIA, LINE, VETERAN, ELITE, compatibility aliases, or a custom profile key (default: LINE)
 *
 * Return Value:
 * Boolean - true when initialisation was accepted
 *
 * Example:
 * ["DAY", "LINE"] call Waldo_fnc_AITweak;
 *
 * Current callers: init.sqf startup and existing mission scripts using the legacy AITweak API.
 */

params [
    ["_mode", "DAY", [""]],
    ["_profile", missionNamespace getVariable ["Waldo_AI_Profile", "LINE"], [""]]
];
[_mode, _profile] call Waldo_fnc_AIRebalanceInit
