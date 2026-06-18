/*
 * Author: Waldo
 * Get side key from side.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _side <ANY> - side
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_side] call Waldo_fnc_EcoResource_getSideKeyFromSide;
 */

    params ["_side"];

    switch (_side) do {
        case west: {"WEST"};
        case east: {"EAST"};
        case independent: {"GUER"};
        case civilian: {"CIV"};
        default {"CIV"};
    };
