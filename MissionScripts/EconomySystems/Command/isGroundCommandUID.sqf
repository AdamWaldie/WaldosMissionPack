/*
 * Author: WaldoTheWarfighter
 * Checks whether a key is present in the current Ground Command list.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _uid <STRING> - uid (optional, default: "")
 *
 * Return Value:
 * <BOOL> true when the normalized key is listed.
 *
 * Example:
 * [_uid] call Waldo_fnc_EcoCommand_isGroundCommandUID;
 * Locality/Authority: Any machine; reads published command state only.
 * Repeat/JIP Behaviour: Repeat-safe and reflects JIP command-list state.
 * Current Callers: No in-pack caller; available for mission scripts checking a stored key.
 * Result: Returns false for an empty or unlisted key.
 */

    params [["_uid", ""]];

    _uid = [_uid] call Waldo_fnc_EcoCommand_normalizeGroundCommandKey;
    if (_uid isEqualTo "") exitWith {false};

    ((call Waldo_fnc_EcoCommand_getGroundCommandUIDs) find _uid) >= 0
