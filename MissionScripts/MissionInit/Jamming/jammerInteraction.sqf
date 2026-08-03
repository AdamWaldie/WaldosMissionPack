/*
 * Author: WaldoTheWarfighter
 * Installs the field interactions for a registered radio jammer. Operator toggling and hostile
 * field disablement are deliberately separate. The feature-owned Disable Jammer action is always
 * retained; the optional procedure flag only changes that action from immediate disablement to
 * launching the shared challenge. The result is resolved on the server and the action remains
 * local and repeat-safe for JIP clients.
 *
 * Arguments:
 * 0: jammer emitter <OBJECT>
 * 1: interaction settings <ARRAY> in the authoritative order
 *      [allowPlayerToggle, disableChallenge, challengeId, difficulty, engineerOnly, resultMode]
 *      (optional; falls back to the emitter's broadcast settings)
 *
 * Result modes:
 * - "DISABLE": switch the registered field off and mark it field-disabled (default)
 * - "DESTROY": destroy and deregister the emitter
 *
 * Return Value:
 * Nothing
 *
 * Current callers: Waldo_fnc_Jammer broadcasts this function to the server, every current client
 * and JIP client; Waldo_fnc_ZenCreateJammerServer retries the exact payload after ownership settles.
 *
 * Example:
 * [myJammer, [false, true, "circuit", "standard", true, "DISABLE"]]
 *     call Waldo_fnc_JammerInteraction;
 */

params [
    ["_object", objNull, [objNull]],
    ["_settings", [], [[]]]
];

if (isNull _object) exitWith {};

private _fallback = [
    _object getVariable ["Waldo_Jamming_AllowPlayerToggle", missionNamespace getVariable ["Waldo_Jamming_AllowPlayerToggle", true]],
    _object getVariable ["Waldo_Jamming_DisableChallenge", missionNamespace getVariable ["Waldo_Jamming_DisableChallenge", false]],
    _object getVariable ["Waldo_Jamming_DisableChallengeId", missionNamespace getVariable ["Waldo_Jamming_DisableChallengeId", "circuit"]],
    _object getVariable ["Waldo_Jamming_DisableDifficulty", missionNamespace getVariable ["Waldo_Jamming_DisableDifficulty", "standard"]],
    _object getVariable ["Waldo_Jamming_DisableEngineerOnly", missionNamespace getVariable ["Waldo_Jamming_DisableEngineerOnly", true]],
    _object getVariable ["Waldo_Jamming_DisableResult", missionNamespace getVariable ["Waldo_Jamming_DisableResult", "DISABLE"]]
];
if ((count _settings) < 6) then {_settings = _fallback;};
_settings params ["_allowPlayerToggle", "_challengeEnabled", "_challengeId", "_difficulty", "_engineerOnly", "_resultMode"];

// Store the exact payload on every machine. Passing it in the JIP remoteExec avoids relying on
// public-variable arrival order during client join.
_object setVariable ["Waldo_Jamming_AllowPlayerToggle", _allowPlayerToggle];
_object setVariable ["Waldo_Jamming_DisableChallenge", _challengeEnabled];
_object setVariable ["Waldo_Jamming_DisableChallengeId", _challengeId];
_object setVariable ["Waldo_Jamming_DisableDifficulty", _difficulty];
_object setVariable ["Waldo_Jamming_DisableEngineerOnly", _engineerOnly];
_object setVariable ["Waldo_Jamming_DisableResult", _resultMode];

