/*
 * Author: Waldo
 * Prune ground command UI ds.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_pruneGroundCommandUIDs;
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
