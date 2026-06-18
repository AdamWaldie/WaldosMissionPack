/*
 * Author: Waldo
 * Get side storage var.
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
 * [_sideKey] call Waldo_fnc_EcoResource_getSideStorageVar;
 */

    params ["_sideKey"];

    switch (toUpper _sideKey) do {
        case "WEST": {"WaldoEcoResource_Resources_WEST"};
        case "EAST": {"WaldoEcoResource_Resources_EAST"};
        case "GUER": {"WaldoEcoResource_Resources_GUER"};
        case "CIV": {"WaldoEcoResource_Resources_CIV"};
        default {""};
    };
