/*
 * Author: WaldoTheWarfighter, Val
 * Opens a local map selection for a transport request and removes only the event handler it owns.
 * The selected position is submitted to the server; no client creates waypoints or reserves assets.
 * Locality and authority: interface-client map UI only; the server validates the submitted click.
 *
 * Arguments: 0 request action <STRING>, including PICKUP_ALL; 1 service type <STRING>; 2 vehicle <OBJECT> (optional).
 * Return Value: Boolean - true when the map selector opened.
 * Example: ["REQUEST_PICKUP", "HELICOPTER", objNull] call Waldo_fnc_TransportOpenMapLocal;
 * Current callers: WMP transport ACE and vanilla self-actions.
 */
params [["_action", "REQUEST_PICKUP", [""]], ["_type", "GROUND", [""]], ["_vehicle", objNull, [objNull]]];
if (!hasInterface || {visibleMap}) exitWith {false};
private _oldHandler = missionNamespace getVariable ["Waldo_Transport_MapHandler", -1];
if (_oldHandler >= 0) then {removeMissionEventHandler ["MapSingleClick", _oldHandler]};
missionNamespace setVariable ["Waldo_Transport_MapHandler", -1];
openMap [true, false];
[toUpperANSI _type, "Select a position on the map. Escape cancels without changing service state.", "INFO"] call Waldo_fnc_TransportNotifyLocal;
private _handlerId = addMissionEventHandler ["MapSingleClick", {
    params ["_units", "_pos"];
    _thisArgs params ["_action", "_type", "_vehicle"];
    removeMissionEventHandler ["MapSingleClick", _thisEventHandler];
    missionNamespace setVariable ["Waldo_Transport_MapHandler", -1];
    openMap [false, false];
    if (_action == "PICKUP_ALL") then {
        ["PICKUP_ALL", _type, _pos, player] remoteExecCall ["Waldo_fnc_TransportBulkRequestServer", 2];
    } else {
        [_action, _type, _vehicle, _pos, player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2];
    };
}, [_action, toUpperANSI _type, _vehicle]];
missionNamespace setVariable ["Waldo_Transport_MapHandler", _handlerId];
[] spawn {
    waitUntil {sleep 0.1; !visibleMap};
    private _handler = missionNamespace getVariable ["Waldo_Transport_MapHandler", -1];
    if (_handler >= 0) then {removeMissionEventHandler ["MapSingleClick", _handler]};
    missionNamespace setVariable ["Waldo_Transport_MapHandler", -1];
};
true
