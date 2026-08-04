/*
 * Author: WaldoTheWarfighter
 * Opens a friendly-name ZEN selector for removing one complete registered Dynamic AO.
 *
 * The AO nearest the module position is preselected, while every live AO remains available. The
 * selected id is sent to the same server cleanup API used by deleting its centre anchor.
 * Current caller: Dynamic AO - Remove in Zen_initModules.sqf.
 *
 * Arguments:
 * 0: module position <ARRAY>
 *
 * Return Value:
 * Boolean - true when the dialog was opened
 *
 * Example:
 * [_modulePos] call Waldo_fnc_DynamicAORemoveZen;
 */
params [["_modulePos", [], [[]]]];
if !(hasInterface) exitWith {false};
private _systems = missionNamespace getVariable ["Waldo_DynamicAO_PublicSystems", []];
if (count _systems == 0) exitWith {
    ["DYNAMIC AO", "No generated areas of operations are active.", "WARNING", "DYNAMIC_AO", 6]
        call Waldo_fnc_FeatureNotifyLocal;
    false
};
private _values = _systems apply {_x select 0};
private _labels = _systems apply {
    private _factionName = getText (configFile >> "CfgFactionClasses" >> (_x select 4) >> "displayName");
    if (_factionName == "") then {_factionName = _x select 4};
    format ["%1 - %2 (%3m)", _x param [6, _x select 0], _factionName, round ((_x select 1) distance2D _modulePos)]
};
private _nearest = 0;
private _distance = 1e10;
{
    private _candidate = (_x select 1) distance2D _modulePos;
    if (_candidate < _distance) then {_distance = _candidate; _nearest = _forEachIndex};
} forEach _systems;
[
    "Remove Dynamic Area of Operations",
    [["COMBO", ["Active AO", "The nearest AO is selected by default. Cleanup deletes all tracked groups, objects, mines and markers."], [_values, _labels, _nearest]]],
    {params ["_values"]; [_values select 0] remoteExecCall ["Waldo_fnc_DynamicAODestroy", 2]}
] call zen_dialog_fnc_create;
true
