/*
 * Author: Waldo
 * Set ground command UI ds.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _uids <ARRAY> - uids (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_uids] call Waldo_fnc_EcoCommand_setGroundCommandUIDs;
 */

    params [["_uids", []]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _clean = [];
    {
        private _uid = [_x] call Waldo_fnc_EcoCommand_normalizeGroundCommandKey;
        if (_uid isEqualTo "") then {continue;};
        if !([_uid] call Waldo_fnc_EcoCommand_isGroundCommandStoredKey) then {continue;};
        if ((_clean find _uid) >= 0) then {continue;};
        _clean pushBack _uid;
    } forEach _uids;

    missionNamespace setVariable ["WaldoEcoCommand_GroundCommandUIDs", _clean, true];
