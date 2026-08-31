/*
 * Author: WaldoTheWarfighter
 * Installs the existing Economy testing-notice action on one current player object.
 *
 * Locality/authority: server only; routes the local action installer only to the current player
 * owner. Repeat/JIP behaviour: repeat-safe through the existing local action flag. Initial players,
 * JIP and respawn are covered by the lifecycle bridge, so no persistent JIP entry or all-client
 * publication is created for this self-only notice.
 *
 * Arguments:
 * 0: _unit <OBJECT> - current player object (default: objNull)
 *
 * Return Value:
 * BOOL - true when owner-targeted installation was sent; false for an invalid/inactive call.
 *
 * Current callers: startTestingNoticePlayerBridge initial reconciliation, PlayerConnected replay and
 * EntityRespawned replay.
 *
 * Example:
 * [_playerUnit] call Waldo_fnc_EcoCore_installTestingNoticeActionServer;
 */

params [["_unit", objNull, [objNull]]];

if (!isServer || {isNull _unit} || {!isPlayer _unit} || {_unit isKindOf "HeadlessClient_F"}) exitWith {false};
if !([] call Waldo_fnc_EcoCore_isModuleActive) exitWith {false};
private _ownerId = owner _unit;
if (_ownerId <= 0) exitWith {false};

[
    _unit,
    "WaldoEcoCore_TestingNoticeActionAddedLocalV2",
    call Waldo_fnc_EcoCore_getTestingNoticeActionArgs
] remoteExecCall ["Waldo_fnc_EcoCore_ensureLocalObjectAction", _ownerId];

true
