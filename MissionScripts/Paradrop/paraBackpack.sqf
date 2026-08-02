/*
 * Author: WaldoTheWarfighter
 * Saves a local jumper's backpack class and contents, equips a selected steerable parachute
 * backpack, and installs a repeat-safe landing action that restores their pack and walking state.
 *
 * Arguments:
 * 0: jumping unit <OBJECT>
 * 1: parachute backpack class <STRING> (default "B_Parachute")
 *
 * Return Value:
 * Boolean - true when the parachute backpack and restoration action were installed.
 *
 * Called by:
 * Waldo_fnc_HaloJumpFunc after aircraft exit.
 *
 * Example:
 * [player, "B_Parachute"] call Waldo_fnc_ParaBackpack;
 */

params [
    ["_player", objNull],
    ["_chuteBackpackClass", "B_Parachute"]
];

if (isNull _player || {!local _player} || {!(isClass (configFile >> "CfgVehicles" >> _chuteBackpackClass))}) exitWith {false};

private _backpack = backpack _player call BIS_fnc_basicBackpack;

private _cargo = backpackItems _player;

private _backpackAndContent = [_backpack, _cargo];

_player setVariable ["Waldo_Paradrop_dropPackContent", _backpackAndContent];

removeBackpack _player;
_player addBackpack _chuteBackpackClass;

_player forceWalk true;

private _oldAction = _player getVariable ["Waldo_Paradrop_RestoreBackpackAction", -1];
if (_oldAction >= 0) then {[_player, _oldAction] call BIS_fnc_holdActionRemove};
private _actionId = [
    _player,
    "Ditch Chute And Put On Backpack",
    "\a3\ui_f\data\igui\cfg\holdactions\holdAction_loaddevice_ca.paa",
    "\a3\ui_f\data\igui\cfg\holdactions\holdAction_loaddevice_ca.paa",
    format["((count (_this getVariable ['%1', []])) > 1) && ((getPosATL _this)#2 < 2)","Waldo_Paradrop_dropPackContent"],
    format["((count (_caller getVariable ['%1', []])) > 1) && ((getPosATL _caller)#2 < 5)","Waldo_Paradrop_dropPackContent"],
    {},
    {},
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        private _backpackAndContent = _caller getVariable ["Waldo_Paradrop_dropPackContent", []];
        _backpackAndContent params [
            ["_backpack", ""],
            ["_cargo", []]
        ];

        removeBackpack _caller;
        if (_backpack != "") then {_caller addBackpack _backpack};

        {
            _caller addItemToBackpack _x;
        } forEach _cargo;

        _caller setVariable ["Waldo_Paradrop_dropPackContent", nil];
        _caller setVariable ["Waldo_Paradrop_RestoreBackpackAction", -1];

        _caller forceWalk false;
    },
    {},
    [],
    5,
    0,
    false,
    false
] call BIS_fnc_holdActionAdd;
_player setVariable ["Waldo_Paradrop_RestoreBackpackAction", _actionId];
true
