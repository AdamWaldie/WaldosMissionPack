/* Installs repeat-safe squad-leader self actions on the current local player. */
params [["_unit", player, [objNull]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _unit} || {!local _unit} || {_unit getVariable ["Waldo_Rally_ActionsInstalled", false]}) exitWith {false};
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
true
