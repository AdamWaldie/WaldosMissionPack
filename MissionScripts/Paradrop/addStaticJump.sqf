/*
This function adds a Jump out option to a vehicle.

Arguments:
0: Vehicle             <OBJECT>
1: Minimum altitude    <NUMBER> (Optional) (Default; 180)
2: Maximum altitude    <NUMBER> (Optional) (Default; 350)
3: Maximum speed       <NUMBER> (Optional) (Default; 310)
4: Chute Vehicle Class <OBJECT> (Optional) (Default; "rhs_d6_Parachute") Requires RHS, respecify alternative if required. (NonSteerable_Parachute_F is vanilla)

Example:
["plane"] call Waldo_fnc_AddStaticJump;
["plane", 180] call Waldo_fnc_AddStaticJump;
["plane", 180, 350, 300] call Waldo_fnc_AddStaticJump;
["plane", 180, 350, 300, "rhs_d6_Parachute"] call Waldo_fnc_AddStaticJump;

*/

params [
    ["_vehicle", objNull],
    ["_minAltitude", 180],
    ["_maxAltitude", 350],
    ["_maxSpeed", 310],
    ["_chuteVehicleClass", "rhs_d6_Parachute"]
];

/*if (!isNil {_vehicle getVariable "Waldo_Static_Jump"}) exitWith {
    hint [format["Aircraft static jump setting already applied for %1.", _vehicle]];
};*/

private _conditionHoldAction = format ["((_target getCargoIndex player) != -1) && ((_target animationPhase 'ramp_bottom' > 0.64) or (_target animationPhase 'door_2_1' == 1) or (_target animationPhase 'door_2_2' == 1) or (_target animationPhase 'jumpdoor_1' == 1) or (_target animationPhase 'jumpdoor_2' == 1) or (_target animationPhase 'back_ramp_switch' == 1) or (_target animationPhase 'back_ramp_half_switch' == 1) or (_target doorPhase 'RearDoors' > 0.5) or (_target doorPhase 'Door_1_source' > 0.5) or (_target animationSourcePhase 'ramp_anim' > 0.5)) && ((getPosVisual _target) select 2 >= %1) && ((getPosVisual _target) select 2 <= %2) && (speed _target <= %3)", _minAltitude, _maxAltitude, _maxSpeed];
//private _conditionHoldAction = format ["((getPosVisual _target) select 2 >= %1) && ((getPosVisual _target) select 2 <= %2) && (speed _target <= %3)", _minAltitude, _maxAltitude, _maxSpeed];

// Add hold action for jump
[
    _vehicle,
    "<t color='#407ada'>Jump</t>",
    "\a3\ui_f\data\igui\cfg\actions\eject_ca.paa",
    "\a3\ui_f\data\igui\cfg\actions\eject_ca.paa",
    _conditionHoldAction,
    "true",
    {},
    {},
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_chuteVehicleClass"];
        [_caller, _target, _chuteVehicleClass] call Waldo_fnc_StaticJumpFunc;
    },
    {},
    [_chuteVehicleClass],
    0,
    25,
    false
] call BIS_fnc_holdActionAdd;

_vehicle setVariable ["Waldo_Static_Jump",[_vehicle, _minAltitude, _maxAltitude, _maxSpeed, _chuteVehicleClass]];