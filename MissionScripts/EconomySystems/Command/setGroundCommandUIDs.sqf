/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - setGroundCommandUIDs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_setGroundCommandUIDs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
