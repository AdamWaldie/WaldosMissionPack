/*
This function adds a "move-in-cargo" teleporter to an object, which allows a player to use an addaction to board an aircraft already in the air. Useful for shortening drop times.

Arguments:
0: Teleporter Object
1: Aircraft variable Name To Teleport Into
2: Custom String Name For the Plane (Optional)

Example:
[this,aircraft] call Waldo_fnc_MoveInCargoPlane;
[this,aircraft,"ARGUS 1-4"] call Waldo_fnc_MoveInCargoPlane;

*/


params["_teleporter","_aircraftToMoveInto",["_customName","Plane"]];

//Set custom title for addaction
private _formattedPlaneName = format ["Board Into %1",_customName];

_teleporter addAction[_formattedPlaneName, {
    params ["_target", "_caller", "_actionId", "_arguments"];
    _arguments params ["_aircraftToMoveInto"];
    player moveIncargo _aircraftToMoveInto;
},_aircraftToMoveInto];