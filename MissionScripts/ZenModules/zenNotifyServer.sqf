/*
 * Author: WaldoTheWarfighter
 * Authenticates a ZEN curator request before invoking the normal server-authoritative notification
 * broadcast API. This protects the public ZEN path without changing mission-script uses of
 * Waldo_fnc_NotificationBroadcast.
 * Locality and authority: Server-only; verifies the requesting remote owner's assigned curator
 * before broadcasting through WMP's notification service.
 * Repeat/JIP: Each accepted request sends one current notification. A past notification is not
 * replayed to players who join later.
 *
 * Arguments:
 * 0: config <HASHMAP> - see Waldo_fnc_NotificationBroadcast.
 * 1: requester <OBJECT>.
 *
 * Return Value: BOOL - true when the server accepted and reached at least one player.
 *
 * Example:
 * [_config, player] remoteExecCall ["Waldo_fnc_ZenNotifyServer", 2];
 * Current caller: Waldo_fnc_ZenNotify.
 * Result: The selected current audience receives the notification; the curator sees the reached
 * player count.
 */
params [["_config", createHashMap, [createHashMap]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {false};
private _owner = remoteExecutedOwner;
if (_owner > 0 && {isNull _requester || {owner _requester != _owner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {false};

private _audience = toUpperANSI (_config getOrDefault ["audience", "ALL"]);
if (_audience == "UNITS" && {(_config getOrDefault ["units", []]) isEqualTo []}) exitWith {
    if (_owner > 2) then {
        ["NOTIFICATION", "Select one or more player units in Zeus first, or drop the module directly on a player.", "WARNING", "NOTIFY_ZEN", 8]
            remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
    };
    false
};
private _reached = [_config] call Waldo_fnc_NotificationBroadcast;
if (_owner > 2) then {
    ["NOTIFICATION SENT", format ["Reached %1 player(s).", _reached], if (_reached > 0) then {"SUCCESS"} else {"WARNING"}, "NOTIFY_ZEN", 6]
        remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
};
_reached > 0
