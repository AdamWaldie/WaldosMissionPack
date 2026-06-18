/*
 * Author: Waldo
 * Shows a short feedback message to a specific actor's client (the player who triggered an economy
 * action). Used by the server-authoritative action handlers to explain why an action did or did not
 * happen (insufficient resources, unmet requirements, no drop point, etc.) instead of failing
 * silently. Safe to call from the server; it routes to the actor's machine via remoteExec.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _actor <OBJECT> - the player to notify
 * 1: _message <STRING> - the message to display
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_caller, "Not enough resources."] call Waldo_fnc_EcoCore_notifyActor;
 */

    params [["_actor", objNull], ["_message", ""]];

    if (isNull _actor) exitWith {};
    if (_message isEqualTo "") exitWith {};
    if (!(_actor isKindOf "CAManBase")) exitWith {};

    [_message] remoteExec ["systemChat", _actor];
