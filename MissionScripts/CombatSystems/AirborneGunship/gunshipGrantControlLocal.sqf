/*
 * Author: WaldoTheWarfighter
 * Completes a server-approved local remote-control handoff to one turret crew member.
 * Locality and authority: Runs on the assigned controller's interface client after the server
 * has approved the handoff; checks the public system summary and a crewed turret path.
 * Repeat/JIP: A fresh handoff sets the current local controlled ID. This camera state is not
 * replayed to joiners; only current assigned controllers can receive the request.
 * Arguments: 0: id <STRING>; 1: aircraft <OBJECT>; 2: turret path <ARRAY>
 * Return Value: Boolean
 * Current caller: Waldo_fnc_GunshipServerHandle after controller validation.
 * Example: ["SPECTRE_1", _aircraft, [0]] call Waldo_fnc_GunshipGrantControlLocal;
 * Result: The controller views and remote-controls the chosen crewed gunship turret.
 */

params ["_id", "_aircraft", "_turretPath"];
if !(hasInterface && {!isNull _aircraft}) exitWith {false};
private _summaryIndex = (missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []]) findIf {(_x select 0) == _id && {(_x select 2) isEqualTo player}};
if (_summaryIndex < 0) exitWith {false};
private _crewIndex = (fullCrew [_aircraft, "", false]) findIf {(_x select 3) isEqualTo _turretPath};
if (_crewIndex < 0) exitWith {["The configured gunship turret is not crewed."] call Waldo_fnc_GunshipNotifyLocal; false};
private _crew = (fullCrew [_aircraft, "", false] select _crewIndex) select 0;
if (isNull _crew) exitWith {false};
player remoteControl _crew;
_crew switchCamera "GUNNER";
missionNamespace setVariable ["Waldo_Gunship_ControlledId", _id];
true
