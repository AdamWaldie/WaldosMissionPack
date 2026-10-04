/*
 * Author: WaldoTheWarfighter
 * Returns a throwable consumed by a corpse-trap progress action when the server rejects arming.
 * Locality and authority: Runs on the requesting player's interface client after a server reply;
 * it restores one magazine locally to the owned, living actor or current player fallback.
 * Repeat/JIP: Each call refunds one magazine; it is not idempotent and must only be sent once for
 * a rejected request. There is no persistent JIP state.
 * Arguments:
 * 0: original planting player <OBJECT> (default objNull)
 * 1: magazine classname <STRING> (default "")
 * 2: rejection reason <STRING> (default "the arming request was rejected")
 * Return Value: <BOOL> - true when a magazine was restored; false without a recipient or class.
 * Current caller: Waldo_fnc_CorpseTrapArmServer on rejection.
 * Example: [player, "HandGrenade", "target moved"] call Waldo_fnc_CorpseTrapRefund;
 * Result: The player receives the spent throwable back and sees the cancellation reason.
 */
params [
    ["_actor", objNull, [objNull]],
    ["_magazine", "", [""]],
    ["_reason", "the arming request was rejected", [""]]
];

if (!hasInterface || {_magazine == ""}) exitWith {false};

private _recipient = if (!isNull _actor && {local _actor} && {alive _actor}) then {_actor} else {player};
if (isNull _recipient) exitWith {false};

_recipient addMagazine _magazine;
systemChat format ["Corpse trap cancelled: %1. The throwable was refunded.", _reason];
true
