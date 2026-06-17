/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - publishLocalGroundCommandIdentity
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_publishLocalGroundCommandIdentity via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
