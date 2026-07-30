/*
 * Author: WaldoTheWarfighter
 * Installs the field interactions for a registered radio jammer. Operator toggling and hostile
 * field disablement are deliberately separate: when a disable challenge is enabled, the direct
 * toggle is suppressed so it cannot bypass the procedure. The challenge uses the shared field-
 * equipment interaction framework, whose result is resolved on the server; ACE and vanilla
 * presentation remain local and repeat-safe for JIP clients.
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
 * Called by:
 * Waldo_fnc_Jammer broadcasts this function to the server, every current client and JIP clients.
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
            ["actionTitle", "Bypass and Disable Radio Jammer"],
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
if (_object getVariable ["Waldo_Jamming_AceAdded", false]) exitWith {};
_object setVariable ["Waldo_Jamming_AceAdded", true];

// A direct toggle is an operator convenience. It is intentionally unavailable when the hostile
// disable challenge is active, otherwise the challenge could be bypassed with a single click.
if (_allowPlayerToggle && {!_challengeEnabled}) then {
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

// Compatibility path for missions that do not opt into the shared interaction challenge.
if (!_challengeEnabled) then {
    private _disable = [
        "Waldo_Jammer_Disable",
        "Disable Radio Jammer",
        "\a3\ui_f\data\igui\cfg\simpletasks\types\danger_ca.paa",
        {
            params ["_target", "_player"];
            [_target, _player, "DESTROY"] remoteExecCall ["Waldo_fnc_JammerDisableServer", 2];
        },
        {
            params ["_target", "_player"];
            if !(_target getVariable ["Waldo_Jamming_DisableEngineerOnly", true]) exitWith {
                (_target getVariable ["Waldo_Jamming_Id", -1]) >= 0
            };
            private _isEngineer = true;
            if !(isNil "ace_common_fnc_isEngineer") then {_isEngineer = [_player] call ace_common_fnc_isEngineer;};
            _isEngineer && {(_target getVariable ["Waldo_Jamming_Id", -1]) >= 0}
        }
    ] call ace_interact_menu_fnc_createAction;
    [_object, 0, ["ACE_MainActions"], _disable] call ace_interact_menu_fnc_addActionToObject;
};
