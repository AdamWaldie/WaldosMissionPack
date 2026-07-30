/*
 * Author: WaldoTheWarfighter
 * Installs repeat-safe local interactions on one deployed Field Resupply crate.
 *
 * ACE clients receive inspect, take-ammunition and salvage object interactions; clients without
 * ACE Interact receive equivalent scroll-wheel actions. Inspect and take are available to nearby
 * players, while salvage is shown only to an assigned carrier wearing a backpack. The server owns
 * charges, cargo mutation, salvage eligibility and deletion. Object-keyed JIP setup gives late
 * joiners the same controls without duplicating them.
 *
 * Arguments:
 * 0: crate <OBJECT> - deployed crate receiving local actions.
 *
 * Return Value:
 * Boolean - true when local setup completes; otherwise false.
 *
 * Example:
 * [_crate] call Waldo_fnc_FieldResupplySetupCrateLocal;
 *
 * Current caller: FieldResupplyServerHandle after a successful DEPLOY operation.
 */

params [["_crate", objNull, [objNull]]];
if !(hasInterface) exitWith {false};
if (isNull _crate || {_crate getVariable ["Waldo_FieldResupply_LocalSetup", false]}) exitWith {false};
_crate setVariable ["Waldo_FieldResupply_LocalSetup", true];
private _inspect = {
    params ["_target"];
    ["FIELD RESUPPLY", format ["Charges remaining: %1.", _target getVariable ["Waldo_FieldResupply_Charges", 0]], "INFO", "FIELD_RESUPPLY"] call Waldo_fnc_FeatureNotifyLocal;
};
private _take = {
    params ["_target", "_caller"];
    [_caller, "TAKE", [_target]] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2];
};
private _salvage = {
    params ["_target", "_caller"];
    [_caller, "SALVAGE", [_target]] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2];
};
if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _actions = [
        ["Waldo_FieldResupply_Inspect", "Inspect Field Resupply", _inspect, {true}],
        ["Waldo_FieldResupply_Take", "Take Compatible Ammunition", _take, {_target getVariable ["Waldo_FieldResupply_Charges", 0] > 0}],
        ["Waldo_FieldResupply_Salvage", "Salvage Field Resupply", _salvage, {
            _player getVariable ["Waldo_FieldResupply_MaxCrates", 0] > 0 && {backpack _player != ""}
        }]
    ];
    private _paths = [];
    {
        _x params ["_id", "_title", "_statement", "_condition"];
        private _action = [_id, _title, "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa", _statement, _condition] call ace_interact_menu_fnc_createAction;
        [_crate, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
        _paths pushBack ["ACE_MainActions", _id];
    } forEach _actions;
    _crate setVariable ["Waldo_FieldResupply_ACEActionPaths", _paths];
    _crate setVariable ["Waldo_FieldResupply_ActionIds", []];
} else {
    private _ids = [
        _crate addAction ["Inspect Field Resupply", _inspect, [], 1.5, true, true, "", "_this distance _target <= 4", 4],
        _crate addAction ["Take Compatible Ammunition", _take, [], 1.5, true, true, "", "_this distance _target <= 4 && {_target getVariable ['Waldo_FieldResupply_Charges', 0] > 0}", 4],
        _crate addAction ["Salvage Field Resupply", _salvage, [], 1.4, true, true, "", "_this distance _target <= 4 && {_this getVariable ['Waldo_FieldResupply_MaxCrates', 0] > 0} && {backpack _this != ''}", 4]
    ];
    _crate setVariable ["Waldo_FieldResupply_ActionIds", _ids];
    _crate setVariable ["Waldo_FieldResupply_ACEActionPaths", []];
};
true
