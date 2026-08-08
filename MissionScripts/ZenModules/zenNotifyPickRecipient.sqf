/*
 * Author: WaldoTheWarfighter
 * Opens a second Zeus dialog listing one side's current groups and players together in a single
 * live dropdown, then forwards the curator's pick to Waldo_fnc_ZenNotifyServer as either a GROUP or
 * a UNITS audience. This is the "By Group or Player" step of the Send Notification module - it
 * replaces what used to be a typed, unvalidated group-callsign text field with a dropdown built
 * fresh from the actual current groups/players of the chosen side, so a curator who really means
 * "just this one player" can pick a player entry from the same list instead of typing a callsign or
 * re-running the module as Selected Unit(s).
 *
 * Arguments:
 * 0: config <HASHMAP> - the notification's title/message/state/duration/placement/side, already
 *    collected by the Send Notification module; audience/group/units are added here before sending.
 * 1: side <SIDE> - which side's groups/players to list.
 *
 * Return Value:
 * Nothing - a valid pick forwards the completed config to Waldo_fnc_ZenNotifyServer.
 *
 * Example:
 * [_config, west] call Waldo_fnc_ZenNotifyPickRecipient;
 *
 * Current caller: Waldo_fnc_ZenNotify (Send Notification module), when Audience is By Group or Player.
 */

params [["_config", createHashMap, [createHashMap]], ["_side", sideUnknown, [sideUnknown]]];

private _sideGroups = allGroups select {side _x == _side && {count units _x > 0}};
private _sidePlayers = allPlayers select {side group _x == _side};
private _entryValues = [];
private _entryLabels = [];
{
    _entryValues pushBack ["GROUP", groupId _x];
    _entryLabels pushBack format ["[Group] %1 (%2)", groupId _x, count units _x];
} forEach _sideGroups;
{
    _entryValues pushBack ["UNIT", _x];
    _entryLabels pushBack format ["[Player] %1", name _x];
} forEach _sidePlayers;
if (count _entryValues == 0) exitWith {systemChat "[WMP] No groups or players found on that side."};

[
    "Send Notification: Group or Player",
    [["COMBO", ["Recipient", "Groups and players currently on the selected side."], [_entryValues, _entryLabels, 0]]],
    {
        params ["_values", "_config"];
        (_values select 0) params ["_kind", "_value"];
        if (_kind == "GROUP") then {
            _config set ["audience", "GROUP"];
            _config set ["group", _value];
        } else {
            _config set ["audience", "UNITS"];
            _config set ["units", [_value]];
        };
        [_config, player] remoteExecCall ["Waldo_fnc_ZenNotifyServer", 2];
    },
    {},
    _config
] call zen_dialog_fnc_create;
