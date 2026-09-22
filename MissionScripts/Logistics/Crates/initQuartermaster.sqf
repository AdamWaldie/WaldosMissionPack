/*
 * Author: WaldoTheWarfighter
 * Installs Logistics Quartermaster actions on an object or NPC. A normal standalone
 * quartermaster is made available immediately. An MHQ passes deploymentControlled=true so its
 * server-owned deploy/tear-down state decides when the quartermaster actions become available.
 * The call is safe in an Eden object init: the server publishes standalone availability and every
 * interface installs its own ACE actions (or vanilla addActions when ACE is absent). JIP clients
 * receive the object state and repeat-safe local actions. Crate requests are always validated and
 * spawned by the server through Waldo_fnc_LogisticsSpawner.
 *
 * Arguments:
 * 0: target <OBJECT> - object or NPC that players interact with.
 * 1: spawn bearing <NUMBER> (default 90) - degrees relative to the target; 0 front, 90 right.
 * 2: spawn distance <NUMBER> (default 2) - starting distance from the target in metres.
 * 3: deployment controlled <BOOL> (default false) - false for a standalone quartermaster; true
 *    only when another system such as the WMP MHQ owns its active/inactive state.
 *
 * Return Value: <BOOL> - true when server state or local actions were handled.
 *
 * Example:
 * [this, 0, 4] call Waldo_fnc_SetupQuarterMaster; // always-available standalone point, 4 m ahead.
 * Current callers: Eden composition/object init and Waldo_fnc_MHQSetupLocal.
 */
params [
    ["_target", objNull, [objNull]],
    ["_offsetDegrees", 90, [0]],
    ["_offsetDistance", 2, [0]],
    ["_deploymentControlled", false, [false]]
];

if (isNull _target) exitWith {false};
if !(missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]) exitWith {
    [_target, _offsetDegrees, _offsetDistance, _deploymentControlled] spawn {
        params ["_target", "_offsetDegrees", "_offsetDistance", "_deploymentControlled"];
        waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false] || {isNull _target}};
        if (!isNull _target) then {
            [_target, _offsetDegrees, _offsetDistance, _deploymentControlled] call Waldo_fnc_SetupQuarterMaster;
        };
    };
    true
};
if !(missionNamespace getVariable ["Waldo_Quartermaster_Enable", true]) exitWith {false};
// Keep script/composition-created points inspectable by ZEN with their actual placement and
// controller mode. This is state, not a second setup pass on joining clients.
if (isServer) then {
    _target setVariable ["Waldo_QM_SetupSettings", [_offsetDegrees, _offsetDistance, _deploymentControlled], true];
};

private _allowedKinds = _target getVariable ["Waldo_QM_AllowedKinds",
    ["Medical", "Ammo", "Supply", "Track", "Wheel", "Grenades", "Explosives", "Rearm", "FuelBarrel", "FuelJerrycan"]];
if (_deploymentControlled && {isServer} && {_target getVariable ["Waldo_QM_Standalone", false]}) then {
    _target setVariable ["Waldo_QM_Standalone", false, true];
    _target setVariable ["Waldo_LogisticsQM_CurrentStatus", false, true];
    ["WMP_QM_" + netId _target] call Waldo_fnc_Remove3DMarker;
};

// A standalone quartermaster has no deployable MHQ to switch this state on later. Establish that
// server-owned state here so its visible actions and server-side crate validation agree. Calls
// made from an Eden init execute on the server already; a client-only custom call forwards once.
if (!_deploymentControlled) then {
    if (isServer) then {
        _target setVariable ["Waldo_QM_Standalone", true, true];
        _target setVariable ["Waldo_LogisticsQM_CurrentStatus", true, true];
        ["WMP_QM_" + netId _target, _target, createHashMapFromArray [
            ["text", "Quartermaster"],
            ["icon", "\a3\ui_f\data\igui\cfg\simpletasks\types\Box_ca.paa"],
            ["offset", [0, 0, 1.5]], ["distance", 25]
        ]] call Waldo_fnc_Create3DMarker;
    } else {
        if !(_target getVariable ["Waldo_QM_StandaloneActivationRequested", false]) then {
            _target setVariable ["Waldo_QM_StandaloneActivationRequested", true];
            [_target, _offsetDegrees, _offsetDistance, false] remoteExecCall ["Waldo_fnc_SetupQuarterMaster", 2];
        };
    };
};

