/* Creates a Zeus-configured jammer on the server after validating the curator. */
params [
    ["_position", [], [[]]],
    ["_settings", [], [[]]],
    ["_actor", objNull, [objNull]]
];

if (!isServer) exitWith {
    [_position, _settings, player] remoteExecCall ["Waldo_fnc_ZenCreateJammerServer", 2];
    objNull
};

private _requestOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
if (isRemoteExecuted && {
    isNull _actor
    || {_requestOwner != owner _actor}
    || {isNull (getAssignedCuratorLogic _actor)}
}) exitWith {
    diag_log format ["[WMP ZEN] rejected jammer-create request owner=%1 actor=%2", _requestOwner, _actor];
    objNull
};
if ((count _position) < 2 || {(count _settings) < 9}) exitWith {objNull};

private _radius = 300;
private _side = "ALL";
private _bands = "ALL";
private _falloff = 50;
private _strength = 1;
private _active = true;
private _marker = false;
private _sector = [];
private _duty = [];
private _jamUAV = false;
private _show3D = false;
private _className = "Land_PowerGenerator_F";
if ((count _settings) >= 12) then {
    _settings params ["_radius", "_side", "_bands", "_falloff", "_strength", "_active", "_marker", "_sector", "_duty", "_jamUAV", "_show3D", "_className"];
} else {
    // Compatibility with the original internal nine-field Zeus payload.
    _settings params ["_radius", "_side", "_falloff", "_strength", "_marker", "_sector", "_duty", "_jamUAV", "_className"];
};
if !(isClass (configFile >> "CfgVehicles" >> _className)) then {_className = "Land_PowerGenerator_F";};
private _object = createVehicle [_className, _position, [], 0, "CAN_COLLIDE"];
[_object, _radius, _side, _bands, _falloff, _strength, _active, _marker, _sector, _duty, _jamUAV, _show3D] call Waldo_fnc_Jammer;
{ _x addCuratorEditableObjects [[_object], true]; } forEach allCurators;
diag_log format ["[WMP ZEN] jammer created object=%1 actor=%2 owner=%3", netId _object, if (isNull _actor) then {"<server>"} else {name _actor}, _requestOwner];
if (!isNull _actor) then {
    ["JAMMER PLACED", format ["%1 m field affecting %2.", _radius, _side], 6, "SUCCESS"] remoteExecCall ["Waldo_fnc_JammingNotice", owner _actor];
};
_object
