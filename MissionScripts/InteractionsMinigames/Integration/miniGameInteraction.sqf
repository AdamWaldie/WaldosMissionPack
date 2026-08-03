/*
 * Author: WaldoTheWarfighter
 * Generic hook that gates an interaction on an object behind a mini game challenge. Adds an
 * ACE interaction and a linked vanilla addAction that, when used,
 * requests an exclusive server-owned attempt. Passing it fires _onSuccess and failing it fires
 * _onFailure. The callbacks run on the SERVER after broadcast lifecycle state is updated
 * (detonate, unlock a door, complete a task, spawn something, etc.), each receiving
 * [_object, _actor, _success, _result]. Existing three-argument callbacks remain valid.
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
 *                  "actorCondition" Code - actor-aware condition, receives [_object, _actor]
 *                                            on clients and the server (default {true})
 *                  "oneShot"   Bool   - consume the action after one attempt (default true)
 *                  "distance"  Number - addAction fallback radius in metres (default 4)
 *                  "lockTimeout" Number - abandoned lock timeout in seconds (default 600)
 *                  "directAceAction" Bool - attach directly beneath ACE Main Actions instead of
 *                                             the Field Equipment category (default false)
 *                  "installAction" Bool - install the framework action; false stores the
 *                                           procedure for a feature-owned action (default true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [this, "minesweeper", [3], { (_this#0) setVariable ["hacked", true, true]; }, {}] call Waldo_fnc_MiniGameInteraction;
 *
 * Current callers: MiniGameInteractionSetup and direct Eden feature integrations.
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
private _actorCondition = ["actorCondition", {true}] call _opt;
private _distance = ["distance", 4] call _opt;
private _presentation = ["presentation", []] call _opt;
private _directAceAction = ["directAceAction", false] call _opt;
private _installAction = ["installAction", true] call _opt;

// Hold the challenge definition + authoritative callbacks on the object (local to each
// machine, including the server that will run the callbacks).
_object setVariable ["Waldo_MG_Int_ChallengeId", _challengeId];
_object setVariable ["Waldo_MG_Int_Config", _config];
_object setVariable ["Waldo_MG_Int_OnSuccess", _onSuccess];
_object setVariable ["Waldo_MG_Int_OnFailure", _onFailure];
_object setVariable ["Waldo_MG_Int_Options", _options];
_object setVariable ["Waldo_MG_Int_Condition", _condition];
_object setVariable ["Waldo_MG_Int_ActorCondition", _actorCondition];
_object setVariable ["Waldo_IMG_Presentation", _presentation];
_object setVariable ["Waldo_MG_Int_Distance", _distance];
if (isServer && {isNil { _object getVariable "Waldo_MG_Int_Active" }}) then {
    _object setVariable ["Waldo_MG_Int_Active", true, true];
};
if (isServer && {isNil {_object getVariable "Waldo_MG_InteractionState"}}) then {
    private _initialResult = ["IDLE", "", "", _challengeId, objNull, "", -1, -1];
    _object setVariable ["Waldo_MG_InteractionState", "IDLE", true];
    _object setVariable ["Waldo_MG_InteractionResult", _initialResult, true];
    _object setVariable ["Waldo_MG_InteractionComplete", false, true];
    _object setVariable ["Waldo_MG_InteractionFailed", false, true];
    _object setVariable [format ["Waldo_MG_%1Complete", _challengeId], false, true];
};

// No local UI on a headless client / dedicated server - it only keeps the callbacks.
if (!hasInterface) exitWith {};

private _aceAvailable = isClass (configFile >> "CfgPatches" >> "ace_interact_menu") && {!(isNil "ace_interact_menu_fnc_createAction")} && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
_object setVariable ["Waldo_MG_Int_ACEAvailable", _aceAvailable];

// Reconcile title/layout changes instead of leaving stale or empty category nodes after a
// runtime reconfiguration. Only this feature's recorded action paths are removed.
private _layoutSignature = [_challengeId, _title, _directAceAction, _installAction];
private _oldLayoutSignature = _object getVariable ["Waldo_MG_Int_LocalLayoutSignature", []];
if !(_oldLayoutSignature isEqualTo _layoutSignature) then {
    if (_aceAvailable && {!(isNil "ace_interact_menu_fnc_removeActionFromObject")}) then {
        private _oldActionPath = _object getVariable ["Waldo_MG_Int_ACEActionPath", []];
        if (count _oldActionPath > 0) then {
            [_object, 0, _oldActionPath] call ace_interact_menu_fnc_removeActionFromObject;
        };
        private _oldCategoryPath = _object getVariable ["Waldo_MG_Int_ACECategoryPath", []];
        if (count _oldCategoryPath > 0) then {
            [_object, 0, _oldCategoryPath] call ace_interact_menu_fnc_removeActionFromObject;
        };
    };
    private _oldVanillaId = _object getVariable ["Waldo_MG_Int_ActionId", -1];
    if (_oldVanillaId >= 0) then {_object removeAction _oldVanillaId;};
    _object setVariable ["Waldo_MG_Int_ACEActionInstalled", false];
    _object setVariable ["Waldo_MG_Int_ACECategoryInstalled", false];
    _object setVariable ["Waldo_MG_Int_ACEActionPath", []];
    _object setVariable ["Waldo_MG_Int_ACECategoryPath", []];
    _object setVariable ["Waldo_MG_Int_VanillaActionInstalled", false];
    _object setVariable ["Waldo_MG_Int_ActionId", -1];
};
_object setVariable ["Waldo_MG_Int_LocalLayoutSignature", _layoutSignature];

if (_installAction && {_aceAvailable} && {!(_object getVariable ["Waldo_MG_Int_ACEActionInstalled", false])}) then {
    if (!_directAceAction && {!(_object getVariable ["Waldo_MG_Int_ACECategoryInstalled", false])}) then {
        private _category = [
            "Waldo_MG_FieldEquipment",
            "Field Equipment",
            "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\interact_ca.paa",
            {true},
            {true}
        ] call ace_interact_menu_fnc_createAction;
        private _categoryPath = [_object, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject;
        _object setVariable ["Waldo_MG_Int_ACECategoryInstalled", true];
        _object setVariable ["Waldo_MG_Int_ACECategoryPath", _categoryPath];
    };
    private _action = [
        format ["Waldo_MG_Interact_%1", _challengeId],
        _title,
        _icon,
        {
            params ["_target", "_actor"];
            _target setVariable ["Waldo_MG_Int_LastLocalActionInvocation", [diag_tickTime, clientOwner, netId _actor]];
            diag_log format ["[WMP INTERACTION] ACE action invoked object=%1 actor=%2 clientOwner=%3", netId _target, name _actor, clientOwner];
            _target call Waldo_fnc_MiniGameInteractionActivate;
        },
        {
            params ["_target", "_actor"];
            if (isNull _actor || {!alive _actor} || {(lifeState _actor) == "INCAPACITATED"}) exitWith {false};
            if (([_target, _actor] call Waldo_fnc_MiniGameInteractionRange) > (_target getVariable ["Waldo_MG_Int_Distance", 4])) exitWith {false};
            if !(_target getVariable ["Waldo_MG_Int_Active", true]) exitWith { false };
            if ((_target getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "RUNNING") exitWith { false };
            private _c = _target getVariable ["Waldo_MG_Int_Condition", {true}];
            if !(_target call _c) exitWith {false};
            private _actorCondition = _target getVariable ["Waldo_MG_Int_ActorCondition", {true}];
            [_target, _actor] call _actorCondition
        },
        {},
        [],
        {[0, 0, 0]},
        _distance
    ] call ace_interact_menu_fnc_createAction;
    private _parentPath = if (_directAceAction) then {["ACE_MainActions"]} else {["ACE_MainActions", "Waldo_MG_FieldEquipment"]};
    private _actionPath = [_object, 0, _parentPath, _action] call ace_interact_menu_fnc_addActionToObject;
    _object setVariable ["Waldo_MG_Int_ACEActionInstalled", true];
    _object setVariable ["Waldo_MG_Int_ACEActionPath", _actionPath];
    _object setVariable ["Waldo_MG_Int_ACEAction", _action];
};

// Field equipment remains visible through the vanilla action menu even when
// ACE is loaded. This is an intentional discoverability surface; both routes
// enter the same server acquisition handshake and cannot bypass authority.
if (_installAction && {!(_object getVariable ["Waldo_MG_Int_VanillaActionInstalled", false])}) then {
    private _id = _object addAction [
        _title,
        { (_this select 0) call Waldo_fnc_MiniGameInteractionActivate; },
        [],
        1.5,
        true,
        true,
        "",
        "(_target getVariable ['Waldo_MG_Int_Active', true]) && {(_target getVariable ['Waldo_MG_InteractionState', 'IDLE']) != 'RUNNING'} && {_target call (_target getVariable ['Waldo_MG_Int_Condition', {true}])} && {[_target, _this] call (_target getVariable ['Waldo_MG_Int_ActorCondition', {true}])} && {[_target, _this] call Waldo_fnc_MiniGameInteractionRange < (_target getVariable ['Waldo_MG_Int_Distance', 4])}",
        _distance
    ];
    _object setVariable ["Waldo_MG_Int_ActionId", _id];
    _object setVariable ["Waldo_MG_Int_VanillaActionInstalled", _id >= 0];
};

_object setVariable ["Waldo_MG_Int_InteractionMode", if (!_installAction) then {"FEATURE_ACTION"} else {if (_aceAvailable) then {"ACE+VANILLA"} else {"VANILLA"}}];

private _conditionReady = _object call _condition;
private _actorReady = [_object, player] call _actorCondition;
diag_log format ["[WMP INTERACTION] local setup object=%1 challenge=%2 title=%3 installAction=%4 direct=%5 ACE=%6 path=%7 vanilla=%8 active=%9 state=%10 range=%11 featureReady=%12 actorReady=%13 clientOwner=%14 objectLocal=%15 objectOwner=%16", netId _object, _challengeId, _title, _installAction, _directAceAction, _object getVariable ["Waldo_MG_Int_ACEActionInstalled", false], _object getVariable ["Waldo_MG_Int_ACEActionPath", []], _object getVariable ["Waldo_MG_Int_VanillaActionInstalled", false], _object getVariable ["Waldo_MG_Int_Active", true], _object getVariable ["Waldo_MG_InteractionState", "IDLE"], _distance, _conditionReady, _actorReady, clientOwner, local _object, owner _object];
