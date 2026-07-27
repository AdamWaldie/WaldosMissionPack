/* Displays a Virtual Vehicle Depot message on the addressed player's client. */
params [["_message", "Vehicle depot request failed.", [""]]];

if (!hasInterface) exitWith {};
[_message] spawn {
    params ["_text"];
    [_text] call BIS_fnc_guiMessage;
};
