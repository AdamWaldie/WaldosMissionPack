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
 * Locality/Authority: Interface client; sends the acquisition request to the server.
 * Repeat/JIP Behaviour: Repeated clicks are gated by the server's attempt state;
 * a joining player sees the published state before attempting use.
 * Current Callers: ACE and vanilla actions installed by MiniGameInteraction.
 * Example: [_equipment] call Waldo_fnc_MiniGameInteractionActivate;
 * Result: Requests a server-owned attempt; it does not open the challenge until accepted.
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
