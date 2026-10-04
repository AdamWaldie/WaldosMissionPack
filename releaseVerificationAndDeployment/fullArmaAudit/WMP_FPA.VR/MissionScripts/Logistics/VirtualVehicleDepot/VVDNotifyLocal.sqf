/*
 * Author: WaldoTheWarfighter
 * Displays a depot availability or validation message for one player.
 * Locality and authority: Runs on the addressed interface client after server depot checks.
 * Repeated calls show another transient dialog; no JIP state is replayed.
 * Arguments: 0: message <STRING> ("Vehicle depot request failed.").
 * Return Value: No supported value; the UI display is asynchronous.
 * Current caller: Waldo_fnc_VVDRequestOpenServer for blocked or busy depots.
 * Example: ["This vehicle depot is already in use."]
 *   remoteExecCall ["Waldo_fnc_VVDNotifyLocal", owner player];
 * Result: The intended player sees the depot message on their client.
 */
params [["_message", "Vehicle depot request failed.", [""]]];

if (!hasInterface) exitWith {};
[_message] spawn {
    params ["_text"];
    [_text] call BIS_fnc_guiMessage;
};
