/*
 * Author: Waldo
 * Remove ground command.
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
