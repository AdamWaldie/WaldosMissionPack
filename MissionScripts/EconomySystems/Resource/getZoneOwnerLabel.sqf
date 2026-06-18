/*
 * Author: Waldo
 * Get zone owner label.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoResource_getZoneOwnerLabel;
 */

    params ["_sideKey"];

    switch (toUpper _sideKey) do {
        case "WEST": {"BLUFOR"};
        case "EAST": {"OPFOR"};
        case "GUER": {"INDEP"};
        default {"UNCLAIMED"};
    }
