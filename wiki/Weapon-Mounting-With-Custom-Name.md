_Associated Files: MissionScripts\Logistics\LogiHelpers\attachedWeapon.sqf_

This script attaches an object (weapon) to a vehicle object and provides a method to switch into the mounted weapon from the vehicle it is attached to and vice versa.

Parameters:
* _turret - variable name of the turret.
* _vehicle - variable name of the vehicle you wish to attach the turret to.
* _customName - set a custom Get in X addaction for the turret, where X is the contents of _customName.

Example call:

In turret init:

`[turretVariableName, VehiclevariableName,"Custom Name For Turret"] call Waldo_fnc_VehicleMountedWeapon;`