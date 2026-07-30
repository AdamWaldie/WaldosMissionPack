/*
 * Author: WaldoTheWarfighter
 * Resolves a field attempt to disable a registered radio jammer. The server revalidates the
 * actor, range, engineer requirement, registry membership and current disabled state before it
 * mutates the authoritative registry. DISABLE preserves the emitter for curator reactivation;
 * DESTROY destroys and deregisters it. Feedback is sent only to the requesting player.
 *
 * Arguments:
 * 0: jammer emitter <OBJECT>
 * 1: actor completing the procedure <OBJECT>
 * 2: result mode <STRING> - "DISABLE" or "DESTROY" (default "DISABLE")
 *
 * Return Value:
 * Boolean - true when the jammer was changed
 *
 * Called by:
 * Waldo_fnc_JammerInteraction after a shared interaction challenge succeeds, or by its legacy
 * direct ACE action when the challenge is disabled.
 *
 * Example:
 * [myJammer, player, "DISABLE"] remoteExecCall ["Waldo_fnc_JammerDisableServer", 2];
 */

params [
    ["_object", objNull, [objNull]],
    ["_actor", objNull, [objNull]],
    ["_resultMode", "DISABLE", [""]]
];

if (!isServer || {isNull _object} || {isNull _actor}) exitWith {false};
private _caller = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
if (isRemoteExecuted && {_caller != owner _actor}) exitWith {false};
if !(_actor in allPlayers) exitWith {false};
if ((_actor distance _object) > 6) exitWith {false};
if (_object getVariable ["Waldo_Jamming_FieldDisabled", false]) exitWith {false};

private _engineerOnly = _object getVariable ["Waldo_Jamming_DisableEngineerOnly", true];
if (_engineerOnly && {!(isNil "ace_common_fnc_isEngineer")} && {!([_actor] call ace_common_fnc_isEngineer)}) exitWith {false};

// A challenge-enabled emitter may only enter through the server-resolved success callback. This
// prevents a client from calling the mutation endpoint directly and skipping the procedure.
private _challengeAuthorised = true;
if (_object getVariable ["Waldo_Jamming_DisableChallenge", false]) then {
    private _interactionResult = _object getVariable ["Waldo_MG_InteractionResult", []];
    _challengeAuthorised = (_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "SUCCESS"
        && {(count _interactionResult) >= 5}
        && {(_interactionResult select 4) isEqualTo _actor};
};
if (!_challengeAuthorised) exitWith {false};

private _id = _object getVariable ["Waldo_Jamming_Id", -1];
private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
if (_id < 0 || {_registry findIf {(_x select 0) == _id} < 0}) exitWith {false};

_resultMode = toUpper _resultMode;
if !(_resultMode in ["DISABLE", "DESTROY"]) then {_resultMode = "DISABLE";};
_object setVariable ["Waldo_Jamming_FieldDisabled", true, true];

if (_resultMode == "DESTROY") then {
    [_object] call Waldo_fnc_JammerRemove;
    if (local _object) then {
        _object setDamage 1;
    } else {
        [_object, 1] remoteExecCall ["setDamage", owner _object];
    };
} else {
    [_object, false] call Waldo_fnc_JammerToggle;
};

["JAMMER DISABLED", "The emitter is no longer disrupting communications.", 6, "SUCCESS"]
    remoteExecCall ["Waldo_fnc_JammingNotice", owner _actor];
diag_log format ["[WMP JAM] field disable accepted jammer=%1 actor=%2 mode=%3", _id, name _actor, _resultMode];
true