if (!hasInterface) exitWith {true};

// Keep the point identifiable even in ACE missions, where functional retrieval lives in the ACE
// interaction tree rather than Arma's action menu. Informational addActions use the shared WMP blue.
if (isNil {_target getVariable "Waldo_QM_InfoActionId"}) then {
    private _infoId = _target addAction [
        "<t color='#79C7FF'>Logistics Quartermaster</t>",
        {
            params ["_target", "_player"];
            private _ace = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
            [
                "LOGISTICS QUARTERMASTER",
                ["Use the action menu to retrieve available stores.", "Use ACE Interact on this point to retrieve available stores."] select _ace,
                "INFO",
                format ["QUARTERMASTER_INFO_%1", netId _target],
                6
            ] call Waldo_fnc_FeatureNotifyLocal;
        },
        [], 1.5, true, false, "",
        "alive _this && {_this distance _target < 6}",
        6
    ];
    _target setVariable ["Waldo_QM_InfoActionId", _infoId];
};
if (_target getVariable ["Waldo_QM_LocalActionsInstalled", false]) exitWith {true};

private _aceLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _aceReady = _aceLoaded
    && {!(isNil "ace_interact_menu_fnc_createAction")}
    && {!(isNil "ace_interact_menu_fnc_addActionToObject")}
    && {!(isNil "ace_common_fnc_progressBar")};
if (_aceLoaded && {!_aceReady}) exitWith {
    if !(_target getVariable ["Waldo_QM_LocalSetupPending", false]) then {
        _target setVariable ["Waldo_QM_LocalSetupPending", true];
        [_target, _offsetDegrees, _offsetDistance, _deploymentControlled] spawn {
            params ["_target", "_offsetDegrees", "_offsetDistance", "_deploymentControlled"];
            waitUntil {uiSleep 0.1; isNull _target || {!(isNil "ace_interact_menu_fnc_createAction")}};
            if (!isNull _target) then {
                _target setVariable ["Waldo_QM_LocalSetupPending", false];
                [_target, _offsetDegrees, _offsetDistance, _deploymentControlled] call Waldo_fnc_SetupQuarterMaster;
            };
        };
    };
    false
};

if (!_aceReady) exitWith {
    private _vanillaActions = [
        ["Retrieve Medical Box", "Medical"],
        ["Retrieve Ammo Box", "Ammo"],
        ["Retrieve Heavy Supply Box", "Supply"],
        ["Retrieve Spare Track", "Track"],
        ["Retrieve Spare Wheel", "Wheel"]
    ] select {missionNamespace getVariable [format ["Waldo_QM_%1_Enable", _x select 1], true]
        && {(_x select 1) in _allowedKinds}};
    if ("Rearm" in _allowedKinds && {missionNamespace getVariable ["Waldo_QM_Rearm_Enable", false]
        || {missionNamespace getVariable ["Waldo_QM_VehicleRearm_Enable", false]}
        || {missionNamespace getVariable ["Waldo_QM_StaticRearm_Enable", false]}}) then {
        _vanillaActions pushBack ["Retrieve Rearm Box", "Rearm"];
    };
    {
        _x params ["_flag", "_label", "_kind"];
        if (_kind in _allowedKinds && {missionNamespace getVariable [_flag, false]}) then {
            _vanillaActions pushBack [_label, _kind]
        };
    } forEach [
        ["Waldo_QM_Grenades_Enable", "Retrieve Grenades Box", "Grenades"],
        ["Waldo_QM_Explosives_Enable", "Retrieve Explosives Box", "Explosives"],
        ["Waldo_QM_FuelBarrel_Enable", "Retrieve Fuel Barrel", "FuelBarrel"],
        ["Waldo_QM_FuelJerrycan_Enable", "Retrieve Fuel Jerrycan", "FuelJerrycan"]
    ];
    private _ids = _vanillaActions apply {
        _x params ["_title", "_boxType"];
        _target addAction [
            _title,
            {
                params ["_target", "_player", "_actionId", "_arguments"];
                _arguments params ["_boxType", "_offsetDegrees", "_offsetDistance"];
                [_target, _player, _boxType, _offsetDegrees, _offsetDistance]
                    remoteExecCall ["Waldo_fnc_LogisticsSpawner", 2];
            },
            [_boxType, _offsetDegrees, _offsetDistance],
            1.5, true, true, "",
            "(_target getVariable ['Waldo_LogisticsQM_CurrentStatus', false]) && {alive _this} && {_this distance _target < 6} && {abs speed _target < 1}",
            6
        ]
    };
    _target setVariable ["Waldo_QM_VanillaActionIds", _ids];
    _target setVariable ["Waldo_QM_LocalActionsInstalled", true];
    diag_log format ["[WMP MHQ] Quartermaster vanilla fallback installed target=%1 count=%2 owner=%3", netId _target, count _ids, clientOwner];
    true
};

