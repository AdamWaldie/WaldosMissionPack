/*
 * Author: Waldo
 * Publish local ground command identity.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_publishLocalGroundCommandIdentity;
 */

    if (!hasInterface) exitWith {};
    if (isNull player) exitWith {};

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
