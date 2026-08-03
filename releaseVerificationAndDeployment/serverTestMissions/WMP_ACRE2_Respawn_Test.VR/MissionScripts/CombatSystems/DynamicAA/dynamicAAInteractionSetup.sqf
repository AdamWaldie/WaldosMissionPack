/*
 * Author: WaldoTheWarfighter
 * Attaches an optional shared shutdown procedure to a Dynamic AA system's central radar. The
 * procedure is installed as callback/state behind a feature-owned Disable AA System action.
 * Successful completion calls the authoritative AA teardown API with asset deletion disabled,
 * leaving a visibly intact but inactive installation.
 *
 * Arguments:
 * 0: central radar <OBJECT>
 * 1: settings <ARRAY> - [systemId, challengeId, difficulty]
 *
 * Return Value:
 * Boolean - true when a valid setup was submitted
 *
 * Called by:
 * Waldo_fnc_DynamicAACreate through an object-keyed JIP remote execution.
 *
 * Example:
 * [radar, ["AA_NORTH", "circuit", "standard"]] call Waldo_fnc_DynamicAAInteractionSetup;
 */

params [["_radar", objNull, [objNull]], ["_settings", [], [[]]]];
if (isNull _radar || {count _settings < 3}) exitWith {false};
_settings params ["_systemId", "_challengeId", "_difficulty"];
_radar setVariable ["Waldo_DynamicAA_SystemId", _systemId];

[
    _radar,
    _challengeId,
    createHashMapFromArray [
        ["actionTitle", "Disable AA System"],
        ["installAction", false],
        ["difficulty", _difficulty],
        ["retryOnFailure", true],
        ["repeatable", false],
        ["condition", {
            _this getVariable ["Waldo_DynamicAA_InteractionAvailable", false]
        }],
        ["onSuccess", {
            params ["_target"];
            _target setVariable ["Waldo_DynamicAA_InteractionAvailable", false, true];
            [_target getVariable ["Waldo_DynamicAA_SystemId", ""], false, _target] call Waldo_fnc_DynamicAADestroy;
        }],
        ["preset", "aa-radar-shutdown"],
        ["title", "AIR DEFENCE CONTROL RADAR"],
        ["objective", "Isolate the radar control path and take the air-defence network offline."],
        ["briefing", "RADAR SHUTDOWN PROCEDURE"],
        ["successText", "AIR-DEFENCE NETWORK DISABLED"],
        ["skin", "hazard"]
    ]
] call Waldo_fnc_MiniGameInteractionSetup;

if (hasInterface && {!(_radar getVariable ["Waldo_DynamicAA_ShutdownActionInstalled", false])}) then {
    private _statement = {params ["_target"]; _target call Waldo_fnc_MiniGameInteractionActivate};
    private _condition = {
        params ["_target"];
        _target getVariable ["Waldo_DynamicAA_InteractionAvailable", false]
    };
    if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")
        && {!(isNil "ace_interact_menu_fnc_createAction")}
        && {!(isNil "ace_interact_menu_fnc_addActionToObject")}) then {
        private _action = [
            "Waldo_DynamicAA_DisableSystem",
            "Disable AA System",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\danger_ca.paa",
            _statement,
            _condition
        ] call ace_interact_menu_fnc_createAction;
        private _path = [_radar, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
        _radar setVariable ["Waldo_DynamicAA_ShutdownACEPath", _path];
    } else {
        private _id = _radar addAction [
            "Disable AA System",
            _statement,
            [], 1.5, true, true, "",
            "_target getVariable ['Waldo_DynamicAA_InteractionAvailable', false] && {_this distance _target <= 5}",
            5
        ];
        _radar setVariable ["Waldo_DynamicAA_ShutdownActionId", _id];
    };
    _radar setVariable ["Waldo_DynamicAA_ShutdownActionInstalled", true];
};
true
