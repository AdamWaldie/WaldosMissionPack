/*
 * Author: WaldoTheWarfighter
 * Restores one packaged vehicle at a clear position inside its assigned recovery workshop.
 *
 * Repairable vehicles are restored as the same hidden object retained during packaging, preserving
 * arbitrary scripts, event handlers, actions, variables and external references. Destroyed vehicles
 * cannot be resurrected reliably by the engine, so that path creates a replacement, rebinds its Eden
 * variable name, copies configured custom variables and invokes `Waldo_Recovery_OnRestored` when it
 * is CODE or a missionNamespace function name. The package is retained and retried when no complete
 * destination footprint is clear; there is no overlapping fallback position.
 *
 * Arguments:
 * 0: recovery package <OBJECT>.
 * 1: registered workshop <OBJECT>.
 *
 * Return Value: OBJECT - restored vehicle, or objNull when validation/placement fails.
 *
 * Example: [_package, _workshop] call Waldo_fnc_RecoveryRestoreServer;
 * Current caller: RecoveryMonitorServer after a grounded package enters a matching workshop.
 */

params [["_package", objNull, [objNull]], ["_workshop", objNull, [objNull]]];
if (!isServer || {remoteExecutedOwner > 0} || {isNull _package} || {isNull _workshop}) exitWith {objNull};
if (_package getVariable ["Waldo_Recovery_Transition", false]) exitWith {objNull};
_package setVariable ["Waldo_Recovery_Transition", true];
private _state = _package getVariable ["Waldo_Recovery_State", []];
if (count _state < 7) exitWith {_package setVariable ["Waldo_Recovery_Transition", false]; objNull};
_state params ["_class", "_textures", "_pylons", "_cargo", "_config", "_wasCarrier", "_carrierRange"];
private _retained = _state param [7, objNull, [objNull]];
private _wasAlive = _state param [8, false, [false]];
private _variableName = _state param [9, "", [""]];
private _vectorDirUp = _state param [10, [[0, 1, 0], [0, 0, 1]], [[]]];
private _simulation = _state param [11, true, [false]];
private _damageAllowed = _state param [12, true, [false]];
private _onRestored = _state param [13, {}, [{}, ""]];
private _customVariables = _state param [14, [], [[]]];
private _footprint = (_state param [15, 3, [0]]) max (missionNamespace getVariable ["Waldo_Recovery_PlacementClearance", 3]);
private _carrierMode = _state param [16, "AUTO", [""]];
private _carrierCapacity = _state param [17, 1, [0]];
private _carrierDeckOffset = _state param [18, [], [[]]];
private _carrierDeckDirection = _state param [19, 0, [0]];

private _position = [_workshop, _class, _footprint, [_package, _retained]] call Waldo_fnc_RecoveryResolveRestorePosition;
if (_position isEqualTo []) exitWith {
    _package setVariable ["Waldo_Recovery_Transition", false];
    diag_log format ["[WMP RECOVERY] Restore delayed: no clear position package=%1 workshop=%2 class=%3", netId _package, netId _workshop, _class];
    objNull
};
private _vehicle = objNull;
if (_wasAlive && {!isNull _retained}) then {
    _vehicle = _retained;
    _vehicle setVectorDirAndUp _vectorDirUp;
    _vehicle setPosATL _position;
    _vehicle hideObjectGlobal false;
} else {
    _vehicle = createVehicle [_class, _position, [], 0, "NONE"];
    if (isNull _vehicle) exitWith {_package setVariable ["Waldo_Recovery_Transition", false]; objNull};
    _vehicle setVectorDirAndUp _vectorDirUp;
    _vehicle setPosATL _position;
    if (!isNull _retained) then {deleteVehicle _retained};
    if (_variableName != "") then {
        _vehicle setVehicleVarName _variableName;
        missionNamespace setVariable [_variableName, _vehicle, true];
    };
    {_x params ["_name", "_value"]; _vehicle setVariable [_name, _value, true]} forEach _customVariables;
};

deleteVehicle _package;
{_vehicle setObjectTextureGlobal [_forEachIndex, _x]} forEach _textures;
{if (_x != "") then {_vehicle setPylonLoadOut [_forEachIndex + 1, _x, true]}} forEach _pylons;
if !(_cargo isEqualTo []) then {
    clearWeaponCargoGlobal _vehicle; clearMagazineCargoGlobal _vehicle; clearItemCargoGlobal _vehicle; clearBackpackCargoGlobal _vehicle;
    (_cargo select 0) params ["_classes", "_counts"]; {_vehicle addWeaponCargoGlobal [_x, _counts select _forEachIndex]} forEach _classes;
    (_cargo select 1) params ["_classes", "_counts"]; {_vehicle addMagazineCargoGlobal [_x, _counts select _forEachIndex]} forEach _classes;
    (_cargo select 2) params ["_classes", "_counts"]; {_vehicle addItemCargoGlobal [_x, _counts select _forEachIndex]} forEach _classes;
    (_cargo select 3) params ["_classes", "_counts"]; {_vehicle addBackpackCargoGlobal [_x, _counts select _forEachIndex]} forEach _classes;
};
_vehicle setDamage 0;
_vehicle setFuel (_config param [6, 1]);
_vehicle allowDamage _damageAllowed;
_vehicle enableSimulationGlobal _simulation;
private _interactionState = _config param [7, [false, "repair", "standard"]];
private _interactionOptions = createHashMapFromArray [
    ["enabled", _interactionState param [0, false]],
    ["challengeId", _interactionState param [1, "repair"]],
    ["difficulty", _interactionState param [2, "standard"]]
];
[_vehicle, _config select 0, _config select 1, _config select 2, _config select 3, _config select 4, _config select 5, _config select 6, _interactionOptions]
    call Waldo_fnc_RecoveryRegisterVehicle;
if (_wasCarrier) then {[_vehicle, _carrierRange, _carrierMode, _carrierCapacity, _carrierDeckOffset, _carrierDeckDirection] call Waldo_fnc_RecoveryRegisterCarrier};
private _transportRegistration = _vehicle getVariable ["Waldo_TransportService_Registration", []];
if (count _transportRegistration >= 4) then {
    _transportRegistration params ["_transportType", "_transportId", "_transportName", "_transportOptions"];
    [_vehicle, _transportType, _transportId, _transportName, _transportOptions] call Waldo_fnc_TransportRegister;
};
if !(_wasAlive) then {
    private _callback = if (_onRestored isEqualType "") then {missionNamespace getVariable [_onRestored, {}]} else {_onRestored};
    if (_callback isEqualType {}) then {[_vehicle, _retained, _workshop] call _callback};
};
private _packages = (missionNamespace getVariable ["Waldo_Recovery_Packages", []]) select {!isNull _x && {_x != _package}};
missionNamespace setVariable ["Waldo_Recovery_Packages", _packages];
private _workshopSide = _workshop getVariable ["Waldo_Recovery_Side", sideUnknown];
private _notificationRadius = (_workshop getVariable ["Waldo_Recovery_NotificationRadius", missionNamespace getVariable ["Waldo_Recovery_NotificationRadius", 100]]) max 0;
private _recipients = allPlayers select {
    _x distance2D _workshop <= _notificationRadius
    && {_workshopSide == sideUnknown || {_workshopSide getFriend side group _x >= 0.6}}
};
if !(_recipients isEqualTo []) then {
    ["A recovered vehicle is ready at the workshop.", "SUCCESS"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", _recipients];
};
_vehicle
