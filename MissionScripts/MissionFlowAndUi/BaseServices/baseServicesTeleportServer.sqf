/*
 * Author: WaldoTheWarfighter
 * Purpose: Validates a service-network teleport request before dispatching to the player's owner.
 * Locality / Authority: Server only; checks remote caller, registration, and physical proximity.
 * Repeat / JIP: Stateless request; JIP uses the published registration.
 * Arguments: player <OBJECT>, origin <OBJECT>, group ID <STRING>, destination <OBJECT>.
 * Return Value: <BOOL> request accepted. Current caller: local ACE Move to action.
 * Example: [player, baseRadio, "HQ", fobRadio] remoteExecCall ["Waldo_fnc_BaseServicesTeleportServer", 2];
 * Result: A valid request starts destination-side travel on the player's owning client.
 */
params [["_player", objNull, [objNull]], ["_origin", objNull, [objNull]], ["_id", "", [""]], ["_destination", objNull, [objNull]]];
if (!isServer || {!(missionNamespace getVariable ["Waldo_BaseServices_Enable", false])}) exitWith {false};
if (isNull _player || {isNull _origin} || {isNull _destination} || {!alive _player}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}) exitWith {false};
if (_player distance _origin > 6) exitWith {false};
private _groups = missionNamespace getVariable ["Waldo_BaseServices_Registry", []];
private _idx = _groups findIf {(_x select 0) isEqualTo _id};
if (_idx < 0) exitWith {false};
private _group = _groups select _idx;
private _rows = _group select 1;
if (_rows findIf {(_x select 0) isEqualTo _origin && {"TELEPORT" in (_x select 2)}} < 0) exitWith {false};
private _destinationIndex = _rows findIf {(_x select 0) isEqualTo _destination && {"TELEPORT" in (_x select 2)}};
if (_destinationIndex < 0) exitWith {false};
private _destinationRow = _rows select _destinationIndex;
private _destinationName = _destinationRow param [1, "Destination", [""]];
private _transition = _destinationRow param [4, ""];
if (_transition isEqualTo "") then {_transition = _group param [2, "STANDARD"]};
[_player, _destination, _transition, _destinationName] remoteExecCall ["Waldo_fnc_BaseServicesTeleportLocal", _player];
true
