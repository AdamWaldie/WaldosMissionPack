_Associated Files:_
* _MissionScripts\Paradrop\moveInCargoPlane.sqf_
* _MissionScripts\Logistics\LogiHelpers\teleport.sqf_

Both of these scripts perform teleportation and can be applied to any object. They have been grouped here for convenience.

## Teleport Object
This teleports a target to a given marker or any other kind of object.

Parameters:
* 0: Object <OBJECT>
* 1: Label text <STRING>
* 2: Destination <MARKER/OBJECT/LOCATION/GROUP/TASK>


Examples:
* `[this,"Teleport - Airfield", Airstrip] call Waldo_fnc_Teleport`  <- Arma 3 Map Location (Predefined)
* `[this,"Teleport - Base", MyBase] call Waldo_fnc_Teleport ` <- Object
* `[this,"Teleport - Bart", "FOB_Bart"] call Waldo_fnc_Teleport` <- Arma 3 Map Location (Predefined)
* `[this,"Teleport - Base", "respawn_west"] call Waldo_fnc_Teleport` <- Marker variable name

Please note that this script requires the destination to have a variable name to reference.

## Move-In Cargo Object

This function adds a "move-in-cargo" teleporter to an object, which allows a player to use an addaction to board an aircraft already in the air. Helpful in shortening drop times.

Arguments:
* 0: Teleporter Object
* 1: Aircraft variable Name To Teleport Into
* 2: Custom String Name For the Plane (Optional)

Example:
* `[this, aircraft] call Waldo_fnc_MoveInCargoPlane;`
* `[this, aircraft, "ARGUS 1-4"] call Waldo_fnc_MoveInCargoPlane;`

Please note that this script requires the destination to have a variable name to reference.