/*
 * Author: WaldoTheWarfighter
 * Purpose: Wraps one authorised transfer or merge with a visible requester result.
 * Locality / Authority: Server only; rejects a client claiming another player's identity.
 * Repeat / JIP: Stateless one-request wrapper; cargo transaction remains in RequestServer.
 * Arguments: player <OBJECT>, source <OBJECT>, destination <OBJECT>, category <STRING>,
 * expected row <ARRAY>, quantity <NUMBER>, interacted object <OBJECT> (objNull).
 * Return Value: <BOOL> committed.
 * Current callers: transfer panel and direct ACE merge action.
 * Example: [player, boxA, boxB, "ALL", [], 1] remoteExecCall ["Waldo_fnc_SupplyTransfersRequestWithFeedbackServer", 2];
 * Result: The server commits or rejects the transfer and sends the actor a local outcome.
 */
params [["_player", objNull, [objNull]], ["_source", objNull, [objNull]],
    ["_destination", objNull, [objNull]], ["_category", "", [""]],
    ["_expected", [], [[]]], ["_quantity", 1, [0]], ["_interaction", objNull, [objNull]]];
if (!isServer || {isNull _player} || {!alive _player}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}) exitWith {false};
private _ok = [_player, _source, _destination, _category, _expected, _quantity, _interaction]
    call Waldo_fnc_SupplyTransfersRequestServer;
[_ok, _source, _destination, _category] remoteExecCall ["Waldo_fnc_SupplyTransfersResultLocal", owner _player];
_ok
