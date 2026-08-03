/*
 * Author: WaldoTheWarfighter
 * Installs the Virtual Vehicle Depot on an object. Setup is repeat-safe. ACE is the sole
 * interaction surface when loaded; the linked vanilla addAction route remains available by
 * default and calls the same authoritative handlers. The
 * selection UI remains local to its operator. Spawned vehicles are network objects, and
 * deletion is routed to their owning machine.
 *
 * [terminal, spawnPad, ["All"], ["ALL"], false, false, false, 10, ""] call Waldo_fnc_VVDInit;
 */

disableSerialization;
params [
    ["_depotSpawnerObject", objNull, [objNull]],
    ["_depotSpawnPoint", objNull, [objNull]],
    ["_types", ["Auto"], [[]]],
    ["_sidesToAllowUseOfSpawner", ["ALL"], [[]]],
    ["_enforcePlayerSideToAccess", false, [true]],
    ["_limitToSideVehicles", false, [true]],
    ["_removeUAVs", false, [true]],
    ["_range", 10, [0]],
    ["_script", "", [""]]
];

if (isNull _depotSpawnerObject || {isNull _depotSpawnPoint}) exitWith {
    diag_log "[WMP VVD] Setup rejected: terminal or spawn point is null.";
    false
};

private _groundTypes = ["Car", "Tank", "Helicopter", "Plane", "StaticWeapon"];
switch (toUpper (_types param [0, "AUTO"])) do {
    case "AUTO": {_types = [_groundTypes, ["Ship"]] select (surfaceIsWater (getPosATL _depotSpawnPoint));};
    case "GROUND": {_types = +_groundTypes;};
    case "ALL": {_types = ["Car", "Tank", "Helicopter", "Plane", "Ship", "StaticWeapon"];};
};

private _rawKey = vehicleVarName _depotSpawnPoint;
if (_rawKey == "") then {_rawKey = netId _depotSpawnPoint;};
if (_rawKey == "" || {_rawKey == "0:0"}) then {_rawKey = str _depotSpawnPoint;};
private _depotKey = ((_rawKey splitString ": .-") joinString "_");
_depotSpawnPoint setVariable ["Waldo_VVD_Key", _depotKey, true];
missionNamespace setVariable ["Garage_Script_" + _depotKey, _script];

if (!isServer && {!(_depotSpawnerObject getVariable ["Waldo_VVD_TerminalConfigured", false])}) then {
    [_depotSpawnerObject, _depotSpawnPoint, _types, _sidesToAllowUseOfSpawner, _enforcePlayerSideToAccess, _limitToSideVehicles, _removeUAVs, _range, _script]
        remoteExecCall ["Waldo_fnc_VVDInit", 2];
};

if (isServer) then {
    _depotSpawnerObject setVariable ["Waldo_VVD_TerminalConfigured", true, true];
    _depotSpawnerObject setVariable ["Waldo_VVD_SpawnPoint", _depotSpawnPoint, true];
    _depotSpawnerObject setVariable ["Waldo_VVD_UseRange", _range max 1, true];
    _depotSpawnPoint setVariable ["Waldo_VVD_Terminal", _depotSpawnerObject, true];
};
if (isServer && {!(_depotSpawnPoint getVariable ["Waldo_VVD_ServerConfigured", false])}) then {
    _depotSpawnPoint setVariable ["Waldo_VVD_ServerConfigured", true, true];
    private _markerDesign = "respawn_unknown";
    if (count _types == 1) then {
        _markerDesign = switch (_types select 0) do {
            case "Car": {"respawn_motor"};
            case "Tank": {"respawn_armor"};
            case "Helicopter": {"respawn_air"};
            case "Plane": {"respawn_plane"};
            case "Ship": {"respawn_naval"};
            default {"respawn_unknown"};
        };
    };
    private _rangeMarker = createMarker ["Waldo_VVD_" + _depotKey + "_Range", _depotSpawnPoint];
    _rangeMarker setMarkerShape "ELLIPSE";
    _rangeMarker setMarkerSize [10, 10];
    private _nameMarker = createMarker ["Waldo_VVD_" + _depotKey + "_Name", _depotSpawnPoint];
    _nameMarker setMarkerText "Virtual Vehicle Depot";
    _nameMarker setMarkerType _markerDesign;
};

if (isServer && {!(_depotSpawnerObject getVariable ["Waldo_VVD_ClientSetupPublished", false])}) then {
    _depotSpawnerObject setVariable ["Waldo_VVD_ClientSetupPublished", true, true];
    // Object-keyed JIP publication gives every current and future interface the
    // same local ACE or vanilla interaction setup. Target -2 excludes a
    // dedicated server and avoids recursively executing the publication branch.
    [_depotSpawnerObject, _depotSpawnPoint, _types, _sidesToAllowUseOfSpawner, _enforcePlayerSideToAccess, _limitToSideVehicles, _removeUAVs, _range, _script]
        remoteExecCall ["Waldo_fnc_VVDInit", -2, _depotSpawnerObject];
};

if (!hasInterface) exitWith {true};
if (_depotSpawnerObject getVariable ["Waldo_VVD_LocalActionsInstalled", false]) exitWith {true};

private _aceLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _aceAvailable = _aceLoaded
    && {!(isNil "ace_interact_menu_fnc_createAction")}
    && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
