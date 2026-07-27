/*
 * Author: WaldoTheWarfighter
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
if !(_object getVariable ["Waldo_MG_Int_Active", true]) exitWith {
    ["EQUIPMENT UNAVAILABLE", "WARN", 3] call Waldo_fnc_MiniGameInteractionNotifyClient;
};
if ((_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "RUNNING") exitWith {
    ["EQUIPMENT IN USE BY ANOTHER OPERATOR", "WARN", 3] call Waldo_fnc_MiniGameInteractionNotifyClient;
};

_object setVariable ["Waldo_MG_Int_LastActivationRequested", diag_tickTime];
[_object, player] remoteExecCall ["Waldo_fnc_MiniGameInteractionAcquireServer", 2];
