/* Installs repeat-safe squad-leader self actions on the current local player. */
params [["_unit", player, [objNull]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _unit} || {!local _unit} || {_unit getVariable ["Waldo_Rally_ActionsInstalled", false]}) exitWith {false};

if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _deploy = [
        "Waldo_Rally_Deploy",
        "Deploy Squad Rally Point",
        "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",
        {
            params ["_target", "_actor"];
            private _duration = missionNamespace getVariable ["Waldo_Rally_DeploymentTime", 15];
            [
                _duration,
                [_actor],
                {params ["_arguments"]; [(_arguments select 0), "DEPLOY"] remoteExecCall ["Waldo_fnc_RallyPointRequestServer", 2];},
                {},
                "Deploying squad rally point...",
                {params ["_arguments"]; private _actor = _arguments select 0; alive _actor && {vehicle _actor == _actor} && {_actor == leader group _actor}}
            ] call ace_common_fnc_progressBar;
        },
        {
            params ["_target", "_actor"];
            missionNamespace getVariable ["Waldo_Rally_Enable", false]
            && {_actor == leader group _actor}
            && {vehicle _actor == _actor}
            && {alive _actor}
            && {!((group _actor) getVariable ["Waldo_Rally_Active", false])}
        }
    ] call ace_interact_menu_fnc_createAction;
    private _pack = [
        "Waldo_Rally_Pack", "Pack Squad Rally Point",
        "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",
        {params ["_target", "_actor"]; [_actor, "REMOVE"] remoteExecCall ["Waldo_fnc_RallyPointRequestServer", 2];},
        {params ["_target", "_actor"]; missionNamespace getVariable ["Waldo_Rally_Enable", false] && {_actor == leader group _actor} && {(group _actor) getVariable ["Waldo_Rally_Active", false]}}
    ] call ace_interact_menu_fnc_createAction;
    private _regroup = [
        "Waldo_Rally_Regroup", "Redeploy at Squad Rally",
        "\a3\ui_f\data\igui\cfg\simpletasks\types\move_ca.paa",
        {params ["_target", "_actor"]; [_actor, "REGROUP"] remoteExecCall ["Waldo_fnc_RallyPointRequestServer", 2];},
        {params ["_target", "_actor"]; missionNamespace getVariable ["Waldo_Rally_Enable", false] && {missionNamespace getVariable ["Waldo_Rally_AllowRegroup", false]} && {(group _actor) getVariable ["Waldo_Rally_Active", false]} && {vehicle _actor == _actor}}
    ] call ace_interact_menu_fnc_createAction;
    {
        [_unit, 1, ["ACE_SelfActions"], _x] call ace_interact_menu_fnc_addActionToObject;
    } forEach [_deploy, _pack, _regroup];
    _unit setVariable ["Waldo_Rally_ACEActionPaths", [
        ["ACE_SelfActions", "Waldo_Rally_Deploy"],
        ["ACE_SelfActions", "Waldo_Rally_Pack"],
        ["ACE_SelfActions", "Waldo_Rally_Regroup"]
    ]];
    _unit setVariable ["Waldo_Rally_HoldActionIds", []];
    _unit setVariable ["Waldo_Rally_ActionIds", []];
    _unit setVariable ["Waldo_Rally_ActionsInstalled", true];
    diag_log format ["[WMP RALLY] Local controls installed mode=ACE unit=%1 paths=%2", name _unit, count (_unit getVariable ["Waldo_Rally_ACEActionPaths", []])];
    true
} else {
private _deploy = [
    _unit,
    "<t color='#F4C542'>Deploy Squad Rally Point</t>",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",
    "missionNamespace getVariable ['Waldo_Rally_Enable',false] && {_caller == leader group _caller} && {vehicle _caller == _caller} && {alive _caller} && {!((group _caller) getVariable ['Waldo_Rally_Active',false])}",
    "_caller == _target && {vehicle _caller == _caller} && {alive _caller}",
    {}, {},
    {params ["_target", "_actor"]; [_actor, "DEPLOY"] remoteExecCall ["Waldo_fnc_RallyPointRequestServer", 2];},
    {}, [], missionNamespace getVariable ["Waldo_Rally_DeploymentTime", 15], 1.5, false, false
] call BIS_fnc_holdActionAdd;
private _remove = _unit addAction [
    "<t color='#F4C542'>Pack Squad Rally Point</t>",
    {params ["_target", "_actor"]; [_actor, "REMOVE"] remoteExecCall ["Waldo_fnc_RallyPointRequestServer", 2];},
    [], 1.5, false, true, "",
    "missionNamespace getVariable ['Waldo_Rally_Enable',false] && {_this == leader group _this} && {(group _this) getVariable ['Waldo_Rally_Active',false]}", 0
];
private _regroup = _unit addAction [
    "<t color='#79C7FF'>Redeploy at Squad Rally</t>",
    {params ["_target", "_actor"]; [_actor, "REGROUP"] remoteExecCall ["Waldo_fnc_RallyPointRequestServer", 2];},
    [], 1.4, false, true, "",
    "missionNamespace getVariable ['Waldo_Rally_Enable',false] && {missionNamespace getVariable ['Waldo_Rally_AllowRegroup',false]} && {(group _this) getVariable ['Waldo_Rally_Active',false]} && {vehicle _this == _this}", 0
];
_unit setVariable ["Waldo_Rally_HoldActionIds", [_deploy]];
_unit setVariable ["Waldo_Rally_ActionIds", [_remove, _regroup]];
_unit setVariable ["Waldo_Rally_ActionsInstalled", true];
diag_log format ["[WMP RALLY] Local controls installed mode=VANILLA unit=%1 actions=%2", name _unit, count (_unit getVariable ["Waldo_Rally_HoldActionIds", []]) + count (_unit getVariable ["Waldo_Rally_ActionIds", []])];
true
}
