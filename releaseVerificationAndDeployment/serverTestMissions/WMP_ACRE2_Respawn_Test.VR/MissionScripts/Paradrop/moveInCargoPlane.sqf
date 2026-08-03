/*
 * Author: WaldoTheWarfighter
 * Installs a repeat-safe blue addAction on a boarding object that moves the caller into cargo of
 * a live aircraft. The action follows aircraft state, refuses full cargo compartments and uses
 * the caller supplied by addAction rather than assuming the global local player variable.
 * Run on every interface, normally through an object-keyed JIP remote execution.
 *
 * Arguments:
 * 0: boarding object <OBJECT>
 * 1: destination aircraft <OBJECT>
 * 2: custom aircraft/operation name <STRING> (default "Aircraft")
 *
 * Return Value:
 * Number - local addAction ID, or -1 when no action could be installed.
 *
 * Called by:
 * Eden object initialization fields and Waldo_fnc_ParadropEmbark boarding-point creation.
 *
 * Example:
 * [this, aircraft, "ARGUS 1-4"] call Waldo_fnc_MoveInCargoPlane;
 */

params [
    ["_boardingObject", objNull, [objNull]],
    ["_aircraft", objNull, [objNull]],
    ["_customName", "Aircraft", [""]]
];

if (!hasInterface || {isNull _boardingObject}) exitWith {-1};

private _oldAction = _boardingObject getVariable ["Waldo_Paradrop_BoardActionId", -1];
if (_oldAction >= 0) then {_boardingObject removeAction _oldAction};
_boardingObject setVariable ["Waldo_Paradrop_BoardAircraft", _aircraft];
private _title = format ["<t color='#407ada'>Board %1</t>", _customName];
private _actionId = _boardingObject addAction [
    _title,
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_aircraft", "_customName"];
        [_caller, _aircraft, _customName] call Waldo_fnc_ParadropEmbarkLocal;
    },
    [_aircraft, _customName],
    1.5,
    true,
    true,
    "",
    "private _aircraft = _target getVariable ['Waldo_Paradrop_BoardAircraft', objNull]; !isNull _aircraft && {alive _aircraft} && {(_aircraft emptyPositions 'cargo') > 0}",
    5
];
_boardingObject setVariable ["Waldo_Paradrop_BoardActionId", _actionId];
_actionId
