/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - getGroundCommandKey
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_getGroundCommandKey via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {""};

    private _publishedKey = _unit getVariable ["WaldoEcoCommand_GroundCommandKey", ""];
    if ([_publishedKey] call Waldo_fnc_EcoCommand_isGroundCommandStoredKey) exitWith {_publishedKey};
    if (isMultiplayer && {hasInterface} && {!(_unit isEqualTo player)}) exitWith {""};

    private _uid = getPlayerUID _unit;
    if !(_uid isEqualType "") then {_uid = str _uid;};
    private _ownerId = _unit getVariable ["WaldoEcoCommand_ClientOwnerId", -1];
    if !((_ownerId isEqualType 0) && {_ownerId >= 0}) then {
        _ownerId = owner _unit;
    };

    if (_uid isEqualTo "") exitWith {
        format ["LOCAL|%1|%2", _ownerId, netId _unit]
    };

    format ["UID|%1|OWNER|%2", _uid, _ownerId]
