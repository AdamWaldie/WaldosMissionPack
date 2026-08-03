/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe local Field Resupply carrier controls on the current player.
 *
 * ACE clients receive a Field Resupply category containing the inspect and deploy controls.
 * Clients without ACE Interact receive equivalent scroll-wheel actions. Conditions mirror the
 * authoritative server rules: the player must be an assigned carrier, wear a backpack and be on
 * foot; deployment additionally requires at least one carried crate. The function is safe to call
 * again after assignment, runtime activation, JIP or respawn and never publishes authoritative
 * carrier state from the client.
 *
 * Arguments: None.
 *
 * Return Value:
 * Boolean - true when controls already exist or were installed; false when unavailable/disabled.
 *
 * Example:
 * [] call Waldo_fnc_FieldResupplyInit;
 *
 * Current callers: initPlayerLocal.sqf, FieldResupplyAssignCarrier and the local respawn handler.
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {
            [] call Waldo_fnc_FieldResupplyInit;
        };
    };
    true
};
if !(missionNamespace getVariable ["Waldo_FieldResupply_Enable", false]) exitWith {false};
if (player getVariable ["Waldo_FieldResupply_ActionInstalled", false]) exitWith {true};

private _inspect = {
    params ["_target", "_caller"];
    [
        "FIELD RESUPPLY",
        format [
            "Carrying %1 of %2 field resupply crate(s).",
            _caller getVariable ["Waldo_FieldResupply_Crates", 0],
            _caller getVariable ["Waldo_FieldResupply_MaxCrates", 0]
        ],
        "INFO",
        "FIELD_RESUPPLY_CARRIER"
    ] call Waldo_fnc_FeatureNotifyLocal;
};
private _deploy = {
    params ["_target", "_caller"];
    [_caller, "DEPLOY", []] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2];
};
private _isCarrier = {
    params ["_target", "_caller"];
    _target isEqualTo _caller
    && {_caller getVariable ["Waldo_FieldResupply_MaxCrates", 0] > 0}
    && {backpack _caller != ""}
    && {vehicle _caller isEqualTo _caller}
};
private _canDeploy = {
    params ["_target", "_caller"];
    _target isEqualTo _caller
    && {_caller getVariable ["Waldo_FieldResupply_MaxCrates", 0] > 0}
    && {_caller getVariable ["Waldo_FieldResupply_Crates", 0] > 0}
    && {backpack _caller != ""}
    && {vehicle _caller isEqualTo _caller}
};

if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _category = [
        "Waldo_FieldResupply_Category",
        "Field Resupply",
        "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa",
        {},
        _isCarrier
    ] call ace_interact_menu_fnc_createAction;
    private _inspectAction = [
        "Waldo_FieldResupply_InspectCarrier",
        "Check Resupply Crates",
        "\a3\ui_f\data\igui\cfg\holdactions\holdaction_search_ca.paa",
        _inspect,
        _isCarrier
    ] call ace_interact_menu_fnc_createAction;
    private _deployAction = [
        "Waldo_FieldResupply_Deploy",
        "Deploy Field Resupply",
        "\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
        _deploy,
        _canDeploy
    ] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions"], _category] call ace_interact_menu_fnc_addActionToObject;
    [player, 1, ["ACE_SelfActions", "Waldo_FieldResupply_Category"], _inspectAction] call ace_interact_menu_fnc_addActionToObject;
    [player, 1, ["ACE_SelfActions", "Waldo_FieldResupply_Category"], _deployAction] call ace_interact_menu_fnc_addActionToObject;
    player setVariable ["Waldo_FieldResupply_ACEActionPaths", [
        ["ACE_SelfActions", "Waldo_FieldResupply_Category"],
        ["ACE_SelfActions", "Waldo_FieldResupply_Category", "Waldo_FieldResupply_InspectCarrier"],
        ["ACE_SelfActions", "Waldo_FieldResupply_Category", "Waldo_FieldResupply_Deploy"]
    ]];
    player setVariable ["Waldo_FieldResupply_ActionIds", []];
} else {
    private _inspectId = player addAction [
        "<t color='#79C7FF'>Check Resupply Crates</t>", _inspect, [], 1.5, false, true, "",
        "_this isEqualTo _target && {_this getVariable ['Waldo_FieldResupply_MaxCrates', 0] > 0} && {backpack _this != ''} && {vehicle _this isEqualTo _this}", 3
    ];
    private _deployId = player addAction [
        "Deploy Field Resupply", _deploy, [], 1.5, false, true, "",
        "_this isEqualTo _target && {_this getVariable ['Waldo_FieldResupply_MaxCrates', 0] > 0} && {_this getVariable ['Waldo_FieldResupply_Crates', 0] > 0} && {backpack _this != ''} && {vehicle _this isEqualTo _this}", 3
    ];
    player setVariable ["Waldo_FieldResupply_ActionIds", [_inspectId, _deployId]];
    player setVariable ["Waldo_FieldResupply_ACEActionPaths", []];
};
player setVariable ["Waldo_FieldResupply_ActionInstalled", true];

if !(missionNamespace getVariable ["Waldo_FieldResupply_RespawnHandler", false]) then {
    missionNamespace setVariable ["Waldo_FieldResupply_RespawnHandler", true];
    addMissionEventHandler ["EntityRespawned", {
        params ["_newEntity"];
        if (_newEntity isEqualTo player) then {
            [_newEntity] spawn {
                params ["_unit"];
                waitUntil {!isNull player && {player isEqualTo _unit}};
                [] call Waldo_fnc_FieldResupplyInit;
            };
        };
    }];
};
true
