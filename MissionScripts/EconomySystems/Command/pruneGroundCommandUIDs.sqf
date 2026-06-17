/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - pruneGroundCommandUIDs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_pruneGroundCommandUIDs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if !([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority) exitWith {};

    private _connected = [];
    {
        private _unitKey = [_x] call Waldo_fnc_EcoCommand_getGroundCommandKey;
        if (_unitKey isNotEqualTo "") then {
            _connected pushBackUnique _unitKey;
        };
    } forEach allPlayers;

    private _kept = [];
    {
        if ((_connected find _x) >= 0) then {
            _kept pushBack _x;
        };
    } forEach (call Waldo_fnc_EcoCommand_getGroundCommandUIDs);

    [_kept] call Waldo_fnc_EcoCommand_setGroundCommandUIDs;
