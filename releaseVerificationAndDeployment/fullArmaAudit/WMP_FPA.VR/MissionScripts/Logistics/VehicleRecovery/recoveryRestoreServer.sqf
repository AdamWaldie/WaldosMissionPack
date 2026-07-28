/* Recreates a packaged vehicle at a workshop and reapplies portable state. */
params [["_package", objNull, [objNull]], ["_workshop", objNull, [objNull]]];
if (!isServer || {remoteExecutedOwner > 0} || {isNull _package} || {isNull _workshop}) exitWith {objNull};
private _state = _package getVariable ["Waldo_Recovery_State", []];
if (count _state < 7) exitWith {objNull};
_state params ["_class", "_textures", "_pylons", "_cargo", "_config", "_wasCarrier", "_carrierRange"];
private _origin = getPosATL _workshop;
private _position = _origin findEmptyPosition [5, (_workshop getVariable ["Waldo_Recovery_Radius", 50]) max 10, _class];
if (_position isEqualTo []) then {_position = _origin vectorAdd [5, 0, 0]};
deleteVehicle _package;
private _vehicle = createVehicle [_class, _position, [], 0, "NONE"];
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
[_vehicle, _config select 0, _config select 1, _config select 2, _config select 3, _config select 4, _config select 5, _config select 6] call Waldo_fnc_RecoveryRegisterVehicle;
if (_wasCarrier) then {[_vehicle, _carrierRange] call Waldo_fnc_RecoveryRegisterCarrier};
private _packages = (missionNamespace getVariable ["Waldo_Recovery_Packages", []]) select {!isNull _x && {_x != _package}};
missionNamespace setVariable ["Waldo_Recovery_Packages", _packages];
private _workshopSide = _workshop getVariable ["Waldo_Recovery_Side", sideUnknown];
private _recipients = if (_workshopSide == sideUnknown) then {0} else {_workshopSide};
["A recovered vehicle is ready at the workshop.", "SUCCESS"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", _recipients];
_vehicle
