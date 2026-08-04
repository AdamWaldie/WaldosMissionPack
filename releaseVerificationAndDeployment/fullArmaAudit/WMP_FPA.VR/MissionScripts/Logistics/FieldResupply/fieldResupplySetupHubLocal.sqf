/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe local refill interaction on one registered Field Resupply hub.
 *
 * ACE clients receive a Field Resupply category containing the refill interaction; non-ACE
 * clients receive a scroll-wheel fallback.
 * Both are visible only to assigned carriers wearing a backpack; the server independently validates
 * range, side, stock and carrier capacity. Object-keyed JIP publication calls this function for
 * late joiners without duplicating actions already installed on that client.
 *
 * Arguments:
 * 0: hub <OBJECT> - registered resupply hub receiving the local interaction.
 *
 * Return Value:
 * Boolean - true when local setup completes; otherwise false.
 *
 * Example:
 * [_hub] remoteExecCall ["Waldo_fnc_FieldResupplySetupHubLocal", -2, "FieldHub_Main"];
 *
 * Current caller: FieldResupplyRegisterHub through an object-keyed JIP remote call.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Optional-Feature-Extensions#field-resupply
 */

params [["_hub", objNull, [objNull]]];
if !(hasInterface) exitWith {false};
if (isNull _hub || {_hub getVariable ["Waldo_FieldResupply_LocalSetup", false]}) exitWith {false};
_hub setVariable ["Waldo_FieldResupply_LocalSetup", true];
private _inspectHub = {
    params ["_target"];
    private _stock = _target getVariable ["Waldo_FieldResupply_Stock", -1];
    private _side = _target getVariable ["Waldo_FieldResupply_Side", sideUnknown];
    [
        "FIELD RESUPPLY HUB",
        format [
            "Refills assigned Field Resupply carriers. Stock: %1. Serviced side: %2.",
            if (_stock < 0) then {"Unlimited"} else {str _stock},
            if (_side isEqualTo sideUnknown) then {"All sides"} else {str _side}
        ],
        "INFO",
        "FIELD_RESUPPLY_HUB"
    ] call Waldo_fnc_FeatureNotifyLocal;
};
private _infoId = _hub addAction [
    "<t color='#79C7FF'>Field Resupply Hub</t>",
    _inspectHub,
    [],
    1.6,
    true,
    false,
    "",
    "_this distance _target <= 4",
    4
];
private _statement = {params ["_target", "_caller"]; [_caller, "REFILL", [_target]] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2]};
private _condition = {
    params ["_target", "_caller"];
    _caller getVariable ["Waldo_FieldResupply_MaxCrates", 0] > 0
    && {backpack _caller != ""}
};
if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _category = ["Waldo_FieldResupply_Category", "Field Resupply", "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa", {}, _condition] call ace_interact_menu_fnc_createAction;
    private _action = ["Waldo_FieldResupply_Refill", "Refill Field Resupply Carrier", "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa", _statement, _condition] call ace_interact_menu_fnc_createAction;
    [_hub, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject;
    [_hub, 0, ["ACE_MainActions", "Waldo_FieldResupply_Category"], _action] call ace_interact_menu_fnc_addActionToObject;
    _hub setVariable ["Waldo_FieldResupply_ACEActionPaths", [
        ["ACE_MainActions", "Waldo_FieldResupply_Category"],
        ["ACE_MainActions", "Waldo_FieldResupply_Category", "Waldo_FieldResupply_Refill"]
    ]];
    _hub setVariable ["Waldo_FieldResupply_ActionIds", [_infoId]];
} else {
    private _action = _hub addAction ["Refill Field Resupply Carrier", _statement, [], 1.5, true, true, "", "_this distance _target <= 4 && {_this getVariable ['Waldo_FieldResupply_MaxCrates', 0] > 0} && {backpack _this != ''}", 4];
    _hub setVariable ["Waldo_FieldResupply_ActionIds", [_infoId, _action]];
    _hub setVariable ["Waldo_FieldResupply_ACEActionPaths", []];
};
true
