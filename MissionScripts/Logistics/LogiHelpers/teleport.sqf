/* This teleports a target to a given marker or any other kind of object.
Z will always be 0 for MARKER, LOCATION and TASK.
 *
Parameters:
0: Object <OBJECT>
1: Label text <STRING>
2: Destination <MARKER/OBJECT/LOCATION/GROUP/TASK>


Examples:
[this,"Teleport - Airfield", Airstrip] call Waldo_fnc_Teleport  <- Arma 3 Map Location (Predefined)
[this,"Teleport - Base", MyBase] call Waldo_fnc_Teleport  <- Object
[this,"Teleport - Bart", "FOB_Bart"] call Waldo_fnc_Teleport <- Arma 3 Map Location (Predefined)
[this,"Teleport - Base", "respawn_west"] call Waldo_fnc_Teleport <- Marker variable name
 *
Public: Yes
*/

params [
    ["_object", objNull, [objNull]],
    ["_action", "Teleport"],
    ["_dest", nil, [objNull, grpNull, "", locationNull, taskNull, []]]
];

if (isNil "_dest") then {
    _dest = _object;
};

_object addAction [
    format["<t color='#00cc00'>%1</t>", _action], {
        params ["","","","_dest"];
        private _height = [0,0,0];

        switch (typeName _dest) do {
            case "OBJECT" : {
                _height = getPosASL _dest;
                _height = _height select 2;
            };
            case "GROUP" : {
                _height = getPosASL _dest;
                _height = _height select 2;
            };
            case "STRING" : {
                _height = _height select 2;
            };
            case "LOCATION" : {
                _height = _height select 2;
            };
            case "TASK" : {
                _height = _height select 2;
            };
            default {
                _height = _height select 2;
            };
        };
        titleText ["A few minutes later...", "BLACK OUT", 3];
        //Get offset destination so no on object spawning
        private _finalDest = [(getPos _dest  select 0) + 3,  (getPos _dest select 1) + 3, getPos _dest select 2];
        //CBA functions for height/position tp
        [player, _finalDest] call CBA_fnc_setPos;
        [player, _height] call CBA_fnc_setHeight;
        titleText ["A few minutes later...", "BLACK IN", 5];

    }, _dest, 1.5, true, true, "", "true", 10
];
