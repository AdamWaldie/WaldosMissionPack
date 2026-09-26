/*
 * Author: WaldoTheWarfighter
 * Moves the current player outside a supported vehicle's left or right passenger door.
 * Locality and authority: Player-client action only; it changes the local player's position and
 * may animate a recognised helicopter door.
 * Repeat/JIP: Each call makes one exit. No persistent action or JIP state is installed here;
 * vehicle action setup owns the interaction.
 *
 * Arguments:
 * 0: Object <OBJECT>
 * 1: Door side <BOOLEAN> (Default Left/true)
 *
 * Example:
 * [this, true] call Waldo_fnc_DoExitOnSide;
 * Return Value: Nothing useful; this is a local exit action.
 * Current callers: vehicle exit actions installed by Waldo_fnc_AddExitAction.
 * Result: The player appears beside the selected passenger door.
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
