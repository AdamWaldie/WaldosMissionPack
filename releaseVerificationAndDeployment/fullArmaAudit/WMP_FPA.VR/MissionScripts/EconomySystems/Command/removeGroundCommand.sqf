/*
 * Author: WaldoTheWarfighter
 * Removes a valid identity key from the authoritative Ground Command list.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _uid <STRING> - uid (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_uid] call Waldo_fnc_EcoCommand_removeGroundCommand;
 * Locality/Authority: Economy authority machine only; curator UI sends a validated request.
 * Repeat/JIP Behaviour: Removing an absent key is a no-op; changed list is published for JIP.
 * Current Callers: Ground Command curator request handling.
 * Result: The selected player no longer has Ground Command membership.
 */

    params [["_uid", ""]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    _uid = [_uid] call Waldo_fnc_EcoCommand_normalizeGroundCommandKey;
    if (_uid isEqualTo "") exitWith {};

    private _uids = call Waldo_fnc_EcoCommand_getGroundCommandUIDs;
    private _index = _uids find _uid;
    if (_index >= 0) then {
        _uids deleteAt _index;
        [_uids] call Waldo_fnc_EcoCommand_setGroundCommandUIDs;
    };
