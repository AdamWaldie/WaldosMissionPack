/*
 * Author: WaldoTheWarfighter
 * Removes command keys whose players are no longer connected.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing <NIL>.
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_pruneGroundCommandUIDs;
 * Locality/Authority: Economy background authority only; writes the validated command list.
 * Repeat/JIP Behaviour: Idempotent for unchanged players; list updates are published for JIP.
 * Current Callers: EcoResource_startAuthorityLoops background reconciliation.
 * Result: Disconnected identities are removed from Ground Command membership.
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
