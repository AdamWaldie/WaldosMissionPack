/*
 * Author: Waldo
 * Requests exclusive ownership of an interaction procedure from the server. The server checks
 * availability, range and ownership before any client display is opened.
 *
 * Arguments:
 * _object - Object - the ACE/addAction target
 *
 * Return Value:
 * Nothing
 */

params [["_object", objNull, [objNull]]];

if (!hasInterface || {isNull _object}) exitWith {};
if !(_object getVariable ["Waldo_MG_Int_Active", true]) exitWith {};
if ((_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "RUNNING") exitWith {};

[_object, player] remoteExecCall ["Waldo_fnc_MiniGameInteractionAcquireServer", 2];