private _icon = "\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa";
private _condition = {
    params ["_target", "_player", "_args"];
    private _kind = _args param [0, ""];
    private _available = true;
    if (_kind in ["Grenades", "Explosives"]) then {
        _available = false;
        private _pool = [side _player] call Waldo_fnc_GetSideLoadoutArray;
        if (count _pool >= 6) then {
            {
                if (isClass (configFile >> "CfgMagazines" >> _x)) then {
                    private _itemType = _x call BIS_fnc_itemType;
                    if (if (_kind == "Grenades") then {_x call BIS_fnc_isThrowable}
                        else {(_itemType param [0, ""]) isEqualTo "Mine"}) exitWith {
                        _available = true;
                    };
                };
            } forEach ((_pool select 1) + (_pool select 5));
        };
    };
    if !(_kind in (_target getVariable ["Waldo_QM_AllowedKinds",
        ["Medical", "Ammo", "Supply", "Track", "Wheel", "Grenades", "Explosives", "Rearm", "FuelBarrel", "FuelJerrycan"]])) then {
        _available = false
    };
    if (_kind == "Rearm" && {isNil "ace_rearm_fnc_makeSource"}) then {_available = false};
    if (_kind == "FuelBarrel" && {isNil "ace_refuel_fnc_makeSource"}) then {_available = false};
    if (_kind == "FuelJerrycan" && {isNil "ace_refuel_fnc_makeJerryCan"}) then {_available = false};
    (_target getVariable ["Waldo_LogisticsQM_CurrentStatus", false])
    && {_available}
    && {alive _player}
    && {_player distance _target < 6}
    && {abs speed _target < 1}
    && {[_player, _target, []] call ace_common_fnc_canInteractWith}
};
private _statement = {
    params ["_target", "_player", "_args"];
    _args params ["_boxType", "_offsetDegrees", "_offsetDistance", "_title"];
    [10, [_target, _player, _boxType, _offsetDegrees, _offsetDistance], {
        _args remoteExecCall ["Waldo_fnc_LogisticsSpawner", 2];
    }, {
        _args params ["_target", "_player", "_boxType"];
        [format ["%1 request cancelled.", _boxType], _player, "QUARTERMASTER"] call Waldo_fnc_DynamicText;
    }, _title] call ace_common_fnc_progressBar;
};

private _category = [
    "Waldo_QM_Category", "Logistics Quartermaster", _icon, {}, {true}
] call ace_interact_menu_fnc_createAction;
private _deployNotice = [
    "Waldo_QM_DeployPlease", "Set Up Command Post To Access", _icon, {},
    {!(_target getVariable ["Waldo_LogisticsQM_CurrentStatus", false])}
] call ace_interact_menu_fnc_createAction;

private _actionSpecs = [
    ["Waldo_QM_InitMedBox", "Retrieve Medical Box", "Medical"],
    ["Waldo_QM_InitAmmoBox", "Retrieve Ammo Box", "Ammo"],
    ["Waldo_QM_InitFullBox", "Retrieve Heavy Supply Box", "Supply"],
    ["Waldo_QM_InitTrack", "Retrieve Spare Track", "Track"],
    ["Waldo_QM_InitWheel", "Retrieve Spare Wheel", "Wheel"]
] select {missionNamespace getVariable [format ["Waldo_QM_%1_Enable", _x select 2], true]
    && {(_x select 2) in _allowedKinds}};
