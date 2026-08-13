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
// A ZEN registration reaches TransportRegister through remote execution. Calls made deeper in that
// same server call stack still expose the curator as remoteExecutedOwner, so rejecting every owner
// other than the server also rejected the legitimate group rename. On the server, accept that path
// only for an already registered transport and replace the supplied text with its authoritative name.
private _authorized = true;
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) then {
    _authorized = isServer;
    private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
    private _matchingId = (keys _services) select {
        private _vehicle = (_services get _x) getOrDefault ["vehicle", objNull];
        !isNull _vehicle && {group driver _vehicle isEqualTo _group}
    } param [0, ""];
    _authorized = _authorized && {_matchingId != ""};
    if (_authorized) then {_displayName = (_services get _matchingId) getOrDefault ["name", _displayName]};
};
if (!_authorized) exitWith {false};
if (!local _group) exitWith {
    [_group, _displayName] remoteExecCall ["Waldo_fnc_TransportSetGroupNameLocal", groupOwner _group];
    true
};
_group setGroupIdGlobal [_displayName];
diag_log format ["[WMP TRANSPORT] Group callsign applied group=%1 requested=%2 owner=%3", groupId _group, _displayName, groupOwner _group];
true
