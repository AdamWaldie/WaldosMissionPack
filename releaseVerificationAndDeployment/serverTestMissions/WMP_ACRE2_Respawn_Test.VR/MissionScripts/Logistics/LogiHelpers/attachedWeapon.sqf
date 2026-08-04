/*
This script attached an object (weapon) to a vehicle object, as well as providing a method to switch into the mounted weapon from the vehicle it is attached to.

parameters:
_turret - variable name of the turret.
_vehicle - variable name of the vehicle you wish to attach the turret to.
_customName - set a custom Get in X addaction for the turret, where X is the contents of _customName.

Example call:

In turret init:

[turretVariableName,VehiclevariableName,"Custom Name For Turret"] call Waldo_fnc_VehicleMountedWeapon;

*/

params["_turret","_vehicle",["_customName","Turret"]];

//Attach the thing to the thing!
0 = [_turret, _vehicle, true] call BIS_fnc_attachToRelative;


if (isClass(configFile >> "CfgPatches" >> "ace_main")) then {
//Prevent other ACE interaction claims
  [_turret, _turret] call ace_common_fnc_claim; // prevent other ACE Options While connected to the object on start
};

//Prevent whacky things from happening by denying special actions from IFA3 & other mods
inGameUISetEventHandler ["action",  
  " _action = _this select 4;  
    if ( _action in ['Unmount','Turn left','Turn right'] ) then { 
        hint 'You cannot do that!'; 
        true 
    } else { 
        false 
    } 
  "  
];

//Set custom title for addaction
private _formattedTurretString = format ["Get In %1",_customName];

//Outside to attached weapon
_turret addAction [_formattedTurretString,{
  params ["_target", "_caller", "_actionId", "_arguments"];
  _arguments params["_turret","_vehicle"];
  moveOut (_this select 1);(_this select 1) moveingunner _turret;
},[_turret,_vehicle],1.5,true,true,"","!(_this in (crew _target));",4,false,"",""];

//From vehicle to attached weapon
_vehicle addAction [_formattedTurretString,{
  params ["_target", "_caller", "_actionId", "_arguments"];
  _arguments params["_turret","_vehicle"];
  moveOut (_this select 1);(_this select 1) moveingunner _turret;
},[_turret,_vehicle],1.5,true,true,"","_this in (crew _target);",4,false,"",""];

//From attached weapon to vehicle
_turret addAction ["Return To Main Vehicle",{
  params ["_target", "_caller", "_actionId", "_arguments"];
  _arguments params["_turret","_vehicle"];
  moveOut (_this select 1);(_this select 1) moveInAny _vehicle;
},[_turret,_vehicle],1.5,true,true,"","_this in (crew _target);",4,false,"",""];