/*
This function adds a HALO Jump out option to a vehicle.

Arguments:
0: Vehicle             <OBJECT>
1: Minimum altitude    <NUMBER> (Optional) (Default; 5000)
4: Chute Vehicle Class <OBJECT> (Optional) (Default; "B_Parachute")

Example:
["plane/helicopter"] call Waldo_fnc_AddHaloJump;
["plane/helicopter", 1000] call Waldo_fnc_AddHaloJump;
["plane/helicopter", 1000, "B_Parachute"] call Waldo_fnc_AddHaloJump;

*/

params [
    ["_vehicle", objNull],
    ["_minAltitude", 1000],
    ["_chuteBackpackClass", "B_Parachute"]
];

// Check so the options arent added twice.
/*if (!isNil {_vehicle getVariable "Waldo_Halo_Jump"}) exitWith {
    hint [format["Aircraft halo jump setting already applied for %1.", _vehicle]];
};*/

private _conditionHoldAction = format ["((_target getCargoIndex player) != -1) && ((_target animationPhase 'ramp_bottom' > 0.64) or (_target animationPhase 'door_2_1' == 1) or (_target animationPhase 'door_2_2' == 1) or (_target animationPhase 'jumpdoor_1' == 1) or (_target animationPhase 'jumpdoor_2' == 1) or (_target animationPhase 'back_ramp_switch' == 1) or (_target animationPhase 'back_ramp_half_switch' == 1) or (_target doorPhase 'RearDoors' > 0.5) or (_target doorPhase 'Door_1_source' > 0.5) or (_target animationSourcePhase 'ramp_anim' > 0.5)) && ((getPosVisual _target) select 2 >= %1)", _minAltitude];
//private _conditionHoldAction = format ["((getPosVisual _target) select 2 >= %1)", _minAltitude];

// Add hold action for jump
[
    _vehicle,
    "<t color='#407ada'>HALO Jump</t>",
    "\a3\ui_f\data\igui\cfg\actions\eject_ca.paa",
    "\a3\ui_f\data\igui\cfg\actions\eject_ca.paa",
    _conditionHoldAction,
    "true",
    {},
    {},
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_chuteBackpackClass"];
        [_caller, _target, _chuteBackpackClass] call Waldo_fnc_HaloJumpFunc;
    },
    {},
    [_chuteBackpackClass],
    0,
    25,
    false
] call BIS_fnc_holdActionAdd;

_vehicle setVariable ["Waldo_Halo_Jump", [_vehicle, _minAltitude, _chuteBackpackClass]];