/*
Author: Waldo (Various Authors credited for the differing GUI and code snippets which make up this script)

This script initlises a virtual vehicle depot spawner. At present this script is incomplete and is WIP. It is released as is to allow for my co-operators to see how the script progresses.

Arguments:
_depotSpawnerObject - The item to add the spawner addactions onto
_depotSpawnPoint - Should be a helipad, but a flat object ontop of which the vehicle will be spawned
_types - what should be allowed to be selected from this specifc spawner, multiple can be given - Potential arguments: ["Auto","All","Car", "Tank", "Helicopter", "Plane", "Ship", "StaticWeapon"] "Auto" will look at the ground beneath it and select a type based on that.
_sidesToAllowUseOfSpawner - Sides allowed to use the spawner - Potential Arguments: ["BLUFOR","OPFOR","INDEP", "CIV", "ALL"]
_enforcePlayerSideToAccess - enforce that players must match the side of the spawner to get the vehicles
_limitToSideVehicles - limit vehicles able to be spawned (but not viewed) to that matching the player side (Finicky and 50/50 working) Reccomend leave as false.
_removeUavs - remove UAVs from the spawner (80/20 as to whether it works depending on mod setup)
_range - range from which you can view the interactions on the spawner
_script - script to apply directly to the spawned vehicle, bypassing the garage.


Example call:

[this, Circle_Helipad, ["All"], ["ALL"], false, false, false, 10, ""] call Waldo_fnc_VVDInit; // Fully unrestricted, default call.

*/

disableserialization;
params[["_depotSpawnerObject", objNull], ["_depotSpawnPoint", objNull], ["_types", ["Auto"]], ["_sidesToAllowUseOfSpawner", ["ALL"]], ["_enforcePlayerSideToAccess",false], ["_limitToSideVehicles",false], ["_removeUavs",false], ["_range", 10], ["_script", ""]];

_depotSpawnPointName = format["%1", _depotSpawnPoint];
missionNamespace setVariable [format["Garage_Script_%1", _depotSpawnPointName], _script];

_arrayGround = ["Car", "Tank", "Helicopter", "Plane", "StaticWeapon"];

//If Auto, set array depending on the point's surface.
switch (_types select 0) do {
  case "Auto": {
    _types = [_arrayGround, ["Ship"]] select (surfaceIsWater (getPos _depotSpawnPoint));
  };
  case "Ground": {
    _types = _arrayGround;
  };
  case "All": {
    _types = ["Car", "Tank", "Helicopter", "Plane", "Ship", "StaticWeapon"];
  };
};

//icon
_markerDesign = "respawn_unknown";
if (count _types == 1) then {
  _markerDesign = switch (_types select 0) do {
    case "Car": {
      "respawn_motor";
    };
    case "Tank": {
      "respawn_armor";
    };
    case "Helicopter": {
      "respawn_air";
    };
    case "Plane": {
      "respawn_plane";
    };
    case "Ship": {
      "respawn_naval";
    };
    default {
      "respawn_unknown";
    };
  };
};

//Set markers
_markerRange = createMarker [format["Marker_%1_Range", _depotSpawnPointName], _depotSpawnPoint];
_markerRange setMarkerShape "ELLIPSE";
_markerRange setMarkerSize [10,10];

_markerPointName = ((_depotSpawnPointName splitString "_")) joinString " ";
_markerName = createMarker [format["Marker_%1_Name", _depotSpawnPointName], _depotSpawnPoint];
_markerName setMarkerText _markerPointName;
_markerName setMarkerType _markerDesign;

_depotSpawnerObject addAction [format["<t color='#FFFF00'>Open Garage %1</t>", _markerPointName], {
    _params = _this select 3;
    _sides = _params select 2;
    _enforcedPlayerSide = _params select 3;
    _remUAV = _params select 4;

    _sideText = switch (side player) do {
      case west; case blufor : {"BLUFOR"};
      case east; case opfor : {"OPFOR";};
      case independent; case resistance : {"INDEP";};
      case civilian : {"CIV";};
      default {"NONE";};
    };

    if (((_sides select 0) == "ALL" || _sideText in _sides) || _enforcedPlayerSide == false) then {
      [_params select 0, _params select 1] call Waldo_fnc_VVDOpen;
    } else {
      ["This Spawner is Not Available To Your Side"] call BIS_fnc_guiMessage;
    };
  },
  [_depotSpawnPoint, _types, _sidesToAllowUseOfSpawner,_enforcePlayerSideToAccess,_removeUavs],
  1.5,
  true,
  true,
  "",
  "true",
  _range
];

_depotSpawnerObject addAction[format["<t color='#00ffff'>Delete Vehicles %1</t>", _markerPointName],{
    _vehicles = ((_this select 3) nearObjects ["AllVehicles", 10]) + ((_this select 3) nearObjects ["#particlesource", 20]);

    {
      _nowvehicle = _x;
      _vehVarName = vehicleVarName _nowvehicle;
      _defaultVeh = "DFV" in (_vehVarName splitString "_");
      if (!(_x isKindOf "Man") && !_defaultVeh) then
      {
        {_nowvehicle deleteVehicleCrew _x} forEach crew _nowvehicle;
        deleteVehicle _x;
      };
    } forEach _vehicles;

  },
  _depotSpawnPoint,
  1.5,
  true,
  true,
  "",
  "true",
  _range
];

_depotSpawnerObject addAction["<t color='#ff0000'>Reset Garage Flag</t>",{
    _marker = vehicleVarName (_this select 3);
    missionNamespace setVariable [format["Open_Garage_%1", _marker], false, true];
  },
  _depotSpawnPoint,
  1.5,
  true,
  true,
  "",
  "true",
  _range
];
