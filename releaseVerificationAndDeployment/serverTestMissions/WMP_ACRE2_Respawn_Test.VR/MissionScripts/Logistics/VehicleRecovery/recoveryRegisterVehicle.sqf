/*
 * Author: WaldoTheWarfighter
 * Registers a vehicle for server-authoritative recovery and optionally hooks a shared preparation
 * procedure into the existing package action. Configuration and interaction settings are broadcast
 * before object-keyed JIP setup, so current and joining clients receive a consistent action while
 * the server retains the completion callback.
 *
 * Arguments:
 * 0: vehicle <OBJECT>
 * 1: workshop key <STRING> (default "MAIN")
 * 2: minimum damage <NUMBER> (default 0.55)
 * 3: allow destroyed <BOOL> (default true)
 * 4: require engineer <BOOL> (default false)
 * 5: package class <STRING> (default first valid `Waldo_Recovery_PackageClasses` entry)
 * 6: preserve cargo <BOOL> (default true)
 * 7: restored fuel <NUMBER> (default 1)
 * 8: interaction options <ARRAY or HASHMAP> - optional `enabled`, `challengeId`, `difficulty`;
 *      semantic default is the repair procedure at standard difficulty
 *
 * Return Value:
 * Boolean - true when forwarded or registered
 *
 * Called by:
 * Vehicle Recovery ZEN registration, audit fixtures and mission-maker scripts.
 *
 * Example:
 * [this, "MAIN", 0.55, true, true, "B_Slingload_01_Cargo_F", true, 1,
 *  createHashMapFromArray [["enabled", true]]] call Waldo_fnc_RecoveryRegisterVehicle;
 */

params [
    ["_vehicle", objNull, [objNull]], ["_workshopKey", "MAIN", [""]],
    ["_minimumDamage", 0.55, [0]], ["_allowDestroyed", true, [true]],
    ["_requireEngineer", false, [true]], ["_packageClass", (missionNamespace getVariable ["Waldo_Recovery_PackageClasses", ["B_Slingload_01_Cargo_F"]]) param [0, "B_Slingload_01_Cargo_F"], [""]],
    ["_preserveCargo", true, [true]], ["_restoredFuel", 1, [0]],
    ["_interactionOptions", [], [[], createHashMap]]
];
if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")} || {_vehicle isKindOf "CAManBase"}) exitWith {false};
if (!isServer) exitWith {
    private _forward = _interactionOptions;
    if (typeName _forward == "HASHMAP") then {private _pairs = []; {_pairs pushBack [_x, _forward get _x]} forEach keys _forward; _forward = _pairs};
    [_vehicle, _workshopKey, _minimumDamage, _allowDestroyed, _requireEngineer, _packageClass, _preserveCargo, _restoredFuel, _forward]
        remoteExecCall ["Waldo_fnc_RecoveryRegisterVehicle", 2];
    true
};
private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {false};
if !(isClass (configFile >> "CfgVehicles" >> _packageClass)) then {
    private _configuredPackages = (missionNamespace getVariable ["Waldo_Recovery_PackageClasses", ["B_Slingload_01_Cargo_F"]]) select {
        _x isEqualType "" && {isClass (configFile >> "CfgVehicles" >> _x)}
    };
    _packageClass = _configuredPackages param [0, "B_Slingload_01_Cargo_F"];
};
private _config = [toUpperANSI _workshopKey, (_minimumDamage max 0) min 1, _allowDestroyed, _requireEngineer, _packageClass, _preserveCargo, (_restoredFuel max 0) min 1];
private _pairs = [];
if (typeName _interactionOptions == "HASHMAP") then {{_pairs pushBack [_x, _interactionOptions get _x]} forEach keys _interactionOptions} else {_pairs = _interactionOptions};
private _getOption = {params ["_key", "_default"]; private _value = _default; {if ((_x param [0, ""]) == _key) exitWith {_value = _x param [1, _default]}} forEach _pairs; _value};
private _interactionEnabled = ["enabled", false] call _getOption;
private _challengeId = ["challengeId", "repair"] call _getOption;
private _difficulty = ["difficulty", "standard"] call _getOption;
_config pushBack [_interactionEnabled, _challengeId, _difficulty];
_vehicle setVariable ["Waldo_Recovery_Config", _config, true];
_vehicle setVariable ["Waldo_Recovery_Registered", true, true];
_vehicle setVariable ["Waldo_Recovery_InteractionEnabled", _interactionEnabled, true];
if (_interactionEnabled && {!isNil "Waldo_fnc_MiniGameInteractionReset"} && {!isNil {_vehicle getVariable "Waldo_MG_InteractionState"}}) then {
    [_vehicle, true, false] call Waldo_fnc_MiniGameInteractionReset;
};
if (!_interactionEnabled && {!isNil {_vehicle getVariable "Waldo_MG_Int_Active"}}) then {
    _vehicle setVariable ["Waldo_MG_Int_Active", false, true];
};
[_vehicle, if (_interactionEnabled) then {[_challengeId, _difficulty]} else {[]}]
    remoteExecCall ["Waldo_fnc_RecoverySetupVehicleLocal", 0, _vehicle];
true
