/* Adds one repeat-safe, object-bound upright action to a local land vehicle. */
params [["_vehicle", objNull, [objNull]]];
if (!hasInterface || {isNull _vehicle} || {!(_vehicle isKindOf "LandVehicle")}) exitWith {false};
if (_vehicle getVariable ["Waldo_VehicleUpright_Action", -1] >= 0) exitWith {true};

private _action = _vehicle addAction [
    "<t color='#4FA9E8'>Set Vehicle Upright</t>",
    {
        params ["_target", "_caller"];
        [_target, _caller] remoteExecCall ["Waldo_fnc_VehicleUpright", 2];
    },
    [],
    0,
    false,
    true,
    "",
    "vehicle _this == _this && {_this distance _target <= 6} && {speed _target < 3} && {(vectorUp _target select 2) < 0.65}",
    6
];
_vehicle setVariable ["Waldo_VehicleUpright_Action", _action];
true
