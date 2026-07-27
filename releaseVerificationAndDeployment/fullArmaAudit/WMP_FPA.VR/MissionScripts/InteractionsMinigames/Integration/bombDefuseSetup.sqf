/*
 * Author: WaldoTheWarfighter
 * Turns any object into a defusable bomb using the same high-level field-equipment setup,
 * presentation profiles, difficulty presets, authoritative lifecycle and ACE/vanilla actions as
 * every other interaction procedure. Passing disarms the device; failing it (wrong wire, timeout
 * or abort) can detonate it. All outcomes are applied on the server.
 *
 * Call from the object's Eden "Initialization" field so it runs on every machine.
 *
 * Arguments:
 * _object  - Object - the device
 * _options - Array/HashMap - named settings accepted by MiniGameInteractionSetup, plus:
 *              "challengeId"       String - any built-in interaction procedure (default "wirecut")
 *              "title"             String - action text (default "Defuse Bomb")
 *              "actionTitle"       String - action text; preferred hashmap key
 *              "equipmentTitle"    String - controller faceplate (default "EOD CONTROLLER")
 *              "wireCount"         Number - wires shown, 3..6 (default 5)
 *              "timeLimit"         Number - seconds on the clock, 0 = none (default 20)
 *              "verificationLevel" Number - required identity checks, 1..4 (default derived)
 *              "difficulty"        String - easy/standard/hard/expert; used when no explicit
 *                                             wire/time/verification/config override is supplied
 *              "detonateOnFailure" Bool   - explode on failure (default true)
 *              "explosive"         String - ammo/magazine class spawned to detonate
 *                                            (default "IEDLandBig_Remote_Ammo")
 *              "defusedVariable"   String - object var set true on success (default "Waldo_MG_BombDefused")
 *              "successVariable"   String - shared API success variable; overrides defusedVariable
 *              "oneShot"           Bool   - single attempt (default true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [this] call Waldo_fnc_BombDefuseSetup;
 * [this, [["wireCount", 6], ["timeLimit", 15]]] call Waldo_fnc_BombDefuseSetup;
 */

params [
    ["_object", objNull, [objNull]],
    ["_options", [], [[], createHashMap]]
];

if (isNull _object) exitWith {};

private _optionPairs = [];
if (typeName _options == "HASHMAP") then {
    {_optionPairs pushBack [_x, _options get _x];} forEach keys _options;
} else {
    _optionPairs = +_options;
};
private _opt = {
    params ["_k", "_def"];
    private _r = _def;
    {if ((_x param [0, ""]) == _k) exitWith {_r = _x param [1, _def];};} forEach _optionPairs;
    _r
};
private _has = {
    params ["_key"];
    (_optionPairs findIf {(_x param [0, ""]) == _key}) >= 0
};

private _title = ["title", "Defuse Bomb"] call _opt;
private _actionTitle = ["actionTitle", _title] call _opt;
private _challengeId = toLower (["challengeId", ["procedure", "wirecut"] call _opt] call _opt);
private _equipmentTitle = ["equipmentTitle", if (_challengeId == "wirecut") then {"EOD CONTROLLER"} else {""}] call _opt;
private _wireCount = ["wireCount", 5] call _opt;
private _timeLimit = ["timeLimit", 20] call _opt;
private _verificationLevel = ["verificationLevel", -1] call _opt;
private _detonate = ["detonateOnFailure", true] call _opt;
private _explosive = ["explosive", "IEDLandBig_Remote_Ammo"] call _opt;
private _legacyDefusedVariable = ["defusedVariable", "Waldo_MG_BombDefused"] call _opt;
private _successVariable = ["successVariable", _legacyDefusedVariable] call _opt;
private _oneShot = ["oneShot", true] call _opt;
private _customSuccess = ["onSuccess", {}] call _opt;
private _customFailure = ["onFailure", {}] call _opt;

