/*
 * Author: WaldoTheWarfighter
 * Adds one vanilla scroll-wheel teleport action to an interaction object. It sends the player to
 * a fixed offset near a named destination with the built-in fade. It does not search for safe ground.
 * Locality/authority: call on each interface client; the local addAction moves that player only.
 * Repeat/JIP: this helper has no duplicate guard or JIP replay. An Eden Init runs for each client;
 * a runtime-created object needs explicit setup for joining clients.
 * Arguments:
 * 0: interaction object <OBJECT> - object receiving the action (required).
 * 1: label <STRING> - player-facing action text (default "Teleport").
 * 2: destination <OBJECT|STRING|LOCATION|GROUP|TASK> - named marker string or existing world
 *    reference (default: interaction object). Marker, Location and Task heights resolve to zero.
 * Return Value: NUMBER - local addAction ID.
 * Current callers: mission-maker Eden object Init fields and scripted local setup.
 * Example: [this, "Teleport to base", "respawn_west"] call Waldo_fnc_Teleport;
 * Result: the player can use a green action to travel near the respawn_west marker.
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
