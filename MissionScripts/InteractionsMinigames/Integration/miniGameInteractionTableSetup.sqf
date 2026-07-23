/*
 * Adds an opt-in Field Equipment picker to a party table without joining its multiplayer
 * vote/ready state. Entries are ids or [id, config, presentation] rows.
 *
 * Example:
 * [this, ["repair", "radiotune", ["circuit", [4,3,0], [["preset","generatorBreaker"]]]]]
 *     call Waldo_fnc_MiniGameInteractionTableSetup;
 */
params [
    ["_table", objNull, [objNull]],
    ["_procedures", ["wirecut", "minesweeper", "keypad", "lockpick", "circuit", "repair", "radiotune", "pressure", "sequence"], [[]]],
    ["_options", [], [[], createHashMap]]
];
if (isNull _table) exitWith {false};

private _normal = [];
{
    if (typeName _x == "STRING") then {
        _normal pushBack [toLower _x, [], []];
    } else {
        if (typeName _x == "ARRAY" && {(count _x) > 0}) then {
            _normal pushBack [toLower (_x param [0, "wirecut"]), _x param [1, []], _x param [2, []]];
        };
    };
} forEach _procedures;
if ((count _normal) == 0) exitWith {false};

_table setVariable ["Waldo_IMG_TableProcedures", _normal];
if (!hasInterface) exitWith {true};
if (_table getVariable ["Waldo_IMG_TableActionInstalled", false]) exitWith {true};
_table setVariable ["Waldo_IMG_TableActionInstalled", true];

private _optionPairs = if (typeName _options == "HASHMAP") then {
    private _pairs = [];
    {_pairs pushBack [_x, _options get _x];} forEach keys _options;
    _pairs
} else {+_options};
private _getOption = {
    params ["_key", "_default"];
    private _value = _default;
    {if ((_x select 0) == _key) exitWith {_value = _x select 1;};} forEach _optionPairs;
    _value
};
private _icon = ["icon", "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa"] call _getOption;
private _actionTitle = ["actionTitle", "Field Equipment"] call _getOption;
private _distance = ["distance", 4] call _getOption;
if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _action = [
        "Waldo_IMG_FieldEquipment",
        _actionTitle,
        _icon,
        {[_this select 0] call Waldo_fnc_MiniGameEquipmentPicker;},
        {
            params ["_target", "_player"];
            !isNull _target && {alive _player} && {isNull (missionNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])}
        }
    ] call ace_interact_menu_fnc_createAction;
    [_table, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
} else {
    private _id = _table addAction [
        _actionTitle,
        {[_this select 0] call Waldo_fnc_MiniGameEquipmentPicker;},
        [], 1.55, true, true, "",
        "isNull (missionNamespace getVariable ['Waldo_MG_ActiveChallengeDisplay', displayNull])",
        _distance
    ];
    _table setVariable ["Waldo_IMG_TableActionId", _id];
};
true
