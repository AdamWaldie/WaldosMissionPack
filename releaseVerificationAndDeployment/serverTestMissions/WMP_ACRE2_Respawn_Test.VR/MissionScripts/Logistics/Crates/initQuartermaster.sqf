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

// A standalone quartermaster has no deployable MHQ to switch this state on later. Establish that
// server-owned state here so its visible actions and server-side crate validation agree. Calls
// made from an Eden init execute on the server already; a client-only custom call forwards once.
if (!_deploymentControlled) then {
    if (isServer) then {
        _target setVariable ["Waldo_QM_Standalone", true, true];
        _target setVariable ["Waldo_LogisticsQM_CurrentStatus", true, true];
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
    params ["_target", "_player"];
    (_target getVariable ["Waldo_LogisticsQM_CurrentStatus", false])
    && {alive _player}
    && {_player distance _target < 6}
    && {abs speed _target < 1}
    && {[_player, _target, []] call ace_common_fnc_canInteractWith}
};
private _statement = {
    params ["_target", "_player", "_args"];
    _args params ["_boxType", "_offsetDegrees", "_offsetDistance"];
    private _label = switch (_boxType) do {
        case "Medical": {"Retrieving Medical Box"};
        case "Ammo": {"Retrieving Ammo Box"};
        case "Supply": {"Retrieving Heavy Supply Box"};
        case "Track": {"Retrieving Spare Track"};
        default {"Retrieving Spare Wheel"};
    };
    [10, [_target, _player, _boxType, _offsetDegrees, _offsetDistance], {
        _args remoteExecCall ["Waldo_fnc_LogisticsSpawner", 2];
    }, {
        _args params ["_target", "_player", "_boxType"];
        [format ["%1 request cancelled.", _boxType], _player] call Waldo_fnc_DynamicText;
    }, _label] call ace_common_fnc_progressBar;
};

private _category = [
    "Waldo_QM_Category", "Logistics Quartermaster", _icon, {}, {true}
] call ace_interact_menu_fnc_createAction;
private _deployNotice = [
    "Waldo_QM_DeployPlease", "Set Up Command Post To Access", _icon, {},
    {!(_target getVariable ["Waldo_LogisticsQM_CurrentStatus", false])}
] call ace_interact_menu_fnc_createAction;

private _actions = [
    ["Waldo_QM_InitMedBox", "Retrieve Medical Box", "Medical"],
    ["Waldo_QM_InitAmmoBox", "Retrieve Ammo Box", "Ammo"],
    ["Waldo_QM_InitFullBox", "Retrieve Heavy Supply Box", "Supply"],
    ["Waldo_QM_InitTrack", "Retrieve Spare Track", "Track"],
    ["Waldo_QM_InitWheel", "Retrieve Spare Wheel", "Wheel"]
] apply {
    _x params ["_id", "_title", "_boxType"];
    [_id, _title, _icon, _statement, _condition, {}, [_boxType, _offsetDegrees, _offsetDistance], [0, 0, 0], 6]
        call ace_interact_menu_fnc_createAction
};

private _paths = [];
_paths pushBack ([_target, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject);
if (_deploymentControlled) then {
    _paths pushBack ([_target, 0, ["ACE_MainActions", "Waldo_QM_Category"], _deployNotice] call ace_interact_menu_fnc_addActionToObject);
};
{
    _paths pushBack ([_target, 0, ["ACE_MainActions", "Waldo_QM_Category"], _x] call ace_interact_menu_fnc_addActionToObject);
} forEach _actions;

_target setVariable ["Waldo_QM_ACEActionPaths", _paths];
_target setVariable ["Waldo_QM_LocalActionsInstalled", true];
diag_log format ["[WMP MHQ] Quartermaster ACE actions installed target=%1 count=%2 owner=%3", netId _target, count _paths, clientOwner];
true
