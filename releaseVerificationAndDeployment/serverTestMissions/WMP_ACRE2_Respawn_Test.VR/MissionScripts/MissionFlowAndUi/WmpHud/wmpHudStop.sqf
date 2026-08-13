/*
 * Author: WaldoTheWarfighter, Val
 * Removes the local WMP HUD Draw3D handler and clears its transient local state. It removes only
 * controls and handlers owned by this feature and is repeat-safe.
 * Locality and authority: interface-client cleanup only.
 *
 * Arguments: None.
 * Return Value: Nothing.
 *
 * Example:
 * [] call Waldo_fnc_WmpHudStop;
 * Result: the current client stops drawing WMP HUD identifiers.
 * Current callers: WMP HUD respawn handling and runtime disable/cleanup paths.
 */

if !(hasInterface) exitWith {};
private _eventId = missionNamespace getVariable ["Waldo_WmpHud_EventId", -1];
if (_eventId >= 0) then {removeMissionEventHandler ["Draw3D", _eventId]};
missionNamespace setVariable ["Waldo_WmpHud_EventId", -1];
missionNamespace setVariable ["Waldo_WmpHud_Visible", false];
missionNamespace setVariable ["Waldo_WmpHud_ClientStarted", false];
