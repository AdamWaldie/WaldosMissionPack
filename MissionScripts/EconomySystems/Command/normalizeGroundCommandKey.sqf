/*
 * Author: Waldo
 * Normalize ground command key.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _key <STRING> - key (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_key] call Waldo_fnc_EcoCommand_normalizeGroundCommandKey;
 */

    params [["_key", ""]];

    if !(_key isEqualType "") then {
        _key = str _key;
    };

    _key
