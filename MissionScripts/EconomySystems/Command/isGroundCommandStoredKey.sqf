/*
 * Author: WaldoTheWarfighter
 * Checks whether a command key uses the UID or LOCAL storage prefix.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _key <STRING> - key (optional, default: "")
 *
 * Return Value:
 * <BOOL> true for a UID| or LOCAL| prefixed key.
 *
 * Example:
 * [_key] call Waldo_fnc_EcoCommand_isGroundCommandStoredKey;
 * Locality/Authority: Any machine; pure string validation.
 * Repeat/JIP Behaviour: Stateless and repeat-safe; no JIP effects.
 * Current Callers: Ground Command key lookup and list filtering.
 * Result: Rejects unprefixed/empty keys.
 */

    params [["_key", ""]];

    if !(_key isEqualType "") then {
        _key = str _key;
    };

    ((_key find "UID|") isEqualTo 0) || {(_key find "LOCAL|") isEqualTo 0}
