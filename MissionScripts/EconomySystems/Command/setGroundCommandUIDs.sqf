/*
 * Author: WaldoTheWarfighter
 * Validates and publishes the authoritative Ground Command identity list.
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
 * Locality/Authority: Economy authority machine only; writes missionNamespace public state.
 * Repeat/JIP Behaviour: Normalizes keys and publishes updates for JIP clients; repeat input
 * leaves the effective membership unchanged.
 * Current Callers: Ground Command Promote, Remove and pruning helpers.
 * Result: Invalid or duplicate entries are excluded from the stored list.
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
