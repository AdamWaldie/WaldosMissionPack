/*
 * Refunds one rejected trap magazine on the owning client.
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
