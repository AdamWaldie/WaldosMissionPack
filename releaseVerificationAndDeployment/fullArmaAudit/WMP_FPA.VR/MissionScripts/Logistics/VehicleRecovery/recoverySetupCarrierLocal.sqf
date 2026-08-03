/* Installs load/unload controls on a recovery carrier. */
params [["_target", objNull, [objNull]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _target} || {_target getVariable ["Waldo_Recovery_CarrierActionsInstalled", false]}) exitWith {false};
private _load = _target addAction [
    "<t color='#F4C542'>Load Recovery Package</t>",
    {params ["_target", "_actor"]; [_actor, "LOAD", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];},
    [], 1.4, true, true, "", "_this distance _target < 6 && {alive _target} && {abs speed _target < 1} && {getVehicleCargo _target isEqualTo []}", 6
];
private _unload = _target addAction [
    "<t color='#F4C542'>Unload Recovery Package</t>",
    {params ["_target", "_actor"]; [_actor, "UNLOAD", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];},
    [], 1.4, true, true, "", "_this distance _target < 6 && {alive _target} && {abs speed _target < 1} && {!((getVehicleCargo _target) isEqualTo [])}", 6
];
_target setVariable ["Waldo_Recovery_CarrierActionIds", [_load, _unload]];
_target setVariable ["Waldo_Recovery_CarrierActionsInstalled", true];
true