if (_challengeEnabled && {!isNil "Waldo_fnc_MiniGameInteractionSetup"}) then {
    [
        _object,
        _challengeId,
        createHashMapFromArray [
            ["actionTitle", "Disable Jammer"],
            ["installAction", false],
            ["difficulty", _difficulty],
            ["retryOnFailure", true],
            ["repeatable", false],
            ["oneShot", false],
            ["distance", 4],
            ["condition", {
                (_this getVariable ["Waldo_Jamming_Id", -1]) >= 0
                && {!(_this getVariable ["Waldo_Jamming_FieldDisabled", false])}
            }],
            ["actorCondition", {
                params ["_target", "_actor"];
                if !(_target getVariable ["Waldo_Jamming_DisableEngineerOnly", true]) exitWith {true};
                if (isNil "ace_common_fnc_isEngineer") exitWith {true};
                [_actor] call ace_common_fnc_isEngineer
            }],
            ["onSuccess", {
                params ["_target", "_actor"];
                [_target, _actor, _target getVariable ["Waldo_Jamming_DisableResult", "DISABLE"]]
                    call Waldo_fnc_JammerDisableServer;
            }],
            ["preset", "jammer-bypass"],
            ["title", "ELECTRONIC COUNTERMEASURES"],
            ["objective", "Isolate the emitter control path and shut down the jamming field."],
            ["briefing", "FIELD DISABLE PROCEDURE"],
            ["statusText", "TRACE THE POWER AND CONTROL CIRCUIT"],
            ["successText", "JAMMING FIELD DISABLED"],
            ["failureText", "BYPASS FAILED - EMITTER REMAINS ACTIVE"],
            ["skin", "hazard"]
        ]
    ] call Waldo_fnc_MiniGameInteractionSetup;
};

// Dedicated servers retain the authoritative callbacks above but do not install local actions.
if (!hasInterface) exitWith {};
if !(isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {};
if (isNil "ace_interact_menu_fnc_createAction" || {isNil "ace_interact_menu_fnc_addActionToObject"}) exitWith {};
if (_object getVariable ["Waldo_Jamming_DisableACEInstalled", false]) exitWith {};

// The operator toggle remains a separately configured convenience; the disable action below is
// the single feature surface whose execution can be gated by the optional procedure.
if (_allowPlayerToggle) then {
    private _toggle = [
        "Waldo_Jammer_Toggle",
        "Toggle Radio Jammer",
        "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa",
        {
            params ["_target"];
            [_target] call Waldo_fnc_JammerToggle;
        },
        {
            params ["_target"];
            (_target getVariable ["Waldo_Jamming_Id", -1]) >= 0
        }
    ] call ace_interact_menu_fnc_createAction;
    [_object, 0, ["ACE_MainActions"], _toggle] call ace_interact_menu_fnc_addActionToObject;
};

private _disable = [
    "Waldo_Jammer_Disable",
    "Disable Jammer",
    "\a3\ui_f\data\igui\cfg\simpletasks\types\danger_ca.paa",
    {
        params ["_target", "_player"];
        if (_target getVariable ["Waldo_Jamming_DisableChallenge", false]) then {
            _target call Waldo_fnc_MiniGameInteractionActivate;
        } else {
            [_target, _player, _target getVariable ["Waldo_Jamming_DisableResult", "DISABLE"]]
                remoteExecCall ["Waldo_fnc_JammerDisableServer", 2];
        };
    },
    {
        params ["_target", "_player"];
        if !(_target getVariable ["Waldo_Jamming_DisableEngineerOnly", true]) exitWith {
            (_target getVariable ["Waldo_Jamming_Id", -1]) >= 0
            && {!(_target getVariable ["Waldo_Jamming_FieldDisabled", false])}
        };
        private _isEngineer = true;
        if !(isNil "ace_common_fnc_isEngineer") then {_isEngineer = [_player] call ace_common_fnc_isEngineer;};
        _isEngineer
        && {(_target getVariable ["Waldo_Jamming_Id", -1]) >= 0}
        && {!(_target getVariable ["Waldo_Jamming_FieldDisabled", false])}
    }
] call ace_interact_menu_fnc_createAction;
[_object, 0, ["ACE_MainActions"], _disable] call ace_interact_menu_fnc_addActionToObject;
private _disablePath = ["ACE_MainActions", "Waldo_Jammer_Disable"];
_object setVariable ["Waldo_Jamming_DisableACEPath", _disablePath];
_object setVariable ["Waldo_Jamming_DisableACEInstalled", true];
_object setVariable ["Waldo_Jamming_AceAdded", true];
diag_log format ["[WMP JAM] feature action installed object=%1 action=Waldo_Jammer_Disable path=%2 challenge=%3", netId _object, _disablePath, _challengeEnabled];
