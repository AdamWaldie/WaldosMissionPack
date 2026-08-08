/*
 * Author: WaldoTheWarfighter
 * Broadcasts one WMP UI notification card (Waldo_fnc_ShowUiNotification) to a chosen audience.
 * Server-authoritative; self-forwards when called on a client, so it is safe to call directly from
 * mission scripts with no isServer wrapper, matching Waldo_fnc_Jammer and the other public
 * registration-style APIs.
 *
 * Arguments:
 * 0: config <HASHMAP> with:
 *    title <STRING> (default "NOTICE"), message <STRING> (default ""),
 *    state <STRING> INFO|SUCCESS|WARNING|ERROR (default "INFO"),
 *    duration <NUMBER> seconds, 0 = persistent (default 8),
 *    placement <STRING> TOP|TOP_RIGHT|CENTER|BOTTOM_LEFT|BOTTOM_CENTER|BOTTOM_RIGHT (default "TOP"),
 *    channel <STRING> replacement/ownership key (default "ZEUS_MESSAGE"),
 *    source <STRING> (default "ZEUS"),
 *    audience <STRING> ALL|SIDE|GROUP|UNITS (default "ALL"),
 *    side <SIDE> - read when audience is SIDE,
 *    group <STRING> - group callsign to match case-insensitively, read when audience is GROUP,
 *    units <ARRAY<OBJECT>> - explicit player units, read when audience is UNITS.
 *
 * Return Value:
 * Number - count of distinct players actually reached.
 *
 * Example:
 * [createHashMapFromArray [
 *     ["title", "FALL BACK"], ["message", "Regroup at the rally point."], ["state", "WARNING"],
 *     ["audience", "SIDE"], ["side", west]
 * ]] call Waldo_fnc_NotificationBroadcast;
 *
 * Current callers: the "Mission Flow: Send Notification" ZEN module (via Waldo_fnc_ZenNotifyServer)
 * and mission scripts.
 */
params [["_config", createHashMap, [createHashMap]]];
if !(isServer) exitWith {[_config] remoteExecCall ["Waldo_fnc_NotificationBroadcast", 2]; 0};

private _audience = toUpperANSI (_config getOrDefault ["audience", "ALL"]);
private _targets = switch (_audience) do {
    case "SIDE": {
        private _side = _config getOrDefault ["side", sideUnknown];
        allPlayers select {side group _x == _side}
    };
    case "GROUP": {
        private _groupName = toUpperANSI (_config getOrDefault ["group", ""]);
        if (_groupName == "") then {[]} else {
            allPlayers select {toUpperANSI groupId group _x == _groupName}
        }
    };
    case "UNITS": {
        (_config getOrDefault ["units", []]) select {!isNull _x && {isPlayer _x}}
    };
    default {allPlayers};
};
private _owners = [];
{_owners pushBackUnique (owner _x)} forEach _targets;
private _payload = [
    _config getOrDefault ["title", "NOTICE"],
    _config getOrDefault ["message", ""],
    toUpperANSI (_config getOrDefault ["state", "INFO"]),
    _config getOrDefault ["duration", 8],
    toUpperANSI (_config getOrDefault ["placement", "TOP"]),
    _config getOrDefault ["channel", "ZEUS_MESSAGE"],
    _config getOrDefault ["source", "ZEUS"]
];
{_payload remoteExecCall ["Waldo_fnc_ShowUiNotification", _x]} forEach _owners;
diag_log format ["[WMP UI] Notification broadcast audience=%1 reached=%2 title=%3", _audience, count _owners, _config getOrDefault ["title", "NOTICE"]];
count _owners
