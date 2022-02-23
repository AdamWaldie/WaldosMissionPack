/*
This function populates an supply crate, with basic medical supplied (quickclot & splints) based on players magazines & weaponry
Includes functionality for

Params:
_crate - object to populate (Passed from module where thee classname of the box is defined)
_scalar - scalar value to multiply medical supplycompliment

Where the call is as follows:

[_crate, _size] call Waldo_fnc_SupplyCratePopulate;

e.g.

[this, 1] call Waldo_fnc_SupplyCratePopulate;

Called via Zen Module as defined in Zen_medicalCrateModule.sqf

*/

params ["_crate", ["_scalar",1]];

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
   _randomInt  = [40,60] call BIS_fnc_randomInt;
    _crate addMagazineCargoGlobal [_x, (_scalar * _randomInt)]
} forEach _ammoboxitems;

//Get selection of Player Launchers
private _playerPrimaryAndSidearm = [];
private _launcherAmmo = [];
private _launchers = [];
{ 
    _playerPrimaryAndSidearm append [primaryWeapon _x];
    _playerPrimaryAndSidearm append [handgunWeapon _x];
    _launchers append [secondaryWeapon _x]; 
    _launcherAmmo append [secondaryWeaponMagazine  _x];
} forEach _CountablePlayers;
_launchers = str _launchers splitString "[]," joinString ",";
_launchers = parseSimpleArray ("[" + _launchers + "]");
_launchers = _launchers arrayIntersect _launchers select {_x isEqualType "" && {_x != ""}};
_launcherAmmo = str _launcherAmmo splitString "[]," joinString ",";
_launcherAmmo = parseSimpleArray ("[" + _launcherAmmo + "]");
_launcherAmmo = _launcherAmmo arrayIntersect _launcherAmmo select {_x isEqualType "" && {_x != ""}};
{
    _crate addWeaponCargoGlobal [_x,[6,8] call BIS_fnc_randomInt];
} forEach _launchers;
{
    _crate addMagazineCargoGlobal [_x,[8,10] call BIS_fnc_randomInt];
} forEach _launcherAmmo;
{
    _crate addWeaponCargoGlobal [_x,[1,3] call BIS_fnc_randomInt];
} forEach _playerPrimaryAndSidearm;

//Add some damn backpacks
_crate addBackpackCargoGlobal ["B_Kitbag_cbr",4];

_crate addItemCargoGlobal ["ACE_EarPlugs", (20)];
_crate addItemCargoGlobal ["ACE_quikclot", (40)];
_crate addItemCargoGlobal ["ACE_tourniquet", (20)];
_crate addItemCargoGlobal ["ACE_personalAidKit", (5)];

[_crate, 1] call ace_cargo_fnc_setSize;
[_crate, true] call ace_dragging_fnc_setDraggable;
[_crate, true] call ace_dragging_fnc_setCarryable;