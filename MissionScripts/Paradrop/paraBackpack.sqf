/*
This saves your current objects inside of your backpack as a variable
And simulate a packpack on your chest. Action is added to allow you to swap back.

Arguments:
0: Player             <PLAYER>
1: ChuteBackpackClass <OBJECT> (Optional) (Default; "B_Parachute")

Example:
["unit"] call Waldo_fnc_ParaBackpack;
["unit", "B_Parachute"] call Waldo_fnc_ParaBackpack;

*/

params [
    ["_player", objNull],
    ["_chuteBackpackClass", "B_Parachute"]
];

private _backpack = backpack _player call BIS_fnc_basicBackpack;

private _cargo = backpackItems _player;

private _backpackAndContent = [_backpack, _cargo];

_player setVariable ["Waldo_Paradrop_dropPackContent", _backpackAndContent];

removeBackpack _player;
_player addBackpack _chuteBackpackClass;

_player forceWalk true;

[
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
        _caller addBackpack _backpack;

        {
            _caller addItemToBackpack _x;
        } forEach _cargo;

        _caller setVariable ["Waldo_Paradrop_dropPackContent", nil];

        _caller forceWalk false;
    },
    {},
    [],
    5,
    0,
    false,
    false
] call BIS_fnc_holdActionAdd;