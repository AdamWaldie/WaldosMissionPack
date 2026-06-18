/*
 * Author: Waldo
 * Is ground command UID.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _uid <STRING> - uid (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_uid] call Waldo_fnc_EcoCommand_isGroundCommandUID;
 */

    params [["_uid", ""]];

    _uid = [_uid] call Waldo_fnc_EcoCommand_normalizeGroundCommandKey;
    if (_uid isEqualTo "") exitWith {false};

    ((call Waldo_fnc_EcoCommand_getGroundCommandUIDs) find _uid) >= 0