if (_aceLoaded && {!_aceAvailable}) exitWith {
    if !(_depotSpawnerObject getVariable ["Waldo_VVD_LocalSetupPending", false]) then {
        _depotSpawnerObject setVariable ["Waldo_VVD_LocalSetupPending", true];
        _this spawn {
            params ["_terminal"];
            waitUntil {
                uiSleep 0.1;
                isNull _terminal
                || {!(isNil "ace_interact_menu_fnc_createAction") && {!(isNil "ace_interact_menu_fnc_addActionToObject")}}
            };
            if (!isNull _terminal) then {
                _terminal setVariable ["Waldo_VVD_LocalSetupPending", false];
                _this call Waldo_fnc_VVDInit;
            };
        };
    };
    true
};
_depotSpawnerObject setVariable ["Waldo_VVD_LocalActionsInstalled", true];

private _arguments = [
    _depotSpawnPoint, _types, _sidesToAllowUseOfSpawner, _enforcePlayerSideToAccess,
    _limitToSideVehicles, _removeUAVs
];

private _open = {
    params ["_target", "_actor", "_arguments"];
    _arguments params ["_spawnPoint", "_types", "_allowedSides", "_enforceSide", "_sideLimit", "_removeUAVs"];
    private _sideText = switch (side group _actor) do {
        case west: {"BLUFOR"}; case east: {"OPFOR"}; case independent: {"INDEP"};
        case civilian: {"CIV"}; default {"NONE"};
    };
    if (_enforceSide && {!("ALL" in _allowedSides)} && {!(_sideText in _allowedSides)}) exitWith {
        ["This depot is not available to your side."] call BIS_fnc_guiMessage;
    };
    _target setVariable ["Waldo_VVD_LastLocalAction", ["OPEN", _actor, diag_tickTime]];
    diag_log format ["[WMP VVD] Open action invoked terminal=%1 pad=%2 actor=%3 owner=%4", netId _target, netId _spawnPoint, name _actor, clientOwner];
    [_target, _spawnPoint, _types, _sideLimit, _removeUAVs, _actor] call Waldo_fnc_VVDRequestOpenServer;
};

private _purge = {
    params ["_target", "_actor", "_spawnPoint"];
    _target setVariable ["Waldo_VVD_LastLocalAction", ["PURGE", _actor, diag_tickTime]];
    diag_log format ["[WMP VVD] Purge action invoked terminal=%1 pad=%2 actor=%3 owner=%4", netId _target, netId _spawnPoint, name _actor, clientOwner];
    private _vehicles = (_spawnPoint nearObjects ["AllVehicles", 10]) + (_spawnPoint nearObjects ["#particlesource", 20]);
    {
        private _defaultVehicle = "DFV" in ((vehicleVarName _x) splitString "_");
        if (!(_x isKindOf "Man") && {!_defaultVehicle}) then {[_x] call Waldo_fnc_VVDPurgeVehicle;};
    } forEach _vehicles;
};

if (_aceAvailable) then {
    private _category = ["Waldo_VVD_Category", "Virtual Vehicle Depot", "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\car_ca.paa", {true}, {true}] call ace_interact_menu_fnc_createAction;
    private _openAction = ["Waldo_VVD_Open", "Open Vehicle Garage", "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\car_ca.paa", _open, {true}, {}, _arguments] call ace_interact_menu_fnc_createAction;
    private _purgeAction = ["Waldo_VVD_Purge", "Clear Depot Spawn Area", "\a3\ui_f\data\IGUI\Cfg\Actions\ico_off_ca.paa", _purge, {true}, {}, _depotSpawnPoint] call ace_interact_menu_fnc_createAction;
    private _categoryPath = [_depotSpawnerObject, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject;
    private _openPath = [_depotSpawnerObject, 0, ["ACE_MainActions", "Waldo_VVD_Category"], _openAction] call ace_interact_menu_fnc_addActionToObject;
    private _purgePath = [_depotSpawnerObject, 0, ["ACE_MainActions", "Waldo_VVD_Category"], _purgeAction] call ace_interact_menu_fnc_addActionToObject;
    _depotSpawnerObject setVariable ["Waldo_VVD_ACEActionsInstalled", true];
    _depotSpawnerObject setVariable ["Waldo_VVD_ACEActionPaths", [_categoryPath, _openPath, _purgePath]];
    _depotSpawnerObject setVariable ["Waldo_VVD_ACEActions", [_category, _openAction, _purgeAction]];
};

if (!_aceAvailable && {!(_depotSpawnerObject getVariable ["Waldo_VVD_VanillaActionsInstalled", false])}) then {
    private _openId = _depotSpawnerObject addAction [
        "<t color='#FFFF00'>Open Vehicle Garage</t>",
        {
            params ["_target", "_actor", "_actionId", "_payload"];
            _payload params ["_handler", "_arguments"];
            [_target, _actor, _arguments] call _handler;
        },
        [_open, _arguments], 1.5, true, true, "", "true", _range
    ];
    private _purgeId = _depotSpawnerObject addAction [
        "<t color='#00FFFF'>Clear Depot Spawn Area</t>",
        {
            params ["_target", "_actor", "_actionId", "_payload"];
            _payload params ["_handler", "_spawnPoint"];
            [_target, _actor, _spawnPoint] call _handler;
        },
        [_purge, _depotSpawnPoint], 1.5, true, true, "", "true", _range
    ];
    _depotSpawnerObject setVariable ["Waldo_VVD_VanillaActionIds", [_openId, _purgeId]];
    _depotSpawnerObject setVariable ["Waldo_VVD_VanillaActionsInstalled", true];
};

private _interactionMode = if (_aceAvailable) then {"ACE"} else {"VANILLA"};
_depotSpawnerObject setVariable ["Waldo_VVD_InteractionMode", _interactionMode];
diag_log format ["[WMP VVD] Actions installed terminal=%1 pad=%2 key=%3 mode=%4", netId _depotSpawnerObject, netId _depotSpawnPoint, _depotKey, _interactionMode];
true
