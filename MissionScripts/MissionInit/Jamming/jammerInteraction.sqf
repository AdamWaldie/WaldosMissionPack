/*
 * Author: WaldoTheWarfighter
 * Installs the field interactions for a registered radio jammer. The feature-owned Disable Jammer
 * action is the only player path that turns an active emitter off, preventing an operator action
 * from bypassing the direct or challenged procedure. Optional reactivation appears only while the
 * registered field is inactive. The Disable Jammer action is always
 * retained; the optional procedure flag only changes that action from immediate disablement to
 * launching the shared challenge. The result is resolved on the server and the action remains
 * local and repeat-safe for JIP clients.
 *
 * Arguments:
 * 0: jammer emitter <OBJECT>
 * 1: interaction settings <ARRAY> in the authoritative order
 *      [allowPlayerToggle, disableChallenge, challengeId, difficulty, engineerOnly, resultMode]
 *      allowPlayerToggle is the legacy API key; it now controls inactive-field reactivation only.
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
private _interactionVersion = 3;
if ((_object getVariable ["Waldo_Jamming_InteractionVersion", 0]) >= _interactionVersion) exitWith {};

// Remove the former single Toggle action and an older Disable action before installing this
// version. This keeps a live script refresh repeat-safe as well as normal JIP setup.
if !(isNil "ace_interact_menu_fnc_removeActionFromObject") then {
    [_object, 0, ["ACE_MainActions", "Waldo_Jammer_Toggle"]] call ace_interact_menu_fnc_removeActionFromObject;
    [_object, 0, ["ACE_MainActions", "Waldo_Jammer_Activate"]] call ace_interact_menu_fnc_removeActionFromObject;
    [_object, 0, ["ACE_MainActions", "Waldo_Jammer_Deactivate"]] call ace_interact_menu_fnc_removeActionFromObject;
    [_object, 0, ["ACE_MainActions", "Waldo_Jammer_Disable"]] call ace_interact_menu_fnc_removeActionFromObject;
};

// Reactivation is a separately configured convenience. Turning an active emitter off always goes
// through the Disable Jammer surface below, whose execution may be gated by the optional procedure.
if (_allowPlayerToggle) then {
    private _activate = [
        "Waldo_Jammer_Activate",
        "Activate Jammer",
        "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa",
        {
            params ["_target"];
            [_target, true] call Waldo_fnc_JammerToggle;
        },
        {
            params ["_target"];
            private _id = _target getVariable ["Waldo_Jamming_Id", -1];
            private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
            private _index = _registry findIf {(_x select 0) == _id};
            _id >= 0
            && {_index >= 0}
            && {!((_registry select _index) select 7)}
        }
    ] call ace_interact_menu_fnc_createAction;
    [_object, 0, ["ACE_MainActions"], _activate] call ace_interact_menu_fnc_addActionToObject;
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
        private _id = _target getVariable ["Waldo_Jamming_Id", -1];
        private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
        private _index = _registry findIf {(_x select 0) == _id};
        private _active = _index >= 0 && {(_registry select _index) select 7};
        if !(_target getVariable ["Waldo_Jamming_DisableEngineerOnly", true]) exitWith {
            _id >= 0 && {_active} && {!(_target getVariable ["Waldo_Jamming_FieldDisabled", false])}
        };
        private _isEngineer = true;
        if !(isNil "ace_common_fnc_isEngineer") then {_isEngineer = [_player] call ace_common_fnc_isEngineer;};
        _isEngineer
        && {_id >= 0}
        && {_active}
        && {!(_target getVariable ["Waldo_Jamming_FieldDisabled", false])}
    }
] call ace_interact_menu_fnc_createAction;
[_object, 0, ["ACE_MainActions"], _disable] call ace_interact_menu_fnc_addActionToObject;
private _disablePath = ["ACE_MainActions", "Waldo_Jammer_Disable"];
_object setVariable ["Waldo_Jamming_DisableACEPath", _disablePath];
_object setVariable ["Waldo_Jamming_DisableACEInstalled", true];
_object setVariable ["Waldo_Jamming_AceAdded", true];
_object setVariable ["Waldo_Jamming_InteractionVersion", _interactionVersion];
diag_log format ["[WMP JAM] feature action installed object=%1 action=Waldo_Jammer_Disable path=%2 challenge=%3", netId _object, _disablePath, _challengeEnabled];
