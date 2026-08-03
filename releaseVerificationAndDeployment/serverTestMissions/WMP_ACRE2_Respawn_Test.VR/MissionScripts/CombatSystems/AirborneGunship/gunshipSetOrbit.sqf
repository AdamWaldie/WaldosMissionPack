/*
 * Author: WaldoTheWarfighter
 * Replaces an aircraft's route with a validated loiter waypoint.
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
