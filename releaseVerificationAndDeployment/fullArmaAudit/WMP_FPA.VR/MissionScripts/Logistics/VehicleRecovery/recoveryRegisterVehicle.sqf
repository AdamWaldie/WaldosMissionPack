/* Registers a recoverable vehicle. Options: workshop key, damage, destroyed, engineer, package, cargo, restored fuel. */
params [
    ["_vehicle", objNull, [objNull]], ["_workshopKey", "MAIN", [""]],
    ["_minimumDamage", 0.55, [0]], ["_allowDestroyed", true, [true]],
    ["_requireEngineer", false, [true]], ["_packageClass", "B_Slingload_01_Cargo_F", [""]],
    ["_preserveCargo", true, [true]], ["_restoredFuel", 1, [0]]
];
if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")}) exitWith {false};
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_RecoveryRegisterVehicle", 2]; true};
private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {false};
if !(isClass (configFile >> "CfgVehicles" >> _packageClass)) then {_packageClass = "B_Slingload_01_Cargo_F"};
private _config = [toUpperANSI _workshopKey, (_minimumDamage max 0) min 1, _allowDestroyed, _requireEngineer, _packageClass, _preserveCargo, (_restoredFuel max 0) min 1];
_vehicle setVariable ["Waldo_Recovery_Config", _config, true];
_vehicle setVariable ["Waldo_Recovery_Registered", true, true];
[_vehicle] remoteExecCall ["Waldo_fnc_RecoverySetupVehicleLocal", 0, _vehicle];
true
