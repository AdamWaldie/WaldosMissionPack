/*
 * Author: WaldoTheWarfighter
 * Purpose: Legacy manual static-weapon attachment with named vanilla Get In and Return actions.
 * It does not perform a collision, clearance, or physics safety check.
 * Locality/authority: intended for an Eden turret Init on each machine. It calls BIS relative
 * attachment, installs local addActions, and replaces that client's global action UI handler.
 * Repeat/JIP: no duplicate guard or explicit mount-state replay. A repeated call can add actions
 * again. Eden Init runs for joining clients, but a runtime-spawned pair needs its own JIP setup.
 * Arguments:
 * 0: turret <OBJECT> (required) - existing static weapon to attach.
 * 1: vehicle <OBJECT> (required) - existing carrier object.
 * 2: custom name <STRING> (default "Turret") - Get In action suffix.
 * Return Value: NUMBER - local action ID of the final Return To Main Vehicle action.
 * Current callers: mission-maker Eden turret Init fields and legacy scripted compositions.
 * Example: [mountedM2, truck1, "M2 Browning"] call Waldo_fnc_VehicleMountedWeapon;
 * Result: local Get In and Return actions appear around the manually attached gun.
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
