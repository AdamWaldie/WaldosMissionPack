/*
 * Author: WaldoTheWarfighter
 * Purpose: Issues optional dynamic grenade/explosive, ACE rearm and ACE fuel supplies at a QM.
 * Locality / Authority: Server only; validates the player, object, issue flag and class again.
 * Repeat / JIP: Each request creates one world object; ACE source state and crate cargo replicate.
 * Arguments: target <OBJECT>, player <OBJECT>, type <STRING>, bearing <NUMBER> (90), distance <NUMBER> (2).
 * Return Value: <BOOL> spawned. Current caller: Waldo_fnc_LogisticsSpawner.
 * Example: [quartermaster, player, "Rearm", 90, 3] remoteExecCall ["Waldo_fnc_LogisticsSpawner", 2];
 */
params [["_target", objNull, [objNull]], ["_player", objNull, [objNull]], ["_kind", "", [""]],
    ["_bearing", 90, [0]], ["_distance", 2, [0]]];
if (!isServer || {isNull _target} || {isNull _player} || {!alive _player}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_Quartermaster_Enable", true]) exitWith {false};
if !(_target getVariable ["Waldo_LogisticsQM_CurrentStatus", false]) exitWith {false};
if (_player distance _target > 6 || {abs speed _target >= 1}) exitWith {false};
private _config = switch (_kind) do {
    case "Grenades": {["Waldo_QM_Grenades_Enable", "Box_NATO_Ammo_F"]};
    case "Explosives": {["Waldo_QM_Explosives_Enable", "Box_NATO_AmmoOrd_F"]};
    case "Rearm": {["Waldo_QM_Rearm_Enable", "Box_NATO_AmmoVeh_F"]};
    case "VehicleRearm": {["Waldo_QM_VehicleRearm_Enable", "Box_NATO_AmmoVeh_F"]};
    case "StaticRearm": {["Waldo_QM_StaticRearm_Enable", "Box_NATO_AmmoVeh_F"]};
    case "FuelBarrel": {["Waldo_QM_FuelBarrel_Enable", "Land_MetalBarrel_F"]};
    case "FuelJerrycan": {["Waldo_QM_FuelJerrycan_Enable", "Land_CanisterFuel_F"]};
    default {[]};
};
private _isRearm = _kind in ["Rearm", "VehicleRearm", "StaticRearm"];
private _rearmEnabled = missionNamespace getVariable ["Waldo_QM_Rearm_Enable", false]
    || {missionNamespace getVariable ["Waldo_QM_VehicleRearm_Enable", false]}
    || {missionNamespace getVariable ["Waldo_QM_StaticRearm_Enable", false]};
if (_config isEqualTo []) exitWith {false};
private _issueEnabled = if (_kind == "Rearm") then {_rearmEnabled} else {
    missionNamespace getVariable [_config select 0, false]
};
if (!_issueEnabled) exitWith {false};
if !(_kind in (_target getVariable ["Waldo_QM_AllowedKinds",
    ["Medical", "Ammo", "Supply", "Track", "Wheel", "Grenades", "Explosives", "Rearm", "FuelBarrel", "FuelJerrycan"]])) exitWith {false};
if (_isRearm && {isNil "ace_rearm_fnc_makeSource"}) exitWith {false};
// ACE's specific-magazine mode needs separately stocked magazine classes. An
// intentionally empty QM shell only supports ACE's limited and unlimited modes.
if (_isRearm && {!((missionNamespace getVariable ["ace_rearm_supply", 0]) in [0, 1])}) exitWith {false};
if (_kind == "FuelBarrel" && {isNil "ace_refuel_fnc_makeSource"}) exitWith {false};
if (_kind == "FuelJerrycan" && {isNil "ace_refuel_fnc_makeJerryCan"}) exitWith {false};
private _dynamicMagazines = [];
if (_kind in ["Grenades", "Explosives"]) then {
    private _pool = [side _player] call Waldo_fnc_GetSideLoadoutArray;
    if (count _pool >= 6) then {
        private _candidates = ((_pool select 1) + (_pool select 5)) arrayIntersect ((_pool select 1) + (_pool select 5));
        {
            if (isClass (configFile >> "CfgMagazines" >> _x)) then {
                private _itemType = _x call BIS_fnc_itemType;
                if (if (_kind == "Grenades") then {_x call BIS_fnc_isThrowable}
                    else {(_itemType param [0, ""]) isEqualTo "Mine"}) then {
                    _dynamicMagazines pushBack _x;
                };
            };
        } forEach _candidates;
    };
};
if (_kind in ["Grenades", "Explosives"] && {_dynamicMagazines isEqualTo []}) exitWith {false};
private _class = missionNamespace getVariable [format ["Waldo_QM_%1_CrateClass", _kind], _config select 1];
if (_kind in ["Grenades", "Explosives"] || {_isRearm}) then {
    private _sidePrefix = switch (side _player) do {
        case east: {"East"};
        case independent: {"IND"};
        default {"NATO"};
    };
    private _suffix = if (_kind == "Grenades") then {"Ammo_F"} else {
        if (_kind == "Explosives") then {"AmmoOrd_F"} else {"AmmoVeh_F"}
    };
    private _sideClass = format ["Box_%1_%2", _sidePrefix, _suffix];
    // Side variants are a fallback only; a mission-maker's per-type class wins.
    if (_class isEqualTo (_config select 1) && {isClass (configFile >> "CfgVehicles" >> _sideClass)}) then {_class = _sideClass};
};
if !(isClass (configFile >> "CfgVehicles" >> _class)) exitWith {false};
private _base = [_target, _distance max 2, getDir _target + _bearing] call BIS_fnc_relPos;
private _position = _base findEmptyPosition [0, 5, _class];
if (_position isEqualTo []) exitWith {
    ["Clear some room before requesting another supply.", _player, "QUARTERMASTER"] call Waldo_fnc_DynamicText;
    false
};
private _object = _class createVehicle _position;
_object setPosATL _position;
private _issueName = switch (_kind) do {
    case "Grenades": {"Grenades Box"};
    case "Explosives": {"Explosives Box"};
    case "Rearm";
    case "VehicleRearm";
    case "StaticRearm": {"Rearm Box"};
    case "FuelBarrel": {"Fuel Barrel"};
    case "FuelJerrycan": {"Fuel Jerrycan"};
};
// ACE appends this name to the model's generic class name in cargo menus.
// Keep the quartermaster issue identity visible after the object is spawned.
_object setVariable ["ace_cargo_customName", _issueName, true];
_object setVariable ["Waldo_QM_IssueName", _issueName, true];
if (_kind in ["Grenades", "Explosives"] || {_isRearm}) then {
    clearWeaponCargoGlobal _object;
    clearMagazineCargoGlobal _object;
    clearItemCargoGlobal _object;
    clearBackpackCargoGlobal _object;
};
if (_kind in ["Grenades", "Explosives"]) then {
    {
        private _count = missionNamespace getVariable [format ["Waldo_QM_%1_CountPerType", _kind], 8];
        _object addMagazineCargoGlobal [_x, (_count max 1) min 100];
    } forEach _dynamicMagazines;
};
if (_isRearm && {!isNil "ace_rearm_fnc_makeSource"}) then {
    private _configuredSupply = switch (_kind) do {
        case "VehicleRearm": {missionNamespace getVariable ["Waldo_QM_VehicleRearm_Supply", 1200]};
        case "StaticRearm": {missionNamespace getVariable ["Waldo_QM_StaticRearm_Supply", 250]};
        default {
            if (missionNamespace getVariable ["Waldo_QM_Rearm_Enable", false]) then {
                missionNamespace getVariable ["Waldo_QM_Rearm_Supply", 1200]
            } else {
                if (missionNamespace getVariable ["Waldo_QM_VehicleRearm_Enable", false]) then {
                    missionNamespace getVariable ["Waldo_QM_VehicleRearm_Supply", 1200]
                } else {missionNamespace getVariable ["Waldo_QM_StaticRearm_Supply", 250]}
            }
        };
    };
    // ACE's supply setting is mission-wide. In limited mode it consumes these
    // points; in unlimited mode a numeric count would mislead players.
    private _limited = (missionNamespace getVariable ["ace_rearm_supply", 0]) == 1;
    private _supply = if (_limited) then {(_configuredSupply max 1) min 100000} else {0};
    [_object, _supply] call ace_rearm_fnc_makeSource;
    [_object] remoteExecCall ["Waldo_fnc_QuartermasterRearmLabelLocal", 0, _object];
};
if (_kind == "FuelBarrel" && {!isNil "ace_refuel_fnc_makeSource"}) then {
    [_object, (missionNamespace getVariable ["Waldo_QM_FuelBarrel_Litres", 200]) max 1] call ace_refuel_fnc_makeSource;
};
if (_kind == "FuelJerrycan") then {
    [_object, (missionNamespace getVariable ["Waldo_QM_FuelJerrycan_Litres", 20]) max 1]
        remoteExecCall ["Waldo_fnc_QuartermasterMakeJerrycanLocal", 0, _object];
};
// A spawned child of a remote-executed request keeps isRemoteExecuted, which the server-only
// cargo/registration guards reject. Finish from CBA's server-local next frame instead.
// QM issues are one ACE cargo slot each, always drag/carryable regardless of mass; fuel and
// rearm behaviour is separate. Both calls reject this request's remote context, so they run here.
[{
    [_this select 0, -1, 1, true, true, true, true] call Waldo_fnc_SetCargoAttributes;
    _this spawn Waldo_fnc_LogisticsRegisterSpawned;
}, [_object, if (_isRearm) then {"REARM"} else {_kind}]] call CBA_fnc_execNextFrame;
diag_log format ["[WMP QM] Extended issue kind=%1 name=%2 class=%3 player=%4",
    _kind, _issueName, _class, name _player];
[format ["%1 ready for collection.", _issueName], _player, "QUARTERMASTER"] call Waldo_fnc_DynamicText;
true
