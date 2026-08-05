/*
 * Author: WaldoTheWarfighter, Val
 * Changes a registered transport crew group's callsign to the service's player-facing display name.
 * This keeps Zeus, map and command views consistent with the name shown in WMP Transport controls.
 * Locality and authority: the server requests the change; the machine owning the AI group applies
 * setGroupIdGlobal so every connected player and JIP client receives the same name.
 *
 * Arguments:
 * 0: service crew group <GROUP>
 * 1: display name <STRING>
 *
 * Return Value: Boolean - true when applied or forwarded to the current group owner.
 * Example: [group driver _vehicle, "Raven One"] call Waldo_fnc_TransportSetGroupNameLocal;
 * Current caller: Waldo_fnc_TransportRegister after authoritative registration succeeds.
 */

params [["_group", grpNull, [grpNull]], ["_displayName", "", [""]]];
if (isNull _group || {_displayName == ""}) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    [_group, _displayName] remoteExecCall ["Waldo_fnc_TransportSetGroupNameLocal", groupOwner _group];
    true
};
_group setGroupIdGlobal [_displayName];
true
