/*
 * Author: WaldoTheWarfighter
 * Adds left/right exit choices to cargo passengers of one vehicle.
 * Locality/authority: the object's local addAction handles only the passenger selecting it.
 * Repeat/JIP: an object flag prevents duplicate setup. Eden Init runs on each client; a vehicle
 * created later needs the same client setup for joining players.
 *
 * Arguments:
 * 0: vehicle <OBJECT> - existing aircraft or other cargo-capable vehicle (required).
 * 1: coloured labels <BOOL> - true for coloured sides (default true).
 * Return Value: No useful value.
 * Current callers: automatic vehicle-action setup and mission-maker object Init fields.
 *
 * Example:
 * [this] call Waldo_fnc_AddExitActions;
 * [this, true] call Waldo_fnc_AddExitActions;
 * Result: cargo passengers see separate left and right exit actions.
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
