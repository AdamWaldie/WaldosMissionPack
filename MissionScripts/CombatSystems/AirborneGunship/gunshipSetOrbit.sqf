/*
 * Author: WaldoTheWarfighter
 * Replaces an aircraft's route with a validated loiter waypoint.
 *
 * A TRANSIT issue whose position genuinely differs from the gunship's own currently stored orbit is
 * treated as a curator/controller retask and tags offStationReason "RETASK" (read by
 * Waldo_fnc_GunshipStatusHud). The monitor's own post-service resume call and the RETURN operation
 * both re-issue the exact same stored orbit position, so neither is mistaken for a real retask; a
 * SERVICE/RTB issue never reaches this branch at all (status is "RTB", not "TRANSIT").
 *
 * Arguments: 0: id <STRING>; 1: position <ARRAY>; 2: status after issue <STRING>
 * Return Value: Boolean
 */

params ["_id", "_position", ["_status", "TRANSIT", [""]]];
if !(isServer && {_position isEqualType []} && {count _position >= 2}) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
if !(_id in keys _registry) exitWith {false};
private _state = _registry get _id;
private _aircraft = _state getOrDefault ["aircraft", objNull];
if (isNull _aircraft || {!alive _aircraft} || {isNull driver _aircraft}) exitWith {false};
private _config = _state get "config";
private _statusUpper = toUpperANSI _status;
private _previousOrbit = _state getOrDefault ["orbit", []];
if (_statusUpper == "TRANSIT" && {!(_previousOrbit isEqualTo _position)}) then {
    _state set ["offStationReason", "RETASK"];
};
[
    _aircraft, _position, _config getOrDefault ["altitude", 700], _config getOrDefault ["radius", 1500],
    _config getOrDefault ["direction", "CIRCLE_L"], _config getOrDefault ["pilotBehaviour", "CARELESS"],
    _config getOrDefault ["pilotCombatMode", "BLUE"]
] remoteExecCall ["Waldo_fnc_GunshipApplyOrbitLocal", owner _aircraft];
_state set ["orbit", +_position];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
private _message = if (toUpperANSI _status == "RTB") then {
    format ["%1 is returning for service.", _config getOrDefault ["callsign", _id]]
} else {
    format ["%1 is moving to its assigned orbit.", _config getOrDefault ["callsign", _id]]
};
[_id, _status, _message] call Waldo_fnc_GunshipSetState
