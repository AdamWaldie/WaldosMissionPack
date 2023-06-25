/*
 * Author: CPL.Brostrom.A (With the help from; 654wak654)
 * This function add two get out side addActions avaible for players in
 * cargoIndex positions.
 *
 * Arguments:
 * 0: Object <OBJECT>
 * 1: Color Action <BOOL>
 *
 * Example:
 * [this] call Waldo_fnc_AddExitActions;
 * [this, true] call Waldo_fnc_AddExitActions;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_useColor", true]
];

// Check so the options arent added twice.
if (!isNil {_vehicle getVariable "Waldo_Exit_Action_Setup"}) exitWith {};

private _leftSide = "Get out Left Side";
private _rightSide = "Get out Right Side";

if (_useColor) then {
    _leftSide = "<t color='#ff0000'>Get out Left Side</t>";
    _rightSide = "<t color='#0000ff'>Get out Right Side</t>";
};

_vehicle addAction [
    _leftSide,
    {[_this select 0, true] call Waldo_fnc_DoExitOnSide},
    0, 1.5, true, true, "",
    "(_target getCargoIndex _this) != -1"
];

_vehicle addAction [
    _rightSide,
    {[_this select 0, false] call Waldo_fnc_DoExitOnSide},
    0, 1.5, true, true, "",
    "(_target getCargoIndex _this) != -1"
];

_vehicle setVariable ["Waldo_Exit_Action_Setup","true"];