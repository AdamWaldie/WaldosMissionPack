/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - removeGroundCommand
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_removeGroundCommand via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
