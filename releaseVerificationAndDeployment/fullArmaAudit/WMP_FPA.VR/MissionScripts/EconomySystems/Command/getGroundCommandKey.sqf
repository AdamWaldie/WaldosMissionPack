/*
 * Author: WaldoTheWarfighter
 * Resolves a player's stable Ground Command key from published identity or UID/owner fallback.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _unit <OBJECT> - unit (optional, default: objNull)
 *
 * Return Value:
 * <STRING> UID/owner key, local fallback key, or "" for an unavailable/remote identity.
 *
 * Example:
 * [_unit] call Waldo_fnc_EcoCommand_getGroundCommandKey;
 * Locality/Authority: Any machine; a client cannot derive another player's unpublished key.
 * Repeat/JIP Behaviour: Read-only; JIP clients use the published unit identity when present.
 * Current Callers: Ground Command membership checks, identity publication and pruning.
 * Result: Returns the key used to compare a unit with the Ground Command list.
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