if ("Rearm" in _allowedKinds && {missionNamespace getVariable ["Waldo_QM_Rearm_Enable", false]
    || {missionNamespace getVariable ["Waldo_QM_VehicleRearm_Enable", false]}
    || {missionNamespace getVariable ["Waldo_QM_StaticRearm_Enable", false]}}) then {
    _actionSpecs pushBack ["Waldo_QM_Rearm", "Retrieve Rearm Box", "Rearm"];
};
{
    _x params ["_flag", "_id", "_label", "_kind"];
    if (_kind in _allowedKinds && {missionNamespace getVariable [_flag, false]}) then {
        _actionSpecs pushBack [_id, _label, _kind]
    };
} forEach [
    ["Waldo_QM_Grenades_Enable", "Waldo_QM_Grenades", "Retrieve Grenades Box", "Grenades"],
    ["Waldo_QM_Explosives_Enable", "Waldo_QM_Explosives", "Retrieve Explosives Box", "Explosives"],
    ["Waldo_QM_FuelBarrel_Enable", "Waldo_QM_FuelBarrel", "Retrieve Fuel Barrel", "FuelBarrel"],
    ["Waldo_QM_FuelJerrycan_Enable", "Waldo_QM_FuelJerrycan", "Retrieve Fuel Jerrycan", "FuelJerrycan"]
];
private _actions = _actionSpecs apply {
    _x params ["_id", "_title", "_boxType"];
    [[_id, _title, _icon, _statement, _condition, {},
        [_boxType, _offsetDegrees, _offsetDistance, _title], [0, 0, 0], 6]
        call ace_interact_menu_fnc_createAction, _boxType]
};

private _paths = [];
_paths pushBack ([_target, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject);
private _infantry = ["Waldo_QM_Infantry", "Infantry Supplies", _icon, {}, {true}]
    call ace_interact_menu_fnc_createAction;
private _vehicle = ["Waldo_QM_Vehicle", "Vehicle Support", "\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa", {}, {true}]
    call ace_interact_menu_fnc_createAction;
_paths pushBack ([_target, 0, ["ACE_MainActions", "Waldo_QM_Category"], _infantry] call ace_interact_menu_fnc_addActionToObject);
_paths pushBack ([_target, 0, ["ACE_MainActions", "Waldo_QM_Category"], _vehicle] call ace_interact_menu_fnc_addActionToObject);
private _hasFuel = missionNamespace getVariable ["Waldo_QM_FuelBarrel_Enable", false]
    && {"FuelBarrel" in _allowedKinds}
    || {missionNamespace getVariable ["Waldo_QM_FuelJerrycan_Enable", false] && {"FuelJerrycan" in _allowedKinds}};
if (_hasFuel) then {
    private _fuel = ["Waldo_QM_Fuel", "Fuel", "\a3\ui_f\data\map\mapcontrol\Fuelstation_CA.paa", {}, {true}]
        call ace_interact_menu_fnc_createAction;
    _paths pushBack ([_target, 0, ["ACE_MainActions", "Waldo_QM_Category"], _fuel] call ace_interact_menu_fnc_addActionToObject);
};
if (_deploymentControlled) then {
    _paths pushBack ([_target, 0, ["ACE_MainActions", "Waldo_QM_Category"], _deployNotice] call ace_interact_menu_fnc_addActionToObject);
};
{
    _x params ["_action", "_boxType"];
    private _branch = if (_boxType in ["Medical", "Ammo", "Supply", "Grenades", "Explosives"]) then {
        "Waldo_QM_Infantry"
    } else {if (_boxType in ["FuelBarrel", "FuelJerrycan"]) then {"Waldo_QM_Fuel"} else {"Waldo_QM_Vehicle"}};
    _paths pushBack ([_target, 0, ["ACE_MainActions", "Waldo_QM_Category", _branch], _action]
        call ace_interact_menu_fnc_addActionToObject);
} forEach _actions;

_target setVariable ["Waldo_QM_ACEActionPaths", _paths];
_target setVariable ["Waldo_QM_LocalActionsInstalled", true];
diag_log format ["[WMP MHQ] Quartermaster ACE actions installed target=%1 count=%2 owner=%3", netId _target, count _paths, clientOwner];
true
