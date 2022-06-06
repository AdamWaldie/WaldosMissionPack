/*
 * Author: Waldo
 * Move the player outside the passanger door on the left or right side.
 *
 * Arguments:
 * 0: Object <OBJECT>
 * 1: Door side <BOOLEAN> (Default Left/true)
 *
 * Example:
 * [this, true] call Waldo_fnc_DoExitOnSide;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_doorSide", true]
];

private _rhs_UH60 = [
    "RHS_UH60M_MEV_d",
    "RHS_UH60M_MEV2_d",
    "RHS_UH60M2_d",
    "RHS_UH60M_ESSS_d",
    "RHS_UH60M_ESSS2_d",
    "RHS_UH60M_d",
    "RHS_UH60M",
    "RHS_UH60M_ESSS",
    "RHS_UH60M_ESSS2",
    "RHS_UH60M2",
    "RHS_UH60M_MEV2",
    "RHS_UH60M_MEV"
];
private _UH80 = [
    "B_CTRG_Heli_Transport_01_sand_F",
    "B_CTRG_Heli_Transport_01_tropic_F",
    "B_Heli_Transport_01_F"
];

// Door Animation handler
if (_doorSide) then {   // Left
    if (typeOf _vehicle in _rhs_UH60) then {
        if (_vehicle doorPhase "doorLB" == 0) then{
            _vehicle animateDoor ["doorLB", 1];
        } else {
            if (_vehicle doorPhase "doorLB" != 0) then {
                [_vehicle, "doorLB"] spawn rhs_fnc_doorHandler;
            };
        };
    };
} else {                // Right
    if (typeOf _vehicle in _rhs_UH60) then {
        if (_vehicle doorPhase "doorRB" == 0) then{
            _vehicle animateDoor ["doorRB", 1];
        } else {
            if (_vehicle doorPhase "doorRB" != 0) then {
                [_vehicle, "doorRB"] spawn rhs_fnc_doorHandler;
            };
        };
    };
};
sleep 1;

private _dir = getDir _vehicle;
_dir = if (_doorSide) then { _dir - 50 } else { _dir + 50 };

private _posASL = (getPosASL _vehicle) vectorAdd [sin _dir * 2.5, cos _dir * 2.5, 0];
moveOut player;
player setPosASL _posASL;

if (_doorSide) then {   // Left
    player setDir _dir - 40;
} else {                // Right
    player setDir _dir + 40;
};