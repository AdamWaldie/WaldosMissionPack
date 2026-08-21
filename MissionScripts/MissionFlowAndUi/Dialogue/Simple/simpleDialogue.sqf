/*
 * Author: WaldoTheWarfighter
 * Registers beginner-friendly random or specific dialogue on one NPC, group, or object array.
 * Locality/authority: registration is server-only; Eden object init fields safely execute this on
 * every machine because non-server copies exit without broadcasting code.
 * Repeat/JIP behaviour: replaces the same speaker registration and republishes one ordered snapshot.
 * Arguments: compact forms [target, archetypeOrTextOrLines], or legacy-compatible target, class,
 * specific STRING/ARRAY, completion CODE, remove-after-use BOOL. Return Value: BOOL.
 * Current callers: Eden object init fields, triggers, scripts and dialogue ZEN adapters.
 * Example: [this, ["Welcome.", "The clinic is ahead."]] call Waldo_fnc_SimpleDialogue;
 */
if (!isServer) exitWith {false};
[] call Waldo_fnc_DialogueBootstrap;
if (count _this < 2) exitWith {diag_log "[WMP DIALOGUE] SimpleDialogue requires a target and dialogue."; false};

private _targetInput = _this select 0;
private _second = _this select 1;
private _archetype = "SPECIFIC";
private _lines = [];
private _onComplete = {};
private _removeAfterUse = false;
private _catalogue = missionNamespace getVariable ["Waldo_Dialogue_Archetypes", createHashMap];

if (_second isEqualType []) then {
    _lines = +_second;
    _onComplete = _this param [2, {}, [{}]];
    _removeAfterUse = _this param [3, false, [true]];
} else {
    if !(_second isEqualType "") exitWith {diag_log "[WMP DIALOGUE] Dialogue must be an archetype ID, text STRING or ARRAY<STRING>."; false};
    private _upper = toUpperANSI _second;
    if !(_upper in keys _catalogue) then {
        if ((_upper find "DORNOW_") == 0) then {["MEDIEVAL_DORNOW"] call Waldo_fnc_DialogueLoadPresetPack};
        if ((_upper find "MODERN_") == 0) then {["MODERN_CIVILIANS"] call Waldo_fnc_DialogueLoadPresetPack};
        _catalogue = missionNamespace getVariable ["Waldo_Dialogue_Archetypes", createHashMap];
    };
    if (_upper == "SPECIFIC") then {
        private _specific = _this param [2, ""];
        _lines = if (_specific isEqualType []) then {+_specific} else {[_specific]};
        _onComplete = _this param [3, {}, [{}]];
        _removeAfterUse = _this param [4, false, [true]];
    } else {
        if (_upper in keys _catalogue) then {
            _archetype = _upper;
            _onComplete = _this param [3, {}, [{}]];
            _removeAfterUse = _this param [4, false, [true]];
        } else {
            _lines = [_second];
            _onComplete = _this param [2, {}, [{}]];
            _removeAfterUse = _this param [3, false, [true]];
        };
    };
};

if (_archetype == "SPECIFIC") then {
    if (count _lines == 0 || {count _lines > 32}) exitWith {diag_log "[WMP DIALOGUE] Specific dialogue requires 1-32 lines."; false};
    private _bad = _lines findIf {!(_x isEqualType "") || {_x == ""} || {count _x > 500}};
    if (_bad >= 0) exitWith {diag_log format ["[WMP DIALOGUE] Invalid specific line at index %1; use non-empty STRING values up to 500 characters.", _bad]; false};
};

private _targets = [_targetInput] call Waldo_fnc_DialogueResolveTargets;
if (count _targets == 0) exitWith {diag_log "[WMP DIALOGUE] No valid speaker objects were supplied."; false};
private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
{
    private _speaker = _x;
    private _key = netId _speaker;
    if (_key == "0:0") then {_key = str _speaker};
    private _entry = createHashMapFromArray [
        ["kind", "SIMPLE"], ["speaker", _speaker], ["archetype", _archetype], ["lines", +_lines],
        ["onComplete", _onComplete], ["removeAfterUse", _removeAfterUse], ["activeSession", ""]
    ];
    _registry set [_key, _entry];
    _speaker setVariable ["Waldo_Dialogue_Available", true, true];
    _speaker setVariable ["Waldo_Dialogue_Occupied", false, true];
} forEach _targets;
missionNamespace setVariable ["Waldo_Dialogue_Registry", _registry];
[] call Waldo_fnc_DialoguePublishState;
diag_log format ["[WMP DIALOGUE] Registered simple dialogue speakers=%1 archetype=%2 removeAfterUse=%3.", count _targets, _archetype, _removeAfterUse];
true
