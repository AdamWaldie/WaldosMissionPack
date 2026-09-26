/*
 * Author: WaldoTheWarfighter
 * Adds a valid identity key to the authoritative Ground Command list.
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
 * [_uid] call Waldo_fnc_EcoCommand_promoteGroundCommand;
 * Locality/Authority: Economy authority machine only; the curator requests changes through
 * the validated Economy server bridge rather than calling this on a client.
 * Repeat/JIP Behaviour: Existing keys are not duplicated; the updated list is published for JIP.
 * Current Callers: Ground Command curator request handling.
 * Result: The selected player gains Ground Command membership when the key is valid.
 */

    params [["_uid", ""]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    _uid = [_uid] call Waldo_fnc_EcoCommand_normalizeGroundCommandKey;
    if (_uid isEqualTo "") exitWith {};

    private _uids = call Waldo_fnc_EcoCommand_getGroundCommandUIDs;
    if ((_uids find _uid) < 0) then {
        _uids pushBack _uid;
        [_uids] call Waldo_fnc_EcoCommand_setGroundCommandUIDs;
    };
