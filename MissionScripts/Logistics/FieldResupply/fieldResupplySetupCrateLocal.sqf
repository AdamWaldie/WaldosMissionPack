/*
 * Author: WaldoTheWarfighter
 * Installs repeat-safe local interactions on one deployed Field Resupply crate.
 *
 * The crate carries real weapon/magazine/item cargo (populated by Waldo_fnc_SupplyCratePopulate
 * before this runs), so taking supplies from it is ordinary ACE Cargo/Gear interaction - there is no
 * WMP-brokered take action here. ACE clients receive a Field Resupply category containing inspect
 * and salvage interactions; every client also receives a WMP-blue informational addAction, joined by
 * a salvage fallback without ACE. The server owns salvage eligibility and deletion. Object-keyed JIP
 * setup gives late joiners the same controls without duplicating them.
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
    ["FIELD RESUPPLY", "Open this crate's Gear or Cargo to see and take its remaining supplies.", "INFO", "FIELD_RESUPPLY"] call Waldo_fnc_FeatureNotifyLocal;
};
private _salvage = {
    params ["_target", "_caller"];
    [_caller, "SALVAGE", [_target]] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2];
};
private _infoId = _crate addAction [
    "<t color='#79C7FF'>Field Resupply Crate</t>", _inspect, [], 1.6, true, false, "",
    "_this distance _target <= 4", 4
];
if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _category = [
        "Waldo_FieldResupply_Category", "Field Resupply",
        "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa", {}, {true}
    ] call ace_interact_menu_fnc_createAction;
    [_crate, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject;
    private _actions = [
        ["Waldo_FieldResupply_Inspect", "Inspect Field Resupply", _inspect, {true}],
        ["Waldo_FieldResupply_Salvage", "Salvage Field Resupply", _salvage, {
            _player getVariable ["Waldo_FieldResupply_MaxCrates", 0] > 0 && {backpack _player != ""}
        }]
    ];
    private _paths = [["ACE_MainActions", "Waldo_FieldResupply_Category"]];
    {
        _x params ["_id", "_title", "_statement", "_condition"];
        private _action = [_id, _title, "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa", _statement, _condition] call ace_interact_menu_fnc_createAction;
        [_crate, 0, ["ACE_MainActions", "Waldo_FieldResupply_Category"], _action] call ace_interact_menu_fnc_addActionToObject;
        _paths pushBack ["ACE_MainActions", "Waldo_FieldResupply_Category", _id];
    } forEach _actions;
    _crate setVariable ["Waldo_FieldResupply_ACEActionPaths", _paths];
    _crate setVariable ["Waldo_FieldResupply_ActionIds", [_infoId]];
} else {
    private _ids = [
        _crate addAction ["Salvage Field Resupply", _salvage, [], 1.4, true, true, "", "_this distance _target <= 4 && {_this getVariable ['Waldo_FieldResupply_MaxCrates', 0] > 0} && {backpack _this != ''}", 4]
    ];
    _ids pushBack _infoId;
    _crate setVariable ["Waldo_FieldResupply_ActionIds", _ids];
    _crate setVariable ["Waldo_FieldResupply_ACEActionPaths", []];
};
true
