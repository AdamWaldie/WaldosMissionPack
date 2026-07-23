/*
 * Author: Waldo
 * Launches a mini game "challenge" by id for a single player and delivers a pass/fail result
 * to success/failure callbacks. This is the standalone entry point behind the generic
 * interaction hook (Waldo_fnc_MiniGameInteraction) - call it directly to run a challenge for
 * any reason (a task step, a Zeus prompt, a trigger) without attaching it to an object.
 *
 * The built-in challenges are registered automatically on first
 * use; add your own with Waldo_fnc_MiniGameRegisterChallenge. Callbacks receive
 * [_actor, _challengeId, _context].
 *
 * Arguments:
 * _challengeId - String - registered challenge id (default "wirecut")
 * _config      - Array  - challenge-specific config passed straight to the opener (default [])
 * _onSuccess   - Code   - run locally on the actor when the challenge is passed (default {})
 * _onFailure   - Code   - run locally on the actor when the challenge is failed (default {})
 * _actor       - Object - who plays it (default: player)
 * _context     - Any    - opaque value handed back to the callbacks (default [])
 * _presentation- Array/HashMap - optional validated equipment presentation overrides
 *
 * Return Value:
 * Boolean - true if a challenge dialog was opened
 *
 * Example:
 * ["minesweeper", [], { hint "Hacked."; }, { hint "Lockout."; }] call Waldo_fnc_MiniGameChallenge;
 */

params [
    ["_challengeId", "wirecut", [""]],
    ["_config", [], [[]]],
    ["_onSuccess", {}, [{}]],
    ["_onFailure", {}, [{}]],
    ["_actor", objNull, [objNull]],
    ["_context", [], []],
    ["_presentation", [], [[], createHashMap]]
];

if (!hasInterface) exitWith { false };
if (isNull _actor) then { _actor = player; };
if (!isNull (missionNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])) exitWith {
    systemChat "Field Equipment: finish the active procedure first.";
    false
};

// Register the built-in challenges once.
if !(missionNamespace getVariable ["Waldo_MG_ChallengesRegistered", false]) then {
    ["wirecut", Waldo_fnc_MiniGameWireCut, "Rugged EOD Controller"] call Waldo_fnc_MiniGameRegisterChallenge;
    ["minesweeper", Waldo_fnc_MiniGameMinesweeper, "Ordnance Diagnostic Tablet"] call Waldo_fnc_MiniGameRegisterChallenge;
    ["keypad", Waldo_fnc_MiniGameKeypad, "Industrial Access Terminal"] call Waldo_fnc_MiniGameRegisterChallenge;
    ["lockpick", Waldo_fnc_MiniGameLockpick, "Cutaway Lock Cylinder"] call Waldo_fnc_MiniGameRegisterChallenge;
    ["circuit", Waldo_fnc_MiniGameCircuit, "Breaker and Relay Cabinet"] call Waldo_fnc_MiniGameRegisterChallenge;
    ["repair", Waldo_fnc_MiniGameRepair, "Open Maintenance Hatch"] call Waldo_fnc_MiniGameRegisterChallenge;
    ["radiotune", Waldo_fnc_MiniGameRadioTune, "Tactical Communications Unit"] call Waldo_fnc_MiniGameRegisterChallenge;
    ["pressure", Waldo_fnc_MiniGamePressure, "Hydraulic Control Manifold"] call Waldo_fnc_MiniGameRegisterChallenge;
    ["sequence", Waldo_fnc_MiniGameSequence, "Secure Control Console"] call Waldo_fnc_MiniGameRegisterChallenge;
    missionNamespace setVariable ["Waldo_MG_ChallengesRegistered", true];
};

private _registry = missionNamespace getVariable ["Waldo_MG_ChallengeRegistry", []];
private _opener = {};
private _found = false;
{
    if ((_x select 0) == _challengeId) exitWith {
        _opener = _x select 1;
        _found = true;
    };
} forEach _registry;

if (!_found) exitWith {
    systemChat format ["Field Equipment: unknown procedure '%1'.", _challengeId];
    [_actor, _challengeId, _context] call _onFailure;
    false
};

// Stash the job so the (asynchronous) resolve callback can find its context by token.
private _jobId = missionNamespace getVariable ["Waldo_MG_JobCounter", 0];
missionNamespace setVariable ["Waldo_MG_JobCounter", _jobId + 1];
private _jobVar = format ["Waldo_MG_Job_%1", _jobId];
missionNamespace setVariable [_jobVar, [_actor, _challengeId, _onSuccess, _onFailure, _context]];
missionNamespace setVariable ["Waldo_IMG_ActiveProfile", [_challengeId, _presentation] call Waldo_fnc_MiniGameEquipmentProfile];

// The opener calls [_success] on this; the token is baked in so no closure is needed.
private _resolve = compile format ["[_this select 0, '%1'] call Waldo_fnc_MiniGameChallengeResolve;", _jobVar];

[_config, _resolve] call _opener;
true
