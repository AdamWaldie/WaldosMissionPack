/*
 * Author: WaldoTheWarfighter
 * Resolves a reply owner without treating Arma's zero HC sender id as a broadcast target.
 * Locality/authority: server only. Positive engine sender ids take precedence. A zero sender
 * requires a supplied id that currently owns an engine HeadlessClient_F entity. HC processes
 * share the trusted mission code; this cannot distinguish two HCs impersonating one another.
 * Repeat/JIP: read-only, no cache; disconnected owners fail immediately.
 * Arguments: 0: claimed owner <NUMBER>, default -1; 1: expected owner <NUMBER>, default -1 (any).
 * Return Value: NUMBER, resolved owner or -1 on failure; never returns broadcast target zero.
 * Current callers: runtime snapshot, HC registration, AI adoption and owner acknowledgements.
 * Example: private _sender = [clientOwner, groupOwner _group] call Waldo_fnc_HeadlessResolveSender;
 */
params [["_claimed",-1,[0]],["_expected",-1,[0]]];
if (!isServer) exitWith {-1};
private _sender = remoteExecutedOwner;
if (_sender > 0) exitWith {
    if ((_claimed > 0 && {_claimed != _sender}) || {_expected > 0 && {_expected != _sender}}) then {-1} else {_sender}
};
if (_claimed <= 2 || {_expected > 0 && {_claimed != _expected}}) exitWith {-1};
if ((entities "HeadlessClient_F") findIf {owner _x == _claimed} < 0) exitWith {-1};
_claimed
