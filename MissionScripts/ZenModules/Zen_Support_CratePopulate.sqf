/*
This function grabs all magazines in all player weapons, gets uniques,and then places a scalar influence number into a crate.

Called via Zen Module ONLY.

*/

params ["_crate", "_scalar"];

clearweaponcargoGlobal _crate;
clearmagazinecargoGlobal _crate;
clearitemcargoGlobal _crate;
clearbackpackcargoGlobal _crate;

Private _CountablePlayers = allPlayers;
private _ammoboxitems = [];
{
    _ammoboxitems append magazines _x; 
} forEach _CountablePlayers;
_ammoboxitems = str _ammoboxitems splitString "[]," joinString ",";
_ammoboxitems = parseSimpleArray ("[" + _ammoboxitems + "]");
_ammoboxitems = _ammoboxitems arrayIntersect _ammoboxitems select {_x isEqualType "" && {_x != ""}};
private _arrayLength = count _ammoboxitems; 
private _ammoCountArray = [];
{
   _randomInt  = [10,40] call BIS_fnc_randomInt;
    _crate addMagazineCargoGlobal [_x, (_scalar * _randomInt)]
} forEach _ammoboxitems;

_crate addBackpackCargoGlobal ["B_Kitbag_cbr",4];
_crate addItemCargoGlobal ["ACE_EarPlugs", (25)];
_crate addItemCargoGlobal ["ACE_quikclot", (100)];
_crate addItemCargoGlobal ["ACE_tourniquet", (36)];
_crate addItemCargoGlobal ["ACE_personalAidKit", (20)];

[_crate, 1] call ace_cargo_fnc_setSize;
[_crate, true] call ace_dragging_fnc_setDraggable;
[_box, true] call ace_dragging_fnc_setCarryable;