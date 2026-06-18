/*
 * Author: Waldo
 * Get preset purchase side name.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoCore_getPresetPurchaseSideName;
 */

    params [["_sideKey", ""]];

    switch (toUpper _sideKey) do {
        case "WEST": {"BLUFOR"};
        case "EAST": {"OPFOR"};
        case "GUER": {"INDEP"};
        default {"EVERYONE"};
    }
