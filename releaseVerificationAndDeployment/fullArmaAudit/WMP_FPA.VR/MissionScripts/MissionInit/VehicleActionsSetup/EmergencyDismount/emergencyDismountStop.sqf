/*
 * Author: WaldoTheWarfighter
 * Stops the local emergency-dismount monitor.
 * Locality/authority: interface client only; this never changes a vehicle or another player.
 * Repeat/JIP: safe when the monitor is already stopped. Joining clients start their own monitor
 * through the runtime-settings path while the feature is enabled.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * No useful value.
 * Current callers: feature-runtime disable path and optional mission-maker client scripts.
 *
 * Example:
 * [] call Waldo_fnc_EmergencyDismountStop;
 * Result: the current client no longer checks for rollover or destroyed-vehicle extraction.
 */

if !(hasInterface) exitWith {};
missionNamespace setVariable ["Waldo_EmergencyDismount_ClientStarted", false];
private _handle = missionNamespace getVariable ["Waldo_EmergencyDismount_ClientLoop", scriptNull];
if !(scriptDone _handle) then {terminate _handle};
