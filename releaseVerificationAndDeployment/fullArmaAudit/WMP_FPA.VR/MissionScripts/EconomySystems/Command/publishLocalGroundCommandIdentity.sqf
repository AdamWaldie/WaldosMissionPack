/*
 * Author: WaldoTheWarfighter
 * Publishes the local player's stable Ground Command owner/UID key when its value changes.
 *
 * Locality/authority: interface client only; publishes variables on the locally owned player
 * object. Repeat/JIP behaviour: repeat-safe and change-gated, so readiness retries and player-unit
 * events create no network update while owner and key remain unchanged.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true after evaluating a valid player; false outside an interface/current player.
 *
 * Current callers: Ground Command identity request/retry service.
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_publishLocalGroundCommandIdentity;
 */

    if (!hasInterface) exitWith {false};
    if (isNull player) exitWith {false};

    private _ownerId = clientOwner;
    if !(_ownerId isEqualType 0) then {
        _ownerId = owner player;
    };

    private _uid = getPlayerUID player;
    if !(_uid isEqualType "") then {_uid = str _uid;};

    private _key = if (_uid isEqualTo "") then {
        format ["LOCAL|%1|%2", _ownerId, netId player]
    } else {
        format ["UID|%1|OWNER|%2", _uid, _ownerId]
    };

    if ((player getVariable ["WaldoEcoCommand_ClientOwnerId", -1]) isNotEqualTo _ownerId) then {
        player setVariable ["WaldoEcoCommand_ClientOwnerId", _ownerId, true];
    };

    if ((player getVariable ["WaldoEcoCommand_GroundCommandKey", ""]) isNotEqualTo _key) then {
        player setVariable ["WaldoEcoCommand_GroundCommandKey", _key, true];
    };

    true
