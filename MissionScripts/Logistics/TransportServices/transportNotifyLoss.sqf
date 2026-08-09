/*
 * Author: WaldoTheWarfighter
 * Notifies every player on a written-off transport service's allowed sides. Split out of
 * Waldo_fnc_TransportMonitorServer so that recurring server loop stays free of remote execution -
 * this is called only on the one-time transition into the too-damaged write-off branch, never once
 * per monitor tick.
 * Locality and authority: server-only; forwards the actual card to each recipient's own client.
 *
 * Arguments:
 * 0: display name <STRING>
 * 1: type <STRING> - HELICOPTER or GROUND, selects the same channel/presentation
 *    Waldo_fnc_TransportNotifyLocal already uses for this service.
 * 2: allowed sides <ARRAY> - sides that receive the warning.
 *
 * Return Value:
 * Nothing.
 *
 * Example:
 * ["Raven One", "HELICOPTER", [west]] call Waldo_fnc_TransportNotifyLoss;
 *
 * Current caller: Waldo_fnc_TransportMonitorServer.
 */

params [["_name", "", [""]], ["_type", "GROUND", [""]], ["_allowedSides", [], [[]]]];
if !(isServer) exitWith {};
private _recipients = allPlayers select {side _x in _allowedSides};
if (count _recipients == 0) exitWith {};
[
    _type,
    format ["%1 is too heavily damaged to remain effective and has been removed from service.", _name],
    "WARNING", _name, 8
] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", _recipients];
