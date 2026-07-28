/* Installs the local recovery interaction; the server validates every completion. */
params [["_target", objNull, [objNull]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _target} || {_target getVariable ["Waldo_Recovery_VehicleActionInstalled", false]}) exitWith {false};
private _condition = "_this distance _target < 5 && {vehicle _this == _this} && {count crew _target == 0} && {abs speed _target < 1} && {(damage _target >= ((_target getVariable ['Waldo_Recovery_Config',['MAIN',0.55,true,false,'',true,1]]) select 1)) || {!alive _target}}";
private _id = _target addAction [
    "<t color='#F4C542'>Package for Recovery</t>",
    {params ["_target", "_actor"]; [_actor, "PACK", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];},
    [], 1.5, true, true, "", _condition, 5
];
_target setVariable ["Waldo_Recovery_VehicleActionIds", [_id]];
_target setVariable ["Waldo_Recovery_VehicleActionInstalled", true];
true
