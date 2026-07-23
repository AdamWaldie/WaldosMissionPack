/*
 * Author: Waldo
 * Generic hook that gates an interaction on an object behind a mini game challenge. Adds an
 * ACE self-interaction (or a vanilla addAction fallback when ACE is absent) that, when used,
 * runs the chosen challenge for that player; passing it fires _onSuccess and failing it fires
 * _onFailure. The callbacks run on the SERVER so they can drive authoritative outcomes
 * (detonate, unlock a door, complete a task, spawn something, etc.), each receiving
 * [_object, _actor, _success].
 *
 * Call this from the object's Eden "Initialization" field so it runs on every machine (each
 * client adds the action locally and the server keeps the callbacks) - the same pattern as
 * Waldo_fnc_MHQSetup. Bomb defusal (Waldo_fnc_BombDefuseSetup) is a ready-made wrapper over
 * this; use this directly for anything else.
 *
 * Arguments:
 * _object      - Object - the interacted object
 * _challengeId - String - registered challenge id (default "wirecut")
 * _config      - Array  - challenge config passed to the opener (default [])
 * _onSuccess   - Code   - server-side, receives [_object, _actor, true]  (default {})
 * _onFailure   - Code   - server-side, receives [_object, _actor, false] (default {})
 * _options     - Array  - array of [key, value] pairs, all optional:
 *                  "title"     String - action text (default "Attempt")
 *                  "icon"      String - ACE action icon path (default "")
 *                  "condition" Code   - extra show condition, gets _object as _this (default {true})
 *                  "oneShot"   Bool   - consume the action after one attempt (default true)
 *                  "distance"  Number - addAction fallback radius in metres (default 4)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [this, "minesweeper", [3], { (_this#0) setVariable ["hacked", true, true]; }, {}] call Waldo_fnc_MiniGameInteraction;
 */

params [
    ["_object", objNull, [objNull]],
    ["_challengeId", "wirecut", [""]],
    ["_config", [], [[]]],
    ["_onSuccess", {}, [{}]],
    ["_onFailure", {}, [{}]],
    ["_options", [], [[]]]
];

if (isNull _object) exitWith {};

private _opt = {
    params ["_k", "_def"];
    private _r = _def;
    { if ((_x select 0) == _k) exitWith { _r = _x select 1; }; } forEach _options;
    _r
};

private _title = ["title", "Inspect Equipment"] call _opt;
private _icon = ["icon", ""] call _opt;
private _condition = ["condition", {true}] call _opt;
private _distance = ["distance", 4] call _opt;
private _presentation = ["presentation", []] call _opt;

// Hold the challenge definition + authoritative callbacks on the object (local to each
// machine, including the server that will run the callbacks).
_object setVariable ["Waldo_MG_Int_ChallengeId", _challengeId];
_object setVariable ["Waldo_MG_Int_Config", _config];
_object setVariable ["Waldo_MG_Int_OnSuccess", _onSuccess];
_object setVariable ["Waldo_MG_Int_OnFailure", _onFailure];
_object setVariable ["Waldo_MG_Int_Options", _options];
_object setVariable ["Waldo_MG_Int_Condition", _condition];
_object setVariable ["Waldo_IMG_Presentation", _presentation];
if (isNil { _object getVariable "Waldo_MG_Int_Active" }) then {
    _object setVariable ["Waldo_MG_Int_Active", true, true];
};

// No local UI on a headless client / dedicated server - it only keeps the callbacks.
if (!hasInterface) exitWith {};

if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _action = [
        "Waldo_MG_Interact",
        _title,
        _icon,
        { (_this select 0) call Waldo_fnc_MiniGameInteractionActivate; },
        {
            params ["_target"];
            if !(_target getVariable ["Waldo_MG_Int_Active", true]) exitWith { false };
            private _c = _target getVariable ["Waldo_MG_Int_Condition", {true}];
            _target call _c
        }
    ] call ace_interact_menu_fnc_createAction;
    [_object, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
} else {
    private _id = _object addAction [
        _title,
        { (_this select 0) call Waldo_fnc_MiniGameInteractionActivate; },
        [],
        1.5,
        true,
        true,
        "",
        "(_target getVariable ['Waldo_MG_Int_Active', true]) && {_target call (_target getVariable ['Waldo_MG_Int_Condition', {true}])} && {_this distance _target < (_target getVariable ['Waldo_MG_Int_Distance', 4])}",
        _distance
    ];
    _object setVariable ["Waldo_MG_Int_Distance", _distance];
    _object setVariable ["Waldo_MG_Int_ActionId", _id];
};
