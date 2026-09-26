/*
 * Author: WaldoTheWarfighter
 * Backward-compatible entry point for the parameterised, repeat-safe AI rebalance system.
 * Locality and authority: Delegates to server-authoritative Waldo_fnc_AIRebalanceInit. A call
 * from another machine follows that function's forwarding path.
 * Repeat/JIP: The delegated initializer owns repeat handling and published AI profile state.
 * This wrapper installs no event handlers of its own.
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
 * Result: Returns the initializer's Boolean acceptance result for the requested mode/profile.
 *
 * Current callers: init.sqf startup and existing mission scripts using the legacy AITweak API.
 */

params [
    ["_mode", "DAY", [""]],
    ["_profile", missionNamespace getVariable ["Waldo_AI_Profile", "LINE"], [""]]
];
[_mode, _profile] call Waldo_fnc_AIRebalanceInit