// Detonation parameters live on the object so the (asynchronous, server-side) callbacks can
// read them without capturing this scope.
_object setVariable ["Waldo_MG_Bomb_Detonate", _detonate, true];
_object setVariable ["Waldo_MG_Bomb_Explosive", _explosive, true];
_object setVariable ["Waldo_MG_Bomb_DefusedVar", _successVariable, true];
_object setVariable ["Waldo_MG_Bomb_OnSuccess", _customSuccess];
_object setVariable ["Waldo_MG_Bomb_OnFailure", _customFailure];

private _onSuccess = {
    params ["_obj", "_actor", "_success", ["_result", []]];
    private _var = _obj getVariable ["Waldo_MG_Bomb_DefusedVar", "Waldo_MG_BombDefused"];
    if (_var != "") then {_obj setVariable [_var, true, true];};
    _obj setVariable ["Waldo_MG_BombDefused", true, true];
    [format ["%1 defused the device.", name _actor]] remoteExec ["systemChat", 0];
    [_obj, _actor, _success, _result] call (_obj getVariable ["Waldo_MG_Bomb_OnSuccess", {}]);
};

private _onFailure = {
    params ["_obj", "_actor", "_success", ["_result", []]];
    [format ["%1 failed the defusal procedure.", name _actor]] remoteExec ["systemChat", 0];
    [_obj, _actor, _success, _result] call (_obj getVariable ["Waldo_MG_Bomb_OnFailure", {}]);
    if (_obj getVariable ["Waldo_MG_Bomb_Detonate", true]) then {
        private _mag = _obj getVariable ["Waldo_MG_Bomb_Explosive", "IEDLandBig_Remote_Ammo"];
        private _pos = getPosATL _obj;
        diag_log format ["[WMP INTERACTION] detonating failed EOD device class=%1 position=%2 actor=%3", _mag, _pos, name _actor];
        deleteVehicle _obj;
        private _boom = createVehicle [_mag, _pos, [], 0, "CAN_COLLIDE"];
        _boom setPosATL _pos;
        // Creating mine/IED ammo does not consistently detonate it immediately.
        // Damage the spawned charge explicitly so a failed live procedure always
        // produces the documented consequence on the authoritative server.
        _boom setDamage 1;
    };
};

private _setup = createHashMapFromArray [
    ["actionTitle", _actionTitle],
    ["successVariable", _successVariable],
    ["oneShot", _oneShot],
    ["retryOnFailure", ["retryOnFailure", !_oneShot] call _opt],
    ["repeatable", ["repeatable", false] call _opt],
    ["distance", ["distance", 4] call _opt],
    ["lockTimeout", ["lockTimeout", 600] call _opt],
    ["condition", ["condition", {true}] call _opt],
    ["icon", ["icon", "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"] call _opt],
    ["onSuccess", _onSuccess],
    ["onFailure", _onFailure]
];
if (_equipmentTitle != "") then {_setup set ["title", _equipmentTitle];};

// Explicit legacy mechanics retain their exact configuration. If the mission maker supplies only
// a difficulty, use the same curated EOD difficulty profile as the generic equipment setup.
private _explicitMechanics = (["wireCount"] call _has) || {(["timeLimit"] call _has)} || {(["verificationLevel"] call _has)};
if (["config"] call _has) then {
    _setup set ["config", ["config", []] call _opt];
} else {
    if (_challengeId == "wirecut" && {_explicitMechanics || {!(["difficulty"] call _has)}}) then {
        _setup set ["config", [_wireCount, _timeLimit, _equipmentTitle, _verificationLevel]];
    } else {
        _setup set ["difficulty", ["difficulty", "standard"] call _opt];
    };
};

{
    private _key = _x;
    if ([_key] call _has) then {_setup set [_key, [_key, ""] call _opt];};
} forEach [
    "preset", "manufacturer", "model", "objective", "activation", "briefing", "controls",
    "hint", "statusText", "successText", "failureText", "timeoutText", "abortText", "texture",
    "texturePreset", "textureOpacity", "soundProfile", "skin", "failureVariable"
];

[_object, _challengeId, _setup] call Waldo_fnc_MiniGameInteractionSetup;
