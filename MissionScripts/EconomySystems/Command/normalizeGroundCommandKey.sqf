/*
 * Author: WaldoTheWarfighter
 * Converts a Ground Command identity value to its stored string form.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _key <STRING> - key (optional, default: "")
 *
 * Return Value:
 * <STRING> original string or stringified input.
 *
 * Example:
 * [_key] call Waldo_fnc_EcoCommand_normalizeGroundCommandKey;
 * Locality/Authority: Any machine; pure value conversion.
 * Repeat/JIP Behaviour: Stateless and repeat-safe; no JIP effects.
 * Current Callers: Ground Command membership and list update helpers.
 * Result: Returns a string suitable for subsequent prefix/list checks.
 */

    params [["_key", ""]];

    if !(_key isEqualType "") then {
        _key = str _key;
    };

    _key
